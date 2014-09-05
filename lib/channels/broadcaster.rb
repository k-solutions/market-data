#!/usr/bin/env ruby
# require 'pry'
require 'celluloid/autostart'
require_relative '../utility/sized_hash'

module Channels
  class Register
    MAX_CHANNELS = 10 # the maximum channels to hold into register
    
    def initialize
      @has_regexp, @hash = false, Utility::SizedHash.new( MAX_CHANNELS )
    end
    
    def unset channel, callback
      return unless ( it = @hash[ channel ].find_index { |cb| cb == callback } )
      @hash[ channel ].delete_at( it )
    end
    
    def set channel, callback
      return unless channel or callback
      @has_regexp = true if channel.is_a? Regexp
      @hash[ channel ] << callback
    end
    
    def get channel
      if @has_regexp
        @hash.inject( [] ) { |res, it| res += ( it[0].is_a?( Regexp ) and it[0].match( channel ) ) ? it[1] : [] }
      else
        @hash[ channel ]
      end
    end
    
    def clear
      @hash.clear
    end
  end
  
  class ZmqBroadcaster
    include Celluloid
    include Celluloid::Notifications
    
    attr_reader :callbacks, :register, :pattern_register

    def initialize
      @subscriptions, @callbacks, @register, @pattern_register = {}, [], Register.new, Register.new
    end
    
    # You could call this with regexp only
    def plisten channel, callback = nil
      _get_source( true ).set channel, callback
      @subscriptions[ channel ] = subscribe channel, :_pbroadcast
    end
    
    def listen channel, callback = nil
      _get_source.set channel, callback
      @subscriptions[ channel ] = subscribe channel, :_broadcast
    end
    
    def premove channel, callback = nil
      _remove channel, callback, true
    end
    
    def remove channel, callback = nil
      _remove channel, callback
    end
    
    # NOTE: This need to be callable from outside (Celluloid do this), but never called directly
    def _pbroadcast the_channel, value
      _send_callback the_channel, value, true
    end
    
    def _broadcast the_channel, value
      _send_callback the_channel, value
    end
    
    private
    def _remove channel, callback, pattern = false
      return unless @subscriptions[ channel ]
      _get_source( pattern ).unset channel, callback
      unsubscribe( @subscriptions[ channel ] )
    end
    
    def _get_source  pattern = false
      pattern ? @pattern_register : @register
    end
    
    def _get_callbacks channel, pattern = false
      _get_source( pattern ).get( channel ).compact
    end
    
    def _send_callback the_channel, value, pattern = false
      return the_channel, value if ( @callbacks = _get_callbacks( the_channel, pattern ) ).empty?
      @callbacks.each { |callback | callback.call the_channel, value } 
    end
  end
end