#!/usr/bin/env ruby

require 'celluloid/autostart'
require_relative '../utility/config'
require_relative '../stream/stat'
require_relative '../channels/channel'

module Supervisors
  class Stat # < Celluloid::SupervisionGroup
    include Celluloid
    include Celluloid::Logger
    HASH_OPTIONS  = ::Utility::Factory.timed_hashes_options type: :stat #, assets: [ 'test' ]
    CHANNELS      = ::Channels::Factory.group channel_label: :subscriber
    
    # NOTE: set :assets if you like statistics for specific market assets
    def initialize
      supervisor =
      unless Actor[ ::Channels::REDIS_PUBLISHER ]
        supervisor = Supervisors::Channels.run! 
        supervisor.supervise_as :stat_history, ::Utility::TimedHashes, HASH_OPTIONS
        
        supervisor
      else
         ::Utility::TimedHashes.supervise_as :stat_history, HASH_OPTIONS # args: [ OPTIONS[ :int ] ]
      end
      supervisor.supervise_as :stat, ::Stream::Stat, { listening_channels: CHANNELS, history: Actor[ :stat_history ] }
      info "Stats supervisor started at: #{Time.now} with key :stat and stat history as :stat_history"
    end
  end
end