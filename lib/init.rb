#!/usr/bin/env ruby
require 'celluloid/autostart'

ENV['RAILS_ENV'] ||= 'development'
# = Hash Recursive Merge
#
# Merges a Ruby Hash recursively, Also known as deep merge.
# Recursive version of Hash#merge and Hash#merge!.
# 
# Category::    Ruby
# Package::     Hash
# Author::      Simone Carletti <weppos@weppos.net>
# Copyright::   2007-2008 The Authors
# License::     MIT License
# Link::        http://www.simonecarletti.com/
# Source::      http://gist.github.com/gists/6391/
#module HashRecursiveMerge
class ::Hash
  def rmerge!(other_hash)
    merge!(other_hash) { |key, oldval, newval| oldval.class == self.class ? oldval.rmerge!(newval) : newval }
  end
  
  def rmerge(other_hash)
    r = {}
    merge(other_hash) { |key, oldval, newval| r[key] = oldval.class == self.class ? oldval.rmerge(newval) : newval }
  end
end

module Channels
  CHANNEL             = 'zmq:internal'
  REDIS_PUBLISHER     = :redis_publisher
  REDIS_SUBSCRIBER    = :redis_subscriber
  ZMQ_BROADCASTER     = :zmq_broadcaster
  DEFAULT_MSG_CHANNEL = 'zmq:message' # on this channels goes all default publishing from subscriptions
end

module Markets
  # holds markets scheduled
  MARKET_STORAGE_KEY  = 'market:storage' # NOTE: This constant must be identical to application layer one   
  MarketStruct        = Struct.new :id, :code, :name, :description, :timezone, :city, :country,
                                    :regular_open_time, :regular_close_time, :regular_preopen_time,
                                    :utc_open_time, :utc_close_time, :utc_preopen_time,
                                    :suspended_at, :days_of_week, :precision, :tag_list
  def self.init_storage
    require_relative 'markets/market_storage'
    inst = MarketStorage.instance # unless defined? Markets::MARKET_STORE
    raise ArgumentError.new "Empty market storage, please go to Rails environment and run rake app:cache:warmup before running it" if inst.keys.empty?
    
    inst
  end
end
