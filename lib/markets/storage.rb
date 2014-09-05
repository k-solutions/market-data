require 'hiredis'
require_relative '../utility/redis'

module Markets
  REDIS = Utility::Redis.get_connection( :hiredis ) unless defined? REDIS

  # Cammon interface to redis storage
  class Storage
    attr_reader :redis_key, :market_classes

    def initialize redis_key='redis_key'
      raise ArgumentError.new "Redis connection is not available!" unless REDIS

      @redis_key ||= redis_key
      @market_classes = []
      @market_classes = [ Market, MarketStruct ] if defined? Market 
      @market_classes = [ MarketStruct ] if defined? MarketStruct
    end

    # add arguments to storage if not exists
    # 2 elements array [ [ key1, val1 ], [ key2, val2 ] ] expected
    def add *args
      raise ArgumentError.new "Blank arguments passed!" if args.empty?
      return set args[0], args[1] if args.first.is_a?( String ) and args.size == 2

      the_keys = keys
      if the_keys.empty?
        set *args
      elsif array_arg_list? args
        new_args = args.reject { |it| the_keys.include?( it[0].to_s ) }
        new_args.empty? ? the_keys : set( *new_args )
      elsif the_keys.include? args.first.to_s
        the_keys
      else
        set *args
      end
    end

    # return value for the given keys
    def get *keys
      keys.compact!
      raise ArgumentError.new "Blank keys passed or no value stored #{keys}!" if keys.empty? or ( stored = mget( *set_keys( keys ) ).compact ).empty?

      # ( stored.size == 1 ) ? JSON.parse( stored.first ) : ( stored.map { |it| JSON.parse( it ) if it.is_a? String } )
      ( stored.size == 1 ) ? Marshal.load( stored.first ) : ( stored.map { |it| Marshal.load( it ) if it.is_a? String } )
     end

    # reset to new value
    def reset *args
      raise ArgumentError.new "Blank arguments passed!" if args.empty?

      set *args
    end

    # takes array of keys to be deleted
    def delete *args
      raise ArgumentError.new "Blank argument passed!" if args.empty?

      unset *set_keys( args )
    end

    # cleans all stored values
    def clean
      the_keys = keys( false )

      unset *the_keys unless the_keys.empty?
    end

    def keys original = true
      REDIS.write [ 'SMEMBERS', @redis_key ]

      original ? get_keys( REDIS.read ) : REDIS.read # smembers @redis_key
    end

    protected # NOTE: to be used from parent classes as well
    def get_market_keys args
      first = args.first
      case first
      when *@market_classes
        args.map { |market| market.code }
      when String
        args
      when Symbol
        args.map( &:to_s )
      else
        raise ArgumentError.new "Bad parameters passed to method: #{args}"
      end
    end

    def mget *args
      REDIS.write args.unshift( 'MGET' )
      REDIS.read
    end

    def multi
      raise ArgumentError.new "Block is expected!" unless block_given?
      begin
        REDIS.write [ 'MULTI' ] # do
        yield
        REDIS.write [ 'SMEMBERS', @redis_key ]
        REDIS.write [ 'EXEC' ]

        nil while ( res = REDIS.read ).is_a?( String )
        return get_keys res.last if res.is_a? Array
      end
    end

    def unset *args
      multi do
        REDIS.write [ 'DEL', *args ]  # [ 'DEL', keys ]   # keys
        REDIS.write [ 'SREM', @redis_key, *args ] # srem @redis_key, *keyss
      end
    end

    def array_arg_list? args
      first = args.first
      case first # REDIS.sadd( @redis_key, key )
      when Array  # multi set
        true
      when String, Symbol # single set
        raise ArgumentError.new "Parameters passed must be key, val or [key1, val1], [key2, val2] ..." unless args.size == 2
        false
      else
        raise ArgumentError.new "Parameters passed must be key, val or [key1, val1], [key2, val2], where key is string or symbol..." # unless args.size == 2
      end
    end

    def get_keys args
      args.map { |v| v.split(":").last }
    end

    def set_key arg
      "#{@redis_key}:#{arg}"
    end

    def set_keys args
      case args.size
      when 1
        [ set_key( args.first ) ]
      else
        args.map { |k| set_key k }
      end
    end

    # set new values only
    def set *args
      if array_arg_list? args
        the_arr = args.inject( [] ) { |res, it| res << set_key( it[0] ) << Marshal.dump( it[1] ) } # it[1].to_json }
        multi do
          REDIS.write [ 'MSET', *the_arr ]
          REDIS.write [ 'SADD', @redis_key, *the_arr.select { |it| (the_arr.index(it) % 2) == 0 } ] # *Hash[ args ].keys ]
        end
      else
        the_key = set_key( args.first ) #.to_s
        multi do
          REDIS.write [ 'SET', the_key, Marshal.dump( args[1] ) ] # args[1].to_json ] # ( , value.to_json )  # if REDIS.sadd( @redis_key, key ) == 1
          REDIS.write [ 'SADD', @redis_key, the_key ]
        end
      end
    end
  end
end
