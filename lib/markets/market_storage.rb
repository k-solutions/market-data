require 'set'
require 'time'
require 'singleton'
require_relative 'storage'
require_relative '../init'

module Markets
  # A storage class for all schedulers
  class MarketStorage < Storage
    include Singleton

    def initialize
      super MARKET_STORAGE_KEY  # storage_key
    end

    def add *markets
      super *get_storage_args( markets )
    end

    def reset *markets
      super *get_storage_args( markets )
    end

    def get *markets
      super *get_market_keys( markets )
    end

    def delete *markets
      super *get_market_keys( markets )
    end

    protected
    def to_time time, timezone
      case time
      when String
        to_time Time.parse( time ), timezone
      when Time
        time.in_time_zone(timezone).utc.strftime("%T")
      when nil
        ""
      else
        raise ArgumentError.new "Bad parameter passed to method!"
      end
    end

    def to_utc_time market, time_field
      return nil unless ts = market.try( time_field.to_sym )

      Time.at(ts.to_f)
    end
    def transform market
      Markets::MarketStruct.new market.id, market.code, market.name, market.description, market.timezone, market.city, market.country,
                                  to_utc_time(market,:regular_open_time),to_utc_time( market,:regular_close_time),to_utc_time(market,:regular_preopen_time),
                                  to_time(market.regular_open_time, market.timezone),
                                  to_time(market.regular_close_time, market.timezone),
                                  to_time(market.regular_preopen_time, market.timezone),
                                  to_utc_time(market,:suspended_at), market.days_of_week, market.precision, market.tag_list.to_set
    end

    def get_storage_args args
      first = args.first
      if defined? Market
        case first
        when Market
          args.map { |it| [ it.code, transform(it) ]  }
        when Markets::MarketStruct
          args.map { |it| [ it.code, it ] }
        else
          raise ArgumentError.new "Wrong arguments passed to method: #{args}"
        end
      elsif first.is_a? Markets::MarketStruct
        args.map { |it| [ it.code, it ] }
      else
        raise ArgumentError.new "Wrong arguments passed to method: #{args}"
      end
    end
  end
end
