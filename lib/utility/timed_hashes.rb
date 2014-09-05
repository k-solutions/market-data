require 'celluloid/autostart'
require_relative 'sized_hash'

module Utility
  module Factory
    SIZED_HASH_PROC     = lambda { |h,k| h[k] = 0 }
    STAT_TIME_INTERVALS  = [ 1, 30, 60 ]
    # options: 
    #  assets: - array with assets codes to get history for
    #  type:   - the type could be nil or :stat
    def self.timed_hashes_options options = {}
      keys = ( options[ :assets ] and !options[ :assets ].empty? ) ? { keys: options[ :assets ] } : {}
      case options[ :type ]
      when :stat
        sized_hash_options = keys.empty? ? { default_proc: SIZED_HASH_PROC } : keys.update( default_proc: SIZED_HASH_PROC )
        { hash_options: sized_hash_options, time_intervals: STAT_TIME_INTERVALS }
      else
        keys.empty? ? {} : { hash_options: keys } # : {}
       end
    end
    
    def self.timed_hashes options = {}
      TimedHashes.new timed_hashes_options( options )
    end
  end
  
  # a collection of TimedHashes with diff time intervals
  class TimedHashes
    include Celluloid
    include Celluloid::Logger
    DEFAULT_INTERVALS = [ 1 ] # NOTE: the time intervals are in seconds 
    
    attr_reader :current_times, :hashes, :default
    # expect:
    # :hash_options   - see SizedHashes init options for details 
    # :time_intervals - array with time intervals to be used for hashes keys
    # :default        - default interval for the timed hashes
    # TODO: Add support for post_interval_callback
    def initialize options = {}
      @default ||= options[ :default ] if options[ :default ]
      init_current_timers
      init_timers_and_hashes options.fetch( :time_intervals, DEFAULT_INTERVALS ),  options.fetch( :hash_options, {} )
    end
    
    # Get a collection of stats
    # options:
    #  :key      - the key to get stats on - required
    #  :interval - the step interval as integer ( as defined in init ) to get stats on
    #  :range || :start, :length || :end, :length
    def get options = {}
      return [] unless the_item = get_item( options )
      the_item.get options
    end
    
    # gets SizedHashes elelement
    #  :interval - the interval/time to be set in TimedHashes
    def get_hash options = {}
      @hashes[ options.fetch(:interval, @default) ] 
    end
    
    # gets Sized hash elelement
    #  :interval - the interval/time to be set in TimedHashes
    #  :key      - the key/asset in the hash to set
    def get_item options = {}
      raise ArgumentError.new "Bad options passed to method" unless options[ :key ]
      
      get_hash(options)[ options[ :key ] ]
    end
    
    # get last Timed hash elelement
    def get_last_item options = {}
      get_item( options ).last
    end
    
    def do_with_last options
      raise ArgumentError.new "You need to supply a block" unless block_given?
      the_item = get_item( options )
      the_item[ nil ] = yield( the_item.last )
    end
    
    # return true if called with preset keys
    def has_preset_keys? options = {}
      get_hash( options ).has_preset_keys?
    end
    
    # check if key list has the :key
    # see get_item docs for details on options
    #  :key  - * must be set 
    def has_key? options = {}
      raise ArgumentError.new "Bad options passed to method! Key is not optional in #{options}." unless options[ :key ]
      return true unless has_preset_keys?( options )
      
      get_hash( options ).keys.include? options[ :key ]
    end
    private
    # sets current timers hash storage
    def init_current_timers
      current_time   = Time.now.utc.to_i
      @current_times = Hash.new { |hash,key| hash[key] = current_time }
    end
    
    # create time and init the hash key 
    def init_time_interval time_interval
      @hashes[ time_interval ].current_time = ( @current_times[ time_interval ] += time_interval )
    end
    
    def init_timers_and_hashes time_intervals, hash_options
      @default ||= time_intervals.first 
      @timers = Hash.new
      @hashes = Hash.new { |h,k| h[k] = SizedHashes.new hash_options }
      time_intervals.each do |time_interval|
        init_time_interval time_interval
        @timers[ time_interval ] = every( time_interval ) { init_time_interval time_interval }  
      end
    end
  end
end
