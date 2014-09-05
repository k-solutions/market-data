#!/usr/bin/env ruby

require 'bigdecimal'
require 'bigdecimal/util'

require_relative '../init'
require_relative '../utility/config'
require_relative '../stream/tick'

module Markets
  class PreProcessor
    include Celluloid
    include Celluloid::Logger
    
    # main contants
    RAILS_ENV             ||= ENV['RAILS_ENV'] || 'development'
    CONFIG_FILE           ||= 'config/interactive_data.yml'
    # markets data
    MARKET_STORAGE        ||= Markets.init_storage
    THE_MARKETS           = MARKET_STORAGE.get( *MARKET_STORAGE.keys )
    ASSETS_EXPECT_BIDASK  = THE_MARKETS.reject { |m| m.tag_list.map( &:downcase ).include?("index") }.map( &:code ).uniq
    MARKET_PRECISIONS     = Hash[ THE_MARKETS.map { |m| [ m.code , m.precision ] } ]
    # various constant to help us calculate
    ROUNDING_MODE         = BigDecimal::ROUND_HALF_EVEN
    BD_TWO                = BigDecimal.new("2.0")
    # position for elemets in the message
    DEFAULT_PREC          = 2 # It is not suposed to be used but if we have no precision in the table
    OPTIONS               = Utility::Parser.get CONFIG_FILE, RAILS_ENV, true
    attr_reader :subscriptions, :listening_channels, :publishing_channels, :split_format

    # Take as options hash where:
    # :listening_channels, :publishing_channels - are channels groups with listening subscriptions channels to bind to
    # :callbacks    - hash with callbacks to prepare channel messages
    # :split_format - format message separator
    def initialize options # , pre_process_blk
      # raise ArgumentError.new "Missing publisher or subscriber" unless Actor[ :subscriber ] and Actor[ :publisher ]
      # parsed_options = Utility::Parser.get CONFIG_FILE, RAILS_ENV, true
      raise ArgumentError.new "Missing channels options!" unless options[ :listening_channels  ] and
                                                                 options[ :publishing_channels ] # and options[ :split_format ] # and pre_process_blk 

      @listening_channels, @publishing_channels = options[ :listening_channels ], options[ :publishing_channels ] # , options[ :split_format ], options[ :callbacks ]
      
      raise ArgumentError.new "Missing subscriptions in the config file: #{CONFIG_FILE}" unless OPTIONS['subscriptions']
      @subscriptions = Hash[ OPTIONS['subscriptions'].map { |it| [ it[1][2], it[0] ] } ]
      
      @listening_channels.subscribe_all current_actor
    end
    
    def update chn, msg
      # return unless ( channel = _get_channel_last( chn ) ) and ( message = post_process( pre_process( chn, msg ) ) )
      # return unless channel and message
      # info "Preprocessor send message: #{message} on channel: #{channel}"
      # Actor[ :publisher ].async.publish channel, message 
      # async.publish_all channel, message
      return unless ( message = post_process( pre_process( msg ) ) )
      @publishing_channels.ppublish_all chn, message
    end

    # protected
    # Calculates average values from bid ask price
    def avg_value msg 
      # NOTE: market value is average of bid/ask if available, otherwise trade price
      market_precision = ( MARKET_PRECISIONS[ msg.market_code ] || DEFAULT_PREC )
      value =
      if ( msg.ask.is_a?(String) && msg.bid.is_a?(String) ) or ( msg.ask.is_a?( Float ) && msg.bid.is_a?( Float ) && msg.ask > 0 && msg.bid > 0 )
        (msg.ask.to_d + msg.bid.to_d)/BD_TWO # .round(data.precision, ROUNDING_MODE)
      else
        msg.trade.to_d #.round(data.precision, ROUNDING_MODE)
      end

      return "-1" if value < 0

      value.round(market_precision, ROUNDING_MODE).to_s('F')
    end

    def pre_process message
      message.is_a?( Stream::Msg ) ? message : Stream::Msg.new( message, @split_format )
    end

    def post_process msg # args
      return unless msg.market_code = @subscriptions[ msg.market_code ]
      msg.trade = avg_value( msg ) if ASSETS_EXPECT_BIDASK.include?( msg.market_code )

      msg.to_a # "#{@publishing_channel}.#{msg.market_code}", msg.to_s # feature.value 
    end
  end
end