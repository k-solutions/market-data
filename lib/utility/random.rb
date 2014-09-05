# require_relative '../gaussian'
require 'celluloid/autostart'
#require_relative '../channels/channel'
module Utility
  # Random values generator agent
  # Operates along with Pusher agent
  # And is supervised/instantiated via Supervisor
  class Random
    include Celluloid
    include Celluloid::Notifications
    # include Celluloid::Logger
    PERIOD       = 0.5 # seconds
    INIT_VALUE   = 1000
    CHANNEL      = defined?( Stream::CHANNEL ) ?  Stream::CHANNEL  : 'zmq:internal'  # unless defined? Markets::CHANNEL
    
    attr_reader :value, :channel

    # options:
    #  :asset                                             - the asset code to generate random for
    #  :asset_precission (optional - default is 2)        - precission asset is generate values with
    #  :channel          (optional default is CHANNEL)    - ZMQchannel to publish random values to
    #  :period           (optional default is PERIOD)     - period of random number generation
    #  :init_value       (optional default isINIT_VALUE ) - initial value to start generation from
    def initialize options = {} # market, channel = CHANNEL, period = PERIOD # _code
      raise ArgumentError.new "Missing asset!" unless options[:asset] # or !market.is_a?( Market ) #.find_by_code( @market_code )
      @value, @period, @market_precision, @channel, @gauss_generator = options.fetch(:init_value, INIT_VALUE ),
                                                                       options.fetch(:period, PERIOD), 
                                                                       options.fetch(:asset_precision, 2), 
                                                                       "#{options.fetch(:channel, CHANNEL)}:#{options[:asset]}", 
                                                                      Gaussian.new

      async.generate
      #info "Random generator started asset: #{@channel}."
    end

    # NOTE: Please execute this method as ! to be done in new tread as this will block your current forever
    def run
      @timer = every( @period ) { async.publish @channel, generate } 
    end

    # Cancel the current Actor run operation
    def cancel
      @timer.cancel
    end

    def generate
      @value += @gauss_generator.rand
      return @value = @value.round( @market_precision )  # round to market precision
    end
    
    # from: http://stackoverflow.com/a/9266488
    # TODO: unify data gnerators from publisher_test, this and guassian.rb
    class Gaussian
      def initialize(mean = 0.0, sd = 1.0, rng = lambda { Kernel.rand })
        @mean, @sd, @rng, @compute_next_pair = mean, sd, rng, false
      end
      
      def rand
        if (@compute_next_pair = !@compute_next_pair)
          # Compute a pair of random values with normal distribution.
          # See http://en.wikipedia.org/wiki/Box-Muller_transform
          theta, scale = ( 2 * Math::PI * @rng.call ), ( @sd * Math.sqrt(-2 * Math.log(1 - @rng.call)) )
          @g1 = @mean + scale * Math.sin(theta)
          @g0 = @mean + scale * Math.cos(theta)
        else
          @g1
        end
      end
    end
  end
end
