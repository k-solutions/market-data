#!/usr/bin/env ruby

require_relative 'tick'
require_relative 'subscriber'
# NOTE: all this seems obsolete
# module HasChannels
# 
#   def set_channels(channel_settings)
#     channel_settings.each{ |key, settings|
#       init_channel( key, *parse_channel_settings(settings))
#     }
#   end
# 
#   def callbacks
#     @callbacks ||= {}
#   end
# 
#   protected
#   def init_channel(key, channel, options={})
#     old_channel = instance_variable_get("@#{key}_channel")
#     old_channel.clean_up(self) if old_channel
#     if channel
#       callbacks[key] = options[:callbacks] if options[:callbacks]
#       callback = callbacks[key]
#       channel.add_observer(observer, callback) if callback
#     end
#     instance_variable_set("@#{key}_channel", channel)
#   end
# 
#   private
#   def parse_channel_settings(channel_settings)
#     if channel_settings.is_a? Channel
#       [channel_settings]
#     else
#       [channel_settings.delete(:channel), channel_settings]
#     end
#   end
# end
# 
# module Listener
#   include HasChannels
# 
#   def listens_to(subscriptions)
#     set_channels(subscriptions)
#   end
# 
# end
# 
# module Publisher
#   include HasChannels
# 
#   def publishes_to(channels)
#     set_channels(channels)
#   end
# end

module Stream
  class Rankables < Array
    # remove all Rankables marked for deletion
    def prune!
      # TODO: lock
      delete_if { |rankable| rankable.delete? }
      # TODO: unlock
    end

  end

  class Refiner # abstract
    attr_reader :threshold

    def initialize(args={})
      args = defaults.merge(args)
      @threshold = args[:threshold]
    end

    def defaults
      {:threshold => 0}
    end

    def refine(rankables)
       aggregates(rankables) + rankables.select { |r| r.total_rank >= threshold }
    end

    protected
    def aggregates(rankables)
      []
    end
  end

  class TickRefiner < Refiner
    protected
    def aggregates(rankable_ticks)
      return [] if rankable_ticks.nil? || rankable_ticks.size == 0
      sum = rankable_ticks.reduce(0) { |sum, tick| sum + tick.value }
      # TODO: use BigDecimal not float
      [ Tick.new( sum.to_f / rankable_ticks.size, :created_at => Time.now.utc.to_f ) ]
    end
  end

  class Refinery < Subscriber
    # include ::Commandable
    # include ::Listener
    # include ::Publisher
    attr_reader :refiner, :rankers, :rankables # :publish_channel, :data_channel, :command_channel

    # channels format
    # 
    def initialize(channels, refiner = Refiner.new, args={})
      args = defaults.merge(args)
      # set_channels(channels)
      @refiner = refiner
      @rankers = []
      @rankables = Rankables.new
# TODO: we should implement in future iterations
#       accepts_commands(:rank)
#       listens_to({:data => {
#                     :channel => channels[:data],
#                     :callback => :store,
#                     :required => true },
#                   :command => {
#                     :channel => channels[:command],
#                     :callback => :command }
#                   })
      # publishes_to( {:publish => {:channel => channels[:publish], :required => true} } ) # ZMQ
      # publish  channels[:publish].to_s
    end

    def defaults
      { }
    end

    def register_ranker(ranker)
      @rankers << ranker
    end

    def store(data)
      data.extend(Rankable)
      rankables << data
    end

    # currently only available to :rank Command
    def rank
      send_to_rankers(rankables.prune!)
    end

    def refine
      publish( refiner.refine(rankables) ) # NOTE: actual publishing
    end

    private
    def send_to_rankers
      # futures = rankers.map do |ranker|
      #   ranker.future(:rank, rankables)
      # end
    end

    def publish(data)
      # @publish_channel.broadcast(data)
    end
  end
end






