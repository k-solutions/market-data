require 'celluloid/autostart'
require_relative '../utility/timed_hashes'

module Stream
  # Celluloid Agent Common Interface for subscribers
  # just inherit from it and implement your own broadcast method
  class Subscriber
    attr_reader :channels, :history

    # options:
    #   :channel  (optional default to CHANNEL constant) - the base channel to listen to
    #   :assets (optional) - list of channels to get data for, any other message will be rejected
    #   :history  (optional, default to false) - collect history data in it is own container
    def initialize options = {}
      raise ArgumentError.new "Missing :channels options in #{options}!" unless options[ :listening_channels ]
      pre_init( options )
      @channels ||= options[ :listening_channels ] # , CHANNEL
      @channels.subscribe_all self
      if options.fetch( :history, false ) and !@history # @set_history
#         ( options[:assets] and !options[:assets].empty? ) ? 
#             Utility::TimedHashes.supervise_as( :history, { hash_options: { keys: options[:assets] } } ) : 
#             Utility::TimedHashes.supervise_as( :history )
        @history = options[ :history ] # Utility::Factory.timed_hashes optoins # Actor[ :history ]
      elsif options[:assets]
        @assets ||= options[ :assets ]
      end # subscribe CHANNEL_REGEXP.call(@channel), :broadcast
      puts "Subscribed to channel: #{@channel.to_s}!"
    end
    
    def pre_init( options={} ); end

    # TODO: set broadcast in your main class
    # NOTE: This class serves only as Subscriber Actor Interface
    def update( the_channel, value )
      # code = get_code the_channel # .split(SEPARATOR).last
      return code, value unless @history
      return nil, nil    unless @history.has_key?( key: the_channel ) 
      @history.do_with_last( key: the_channel ) { |last| last << value }
      
      return the_channel, value
    end
  end
end
