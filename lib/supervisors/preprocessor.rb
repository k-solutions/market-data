#!/usr/bin/env ruby

require 'celluloid/autostart'
require_relative 'channels'
require_relative '../utility/config'
require_relative '../markets/preprocessor'

module Supervisors
  class Preprocessor
    include Celluloid
    include Celluloid::Logger
    PREPROCESSOR_KEY = :preprocessor
    OPTIONS          = { listening_channels:  ::Channels::Factory.group( channel_label: :preprocessor ),
                         publishing_channels: ::Channels::Factory.group( channel_label: :preprocessor, role: :publisher ) }

    def initialize 
      unless Actor[ ::Channels::REDIS_PUBLISHER ]
        supervisor = Supervisors::Channels.run! 
        supervisor.supervise_as PREPROCESSOR_KEY, Markets::PreProcessor, OPTIONS
      else
        Markets::PreProcessor.supervise_as PREPROCESSOR_KEY, OPTIONS
      end
      info "Preprocessor supervisor started at: #{Time.now} with key #{PREPROCESSOR_KEY}"
    end
  end
end
