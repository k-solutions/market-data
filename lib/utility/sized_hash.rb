module Utility
  # Create a hash that could not exceed given max size 
  class SizedHash # < Hash
    HASH_METHODS  = [ :delete, :clear, :values_at, :keys, :values, :size, :length, :[], :fetch, :shift, :empty?, :each, :each_key, :inject ]
    MAX_SIZE      = 7200 # 2 hours in seconds
    DEFAULT_PROC  = lambda { |hash, key| hash[ key ] = [] }
    DEFAULT_RANGE_PERIOD = 60 # NOTE: the dafault of the range to be returned from get interface message
    
    extend Forwardable
    def_delegators :hash, *HASH_METHODS
    
    attr_reader :max_size, :hash
  
    def initialize max_size = MAX_SIZE, default_proc = nil
      @hash, @max_size = {}, max_size.to_i
      raise ArgumentError.new "The maximum size is very low!" if @max_size <= 1
      hash.default_proc = default_proc ? default_proc : DEFAULT_PROC
    end
    
    # Get a segment of the hash
    # options: 
    #  :range || :start, :length || :end, :length
    #  :default_range must introduxed somehow 
    def get options = {}
      return [] if hash.empty?
      range = options.fetch :range, create_range( options )
      hash.values_at *( hash.keys & range.to_a )
    end
    
    def last
      @hash[ last_key ]
    end    
    
    def merge! hash
      hash.merge! hash
    end
  
    def current_time= cur_time
      raise ArgumentError.new "Undefined #{cur_time}" unless cur_time
      @current_time = cur_time
      
      last
    end
    
    def []= key, value
      @hash[ key || last_key ] = value
      reduce
    end
    alias :store :[]=
    
    private
    
    def last_key
      hash.keys.last || @current_time
    end
    
    # see get methods for more details on options
    def create_range options = {}
      # raise ArgumentError.new "Bad options paased to method: #{options}" unless options[:length] and ( options[:start] or options[:end] )
      if options[:start]
        options[:start].to_i..(options[:start] + options[:length] - 1).to_i
      elsif options[ :end ]
        (options[:end] - options[:length] + 1).to_i..options[:end].to_i
      else
        default_range
      end
    end
    
    def default_range
      (@current_time - DEFAULT_RANGE_PERIOD)..@current_time
    end
    
    def reduce
      return if empty? and ( @max_size >= size )
      shift while @max_size < size
    end
  end
  
  class SizedHashes
    extend Forwardable
    def_delegators :the_hash, *( SizedHash::HASH_METHODS )
    
    attr_reader :the_hash, :keys
    # collection of sized hashes with common default_proc
    #  :max_size     - to be init as maz size per collection item
    #  :default_proc - default proc for the collection items
    def initialize options = {}, item_class = SizedHash
      if options[ :keys ] and !options[ :keys ].empty?
        @keys, @the_hash = options[ :keys ], Hash.new 
        options[ :keys ].each { |key| @the_hash[ key ] = init_hash_item( options ) }
      else
        @the_hash = Hash.new { |h,k| h[k] = init_hash_item( options ) }
      end
    end
    
    # retunr true if called with preset keys
    def has_preset_keys?
      !@keys.nil?
    end
    
    # key to get info on
    def get options= {}
      return [] if @the_hash.empty?
      @the_hash[ options[ :key ] || @the_hash.keys.last ].get options
    end
    
    def current_time= cur_time
      @the_hash.each_key { |k| the_hash[ k ].current_time = cur_time }
    end
    
    private
    def init_hash_item options, item_class = SizedHash
      item_class.new( options.fetch( :max_size, SizedHash::MAX_SIZE ), 
                      options.fetch( :default_proc, SizedHash::DEFAULT_PROC ) ) 
    end
  end
end
