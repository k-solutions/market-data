#!/usr/bin/env ruby
require 'celluloid/autostart'

require_relative 'channels'
require_relative 'preprocessor'
require_relative 'publisher'
require_relative 'stat'

module Supervisors
  class Main < Celluloid::SupervisionGroup
    supervise Channels,     :as => :channels_supervisor
    supervise Preprocessor, :as => :preprocessor_supervisor
    supervise Publisher,    :as => :publisher_supervisor
    # supervise Stat,         :as => :stat_supervisor
  end
end