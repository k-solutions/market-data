#!/usr/bin/env ruby
require_relative '../init'
require_relative '../stream/tick'
require_relative '../channels/redis'

module Markets
  # Celluloid Agent to push data to juggernaut queue directly
  class Publisher # < Stream::Subscriber
    include Celluloid
    include Celluloid::Logger
    
    RAILS_ENV  ||= 'development'
    CONFIG_FILE  = '/config/interactive_data.yml'
    CONTRIB_ID   = 'LOCK'
    OPTIONS      = Utility::Parser.get CONFIG_FILE, RAILS_ENV, true

    attr_reader :counter, :valid_codes, :msg_data, :subscriptions, :listening_channels
    # see subscriber init options for details
    def initialize options = {}
      raise ArgumentError.new "Missing channels options!" if (options[ :listening_channels ] and options[ :listening_channels ].empty?) and
                                                             (options[ :publishing_channels ] and options[ :publishing_channels ].empty?) 
      @listening_channels, @publishing_channels = options[ :listening_channels ], options[ :publishing_channels ]
      @listening_channels.subscribe_all current_actor
      
      raise ArgumetError.new "Unable to locate subscriptions into #{CONFIG_FILE} config file" unless @subscriptions = OPTIONS['subscriptions'] 
      @counter, @valid_codes = 0, @subscriptions.keys
      raise ArgumentError.new "You have missing data: #{@subscriptions} in the publisher config #{CONFIG_FILE}" if @valid_codes.empty?
      @msg_data = lambda { |code, val| [ @subscriptions[code][2], CONTRIB_ID, Time.now.utc.to_f, val.to_f, ( val + rand(0.01)).to_f, ( val + rand(0.01)).to_f  ] }
    end
    
    # NOTE: this method is called on publish event
    def update( the_channel, value )
      return unless the_channel or @valid_codes.include?( the_channel )
      @counter += 1
      msg = process( the_channel, value )
      # binding.pry
      @publishing_channels.ppublish_all the_channel, msg
      return the_channel, msg
    end
    
    def process market_code, value
     @msg_data.call( market_code, value ) # @msg_processing_proc.call( arr ) info "Processing #{market_code} with #{value} to #{res}" res
    rescue ScriptError => e 
      raise StandardError.new "Error in a passed code detected: #{e} with: #{e.backtrace}"#
    end

    def terminate
      info "Published #{@counter} messages!\n"
      super
    end
  end
end
