require_relative 'rankable'

module Stream
  class Msg
    SPLIT_FORMAT = ','
    
    attr_accessor :market_code, :contributor, :time, :trade, :bid, :ask
    
    def initialize msg, split_format = SPLIT_FORMAT
      raise ArgumentError.new "Missing message in the method call!" unless msg
      
      @split_format = split_format
      case msg
      when String
        @market_code, @contributer, @time, @trade, @bid, @ask = msg.split(@split_format)
        raise ArgumentError.new "Bad message size!" unless @market_code and @contributer and @time and @trade and @bid and @ask 
      when Array
        raise ArgumentError.new "Bad message size!" if msg.size != 6
        @market_code, @contributer, @time, @trade, @bid, @ask = msg
      else
        raise ArgumentError.new "Unkown message type"
      end
    end
    
    def to_a
      [ @market_code, @contributer, @time, @trade, @bid, @ask ] 
    end
    
    def to_s
      to_a.join @split_format
    end
  end
  
  class Tick
    include Rankable
    attr_reader :value, :trade_time, :received_at, :created_at, :contributor

    def initialize(value, args={})
      @value        = value
      @trade_time   = args.fetch(:trade_time,  nil)
      @received_at  = args.fetch(:received_at, nil)
      @created_at   = args.fetch(:created_at,  Time.now.utc)
      @contributor  = args.fetch(:contributor, "")
    end

    def time
      @trade_time || @received_at || @created_at || 0
    end
  end
end