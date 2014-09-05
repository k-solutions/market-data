#!/usr/bin/env ruby
require 'pry'
require 'celluloid/autostart'

require_relative 'channels'
require_relative '../markets/publisher'
require_relative '../utility/random'

module Supervisors
  MS = Markets.init_storage
 
  # Supervisor for Publisher
  class Publisher
    include Celluloid
    include Celluloid::Logger

    # PUBLISHING_CHANNELS = ::Channels::Factory.group channel_label: :publisher, role: :publisher 
    # LISTENING_CHANNELS = ::Channels::Factory.group channel_label: :publisher, role: :subscriber 
    OPTIONS            = { listening_channels:  ::Channels::Factory.group( channel_label: :publisher ), 
                           publishing_channels: ::Channels::Factory.group( channel_label: :publisher, role: :publisher ) }

    PUBLISHER_KEY       = :publisher
    WORKER_KEY          = :publisher_worker
    WORKER_SYMBOL       = lambda { |market_code| "#{WORKER_KEY}_#{market_code}".to_sym }

    def initialize 
      raise ArgumentError.new "Missing markets storage!" unless defined?( MS ) or MS.keys.empty? 
      markets = MS.get( *MS.keys )
      raise ArgumentError.new "Empty markets storage!" if markets and markets.empty?

      supervisor =
      unless Actor[ ::Channels::REDIS_PUBLISHER ]
        supervisor = Supervisors::Channels.run! 
        supervisor.supervise_as PUBLISHER_KEY,  Markets::Publisher, OPTIONS
        supervisor
      else
        Markets::Publisher.supervise_as PUBLISHER_KEY, OPTIONS
      end
      raise SystemError.new "Publisher  not registerd as #{PUBLISHER_KEY}" unless Actor[ :publisher ]
      
      valid_codes = Actor[ :publisher ].valid_codes
      markets.select { |market| valid_codes.include? market.code }.each do |market|
        the_code = market.code
        the_key  = WORKER_SYMBOL.call( the_code )
        
        supervisor.supervise_as the_key, Utility::Random, { asset: the_code }
        raise  SystemError.new "Worker for #{ the_code } could not be instantiated" unless Actor[ the_key ]
        Actor[ the_key ].async.run
        info "Random generator run on the market: #{market.code} with key: #{the_key} listening to #{Actor[ the_key ].channel}"
      end

      info "Publisher supervisor started at: #{Time.now} with key #{PUBLISHER_KEY}"
    end
  end
end
