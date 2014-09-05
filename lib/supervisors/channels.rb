#!/usr/bin/env ruby
require 'celluloid/autostart'

require_relative '../init'
require_relative '../channels/redis'
require_relative '../channels/broadcaster'
require_relative '../channels/channel'

module Supervisors
  class Channels < Celluloid::SupervisionGroup
    supervise ::Channels::RedisPub,       :as => ::Channels::REDIS_PUBLISHER  # :redis_publisher
    supervise ::Channels::RedisSub,       :as => ::Channels::REDIS_SUBSCRIBER # :redis_subscriber
    supervise ::Channels::ZmqBroadcaster, :as => ::Channels::ZMQ_BROADCASTER
  end
end