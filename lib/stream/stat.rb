#!/usr/bin/env ruby

require_relative '../init'
require_relative '../stream/subscriber'

module Stream
  # Celluloid Agent to collect stream statistics
  class Stat # < Subscriber
    include Celluloid
    include Celluloid::Logger
    
    attr_reader :history, :channels
    
    MIN_STAT_PERIOD     = 60 # NOTE: this timeout is when minets stat is collected from seconds stats
    STAT_STEP           = 1
    SUM_PROC            = lambda { |arr| arr.inject( 0 ) { |res, it| res += it } }
    
    extend Forwardable
    def_delegators :history, :get, :get_item, :get_last_item
    
    # options:
    #  history:  - the history time hashes object to hold statistics
    #  channels: - a channels group to subscribe to
    def initialize options = {} # , *markets
      raise ArgumentError.new "Missing options :history or :channels in #{options}" unless options[ :history ] or options[ :listening_channels ]
      @channels, @history = options[ :listening_channels ], options[ :history ] # Actor[ :stat_history ]
      @channels.subscribe_all self
      # @stat_timer = every( MIN_STAT_PERIOD ) { async.collect }
    end
    
    def update( the_channel, value )
      @history.do_with_last( key: the_channel ) { |last| last += STAT_STEP }
      info "Registered #{the_channel} and #{value}"
      return the_channel, value
    end
    
    def collect
      the_hash = @history.get_hash
      the_hash.each_key do |key|
        cur_history = get( key: key )
        info "Empty history for #{key}" and next if cur_history.empty?
        info "History recorded in #{key} is: #{cur_history}"
        @history.do_with_last( interval: 60, key: key ) { |last| last = SUM_PROC.call cur_history  }
      end
    end
  end
end
