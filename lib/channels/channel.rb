#!/usr/bin/env ruby

require 'observer'
require_relative '../init'
require_relative 'broadcaster'
require_relative 'redis'

module Channels
  BROADCASTER ||= Celluloid::Actor[ ZMQ_BROADCASTER  ] || ZmqBroadcaster.new
  PUBLISHER   ||= Celluloid::Actor[ REDIS_PUBLISHER  ] || RedisPub.new
  SUBSCRIBER  ||= Celluloid::Actor[ REDIS_SUBSCRIBER ] || RedisSub.new
  
  class Redis
    include Observable
    
    ROLES     = [ :subscribe, :psubscribe ] # Having a role is making sense if you need to activate the channels on init # :publisher, :retranslator ]
    SEPARATOR = '.'
    
    # TODO: add reg_exp handling for channel
    attr_reader :id, :items, :role
    
    # options are:
    #  :id    - must be provided will be parsed like 'item1.item2'
    #  :items - array of elelemts to create a channel
    #  :type  - could be :redis, :zmq or :combined
    #  :role  - could be :subscriber, :publisher or :retranslator
    def initialize( options = {} )
      raise ArgumentError.new "You need to supply a channel id" unless options[ :id ] and !options[ :id ].empty?
      @id, @role, @items  = options[ :id ], options.fetch( :role, nil ), options.fetch( :items, parse( options[ :id ] ) )
      @def_callback = lambda { |channel, val| self._broadcast channel, val }
      @format_proc  = lambda { |msg| msg.respond_to?(options[:format_method].to_sym) ? msg.send( options[:format_method].to_sym, options[:format] ): msg } if options[:format] and options[:format_method]
      send @role.to_sym if _has_role? # activate the channel
    end
    
    # options:
    #  :data - mandatory
    #  :channel - optional (default to_s)
    def publish options = {}
      return unless options[ :data ]
      PUBLISHER.publish options.fetch( :channel, to_s ), _get_msg( options[ :data ], true )
    end
    
    # Path publish is publishing to path channels (adding channel items and separator to passed channnel)
    # options:
    #  :data - mandatory
    #  :channel - optional (default to_s)
    def ppublish options = {}
      return unless options[ :data ]
      channel = options[ :channel ] ? "#{to_s}#{_separator}#{options[ :channel ]}" : to_s
      PUBLISHER.publish channel, _get_msg( options[ :data ], true )
    end
    
    def subscribe callback = @def_callback 
      SUBSCRIBER.subscribe [ to_s ], { :send => [ self, :_broadcast ] } # subscribed to_s, callback 
    end
    
    def psubscribe callback = @def_callback 
      SUBSCRIBER.psubscribe [ to_reg ], { :send => [ self, :_broadcast ] }
    end
    
    def unsubscribe callback = @def_callback
      # NOTE: The unsubscription is automatic BROADCASTER.unsubscribe to_s, callback
    end
    
    def punsubscribe callback = @def_callback
      # NOTE: The unsubscription is automatic BROADCASTER.unsubscribe to_reg, callback
    end
    
    # parse channels string and 
    # return array of it's items
    def parse str = nil
      if str and !str.empty? 
        str.split( _separator )
      elsif @items and !@items.empty?
        @items
      else
        raise ArgumentError.new "Bad parameter passed to method!"
      end
    end
    
    def get_last str = nil
      parse( str ).last
    end
    
    def match? channel
      channel.match Regexp.escape( to_s ) 
    end
    
    # return channel as string
    def to_s
      @items.join( _separator )
    end
    
    def to_reg
      "#{to_s}#{ _separator }*"
    end
    
    # NOTE: this method should be protected, but it could not be called from Redis actors
    def _broadcast channel, value
      the_channel, msg = get_last( channel ), _get_msg( value )
      # binding.pry
      changed # notify observers
      notify_observers the_channel, msg #  binding.pry
      
      return the_channel, msg
    end
    
    private
    def _has_role?
      @role and ROLES.include?( @role  )
    end
    
    def _get_msg msg, publish = false
      return msg if publish and _has_role? # we have a subscription channel with publish call
      @format_proc ? @format_proc.call( msg ) : msg
    end
    
    def _separator
      self.class::SEPARATOR
    end
  end
  
  class Zmq < Redis
    SEPARATOR = ':'
    
    def to_reg 
      Regexp.new "#{Regexp.escape("#{to_s}")}#{_separator}\\w{3,}"
    end
    
    # options:
    #  :data - mandatory
    #  :channel - optional (default to_s)
    def publish options = {} # channel = to_s, data = nil
      return unless options[ :data ]
      BROADCASTER.publish options.fetch( :channel, to_s ), _get_msg( options[ :data ], true ) # options[ :data ]
    end
    
    # Path publish is publishing to path channels (adding channel items and separator to passed channnel)
    # options:
    #  :data - mandatory
    #  :channel - optional (default to_s)
    def ppublish options = {} 
      return unless options[ :data ]
      channel = options[ :channel ] ? "#{to_s}#{_separator}#{options[ :channel ]}" : to_s
      BROADCASTER.publish channel, _get_msg( options[ :data ], true ) # options[ :data ]
    end
    
    def subscribe callback = @def_callback 
      BROADCASTER.listen to_s, callback 
    end
    
    def psubscribe callback = @def_callback 
      BROADCASTER.plisten to_reg, callback 
    end
    
    def unsubscribe callback = @def_callback
      BROADCASTER.remove to_s, callback
    end
    
    def punsubscribe callback = @def_callback
      BROADCASTER.premove to_reg, callback
    end
  end
  
  module Factory
    CONFIG_FILE           = 'config/channels.yml'
    ROLES                 = [ :subscriber , :publisher ]
    class << self
      def group_options options = {}
        raise ArgumentError.new "Wrong or missing :channel_label options in #{options}" unless options[ :channel_label ] and
                                                    ( the_options = Utility::Parser.get( CONFIG_FILE,  options[ :channel_label ] ) )
        if options[ :role ]
          raise ArgumentError.new "Wrong :role options in #{options}" unless ROLES.include? options[ :role ] 
          the_options[ options[ :role ] ]
        else
          the_options[ ROLES.first ]
        end
      end
      
      def group options = {}
        Group.new *group_options( options )
      end
      
      # options are:
      #  :id    - mandatory option, if given in proper format would be autoprsed
      #  :items - array of elelemts to create a channel
      #  :type  - could be :redis, :zmq or :combined ( default is :redis )
      #  :role  - could be :subscriber, :publisher or :retranslator   
      def create options = {}
        raise ArgumentError.new "Bad options passed #{options}" unless options[ :id ]
        case options[:type]
        when :zmq
          Zmq.new   options
        else
          Redis.new options
        end
      end
    end
  end
  
  # sets a channels group
  class Group
    METHODS = [ :size, :length, :first, :last, :find, :detect, :each, :empty? ]
    extend Forwardable
    def_delegators :channels, *METHODS 
    
    attr_reader :channels
    
    def initialize *args
      @channels = args.inject( [] ) { |res, options| res << Factory.create( options ) }
    end
    
    def ppublish_all channel, data
      @channels.each { |chn| chn.ppublish channel: channel, data: data }
    end
    
    def publish_all channel, data
      @channels.each { |chn| chn.publish channel: channel, data: data }
    end
    
    def subscribe_all current
      the_channels = @channels # NOTE: can't add a new key into hash during iteration exception raised in direct call
      the_channels.each { |chn| chn.add_observer( current ) }
    end
    
    def get_first_channel channel_str
      @channels.find { |chn| chn.match? channel_str }
    end
  end
end