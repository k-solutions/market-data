# -*- coding: utf-8 -*-
require_relative '../spec_helper'
require_relative '../../lib/channels/redis'
init_channels

describe Channels::RedisPub do
  let( :publisher ) { Celluloid::Actor[ Channels::REDIS_PUBLISHER  ] || Channels::RedisPub.new }

  it "should init publisher" do
    lambda { publisher }.should_not raise_error 
  end
  
  it "should raise exception on bad call" do
    # lambda do 
     # publisher.publish :test, nil
     # binding.pry
     # sleep 1 until publisher # need time to restart
    # end.should raise_error Channels::RedisPub::PublishException
  end
  
  it "should publish" do
    lambda { publisher.publish :test, :test }.should_not raise_error 
  end
  
  it "should publish not blocking" do
    lambda { publisher.async.publish :test, :test }.should_not raise_error 
  end
end
