require 'celluloid/autostart'
require_relative '../utility/redis'

module Channels
    class RedisBase
      include Celluloid
      include Celluloid::Logger
      
      def initialize options = nil # redis
         @redis ||= Utility::Redis.get_connection( :celluloid ) 
         raise ArgumentError.new "Redis connection is not available!" unless @redis or !@redis.connected?
      end
    end
    
    class RedisPub < RedisBase
      class PublishException < Exception; end
        
      def publish channel, message
        raise PublishException.new "Bad parameters for publish!" unless channel and message
        
        @redis.publish channel, message # info "Published #{message} on channel: #{channel}"
      end
    end
  
    class SubBus < RedisBase
      include Celluloid::Notifications
      
      DEFAULT_BROADCAST = lambda { |chn, msg| Actor.current.publish( DEFAULT_MSG_CHANNEL, msg ) } 
      
      attr_reader :callback, :channels, :pchannels
      
      finalizer :unsubscribe_all
      
      def initialize options = nil
        super
        @pchannels, @channels, @callback = [], [], set_caller( options )
      end

      def subscribed *channels
        @channels = @channels | channels      # holds the list of channels subscribed
        @redis.subscribe( *channels ) do |on| # rest of the channels must be subscried in it subscription call, so subscribe only new commerss 
          on.subscribe { |channel, subscriptions| info "Subscribed to #{channel}/#{subscriptions} with channels registered: #{@channels.join(', ')}" }
          ca = current_actor
          defer { on.message { |channel,msg| ca.callback.call( channel, msg ) } }
        end
      end
      
      def psubscribed *channels
        @pchannels = @pchannels | channels
        @redis.psubscribe( *channels ) do |on| # , 
          on.psubscribe { |channel, subscriptions| info "Pattern Subscribtion to #{channel}/#{subscriptions}" }
          ca = current_actor
          defer { on.pmessage { |pattern, channel,msg| ca.callback.call( channel, msg ) } }
        end
      end
      
      def unsubscribe_all
        return if @channels.empty? and @pchannels.empty?
        
        unless @channels.empty?
          @redis.subscribe( *@channels ) do |on|  # fake subscription
            on.subscribe { @redis.unsubscribe( *@channels ) }
            on.unsubscribe { |channel, total| info "Unsubscribed from #{channel}  with (#{total} subscriptions)" }
          end
        end
        
        unless @pchannels.empty?
           @redis.psubscribe( *@pchannels ) do |on|  # fake subscription
            on.subscribe { @redis.punsubscribe( *@pchannels ) }
            on.unsubscribe { |channel, total| info "Unsubscribed from #{channel}  with (#{total} subscriptions)" }
          end
        end
      end
     
      private
      # preprocessing caller value
      def set_caller options
        options ||= { :broadcast => DEFAULT_MSG_CHANNEL } 
        # TODO: add default broadcast options
        options.each do |key, val|
          return case key
          when :callback
            val
          when :send
            raise SubscribeException.new "Bad options for send we expect in the format [ actor, method ]" if val.size != 2
            # TODO: do async send if actor is a Celluloid::Actor
            lambda { |chn, msg| val[0].send val[1], chn, msg } 
          when :broadcast
            ca = current_actor
            lambda { |chn, msg| ca.publish val.to_s, msg } 
          else
            DEFAULT_BROADCAST
          end
        end
      end   
    end
  
    class RedisSub
      include Celluloid
      include Celluloid::Logger
      class SubscribeException < Exception; end
    
      attr_reader :timer, :subscription_size
      
      KEY_PROC = lambda { |it| "subbus#{it}".to_sym }
      
      finalizer :finalizer
      
      def initialize # redis
        @subscription_size = 0
        # NOTE: this was introduced to insure us we have no blocking connection 
        # @timer  = every( 3.5 ) { puts "Hello from timer!" }
      end

      def finalizer
       @subscription_size.times do |it|
         key = KEY_PROC.call it
         Actor[ key ].terminate if Actor[ key ]
       end
      end
      
      def presubscription channels = [], options = nil
        raise SubscribeException.new "Empty channels passed!" if channels.empty?
        key = KEY_PROC.call( @subscription_size += 1 ) 
        if @supervisor
          @supervisor.supervise_as( key, SubBus, options )
        else
          @supervisor = SubBus.supervise_as key, options
        end
        
        key
      end
      
      # channels array of chanells to subscribe to
      # options: msg claback with hash could be:
      #   :callback  => lambda { } or Proc.new {  }
      #   :broadcast => channel ZMQ publish to broadcast channel
      #   :send => [ actor, :method ] or [ :actor_name, :methos ] # if Actor is regietered
      def subscribe( channels = [], options = nil ) #, message
        key = presubscription channels, options
        Actor[ key ].async.subscribed *channels
      end
      
      # channels array of chanells to subscribe to
      # options: msg claback with hash could be:
      #   :broadcast => channel ZMQ publish to broadcast channel
      #   :send => [ actor, :method ] or [ :actor_name, :methos ] # if Actor is regietered
      def psubscribe( channels = [], options = nil ) #, message
        key = presubscription channels, options
        Actor[ key ].async.psubscribed *channels
      end
    end
end