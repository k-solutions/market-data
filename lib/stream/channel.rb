#!/usr/bin/env ruby

require 'observer'

module Stream
  
  class ZmqChannel
    include Celluloid
    include Celluloid::Notifications
    
    def initialize channel, callback = nil
      @callback = callback
      subscribe channel, :broadcast
    end
    
    def broadcast the_channel, value
      @callback.call the_channel, value unless @callback
    end
  end
  
  class Channel
    include Observable
    
    SEPARATORS = { redis: '.', zmq: ':' }
    ROLES      = [ :subscriber, :publisher, :retranslator ]
    # TODO: add reg_exp handling for channel
    attr_reader :id, :items, :type, :role

    # options are:
    #  :channel_id
    #  :items - array of elelemts to create a channel
    #  :type  - could be :redis, :zmq or :combined
    #  :role  - could be :subscriber, :publisher or :retranslator
    def initialize( options = {} )
      raise ArgumentError.new "You need to supply a channel id" unless options[ :id ] and !options[ :id ].empty?
      @id    = options.fetch :id
      @type  = options.fetch :type, :redis
      @role  = options.fetch :role, ROLES.first
      @items = options.fetch :items, parse( @id )
    end

    # parse channels string and 
    # return array of it's items
    def parse str = nil, type = nil
      if str and !str.empty? 
        str.split( get_separator( type ) )
      elsif @items and !@items.empty?
        @items
      else
        raise ArgumentError.new "Bad parameter passed to method!"
      end
    end
    
    def to_reg type = nil
      type ||= @type
      case type
      when :redis
        "#{to_s}#{get_separator(type)}*"
      when :zmq
        Regexp.new "#{Regexp.escape("#{to_s}")}#{get_separator(type)}\\w{3,}"
      else
        raise ArgumentError.new "Unkown type #{type} for channel"
      end
    end

    # return channel as string
    def to_s type = nil
      @items.join( get_separator( type ) )
    end
    
# NOTE: would not see any use case for this method yet
#     def clean_up(*args)
#     end
    
    private 
    def get_separator type = nil
      SEPARATORS[ type || @type ]
    end
  end

  class SubscriptionChannel < Channel

    def initialize(channel_id, options={})
      super(channel_id, options)
      #TODO: subscribe @channel_id, :received
    end

    def clean_up(obj)
      super(obj)
      delete_observer(obj)
    end

    private
    def received(data)
      changed
      notify_observers(data)
    end
  end

  class PublishChannel < Channel
    include Observable

    def broadcast(data)
      #TODO: publish @channel_id, data
      changed
      notify_observers
    end
  end
end