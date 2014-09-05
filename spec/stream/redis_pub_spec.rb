# -*- coding: utf-8 -*-
require_relative '../spec_helper'
require_relative '../../lib/stream/redis'

describe Stream::RedisPub do
  let( :publisher ) { Stream::RedisPub.new }

  it "should init publisher" do
    lambda { Stream::RedisPub.new }.should_not raise_error 
  end
  
  it "should raise exception on bad call" do
    lambda { publisher.publish :test, nil }.should raise_error Stream::RedisPub::PublishException
  end
  
  it "should publish" do
    lambda { publisher.publish :test, :test }.should_not raise_error 
  end
  
  it "should publish not blocking" do
    lambda { publisher.async.publish :test, :test }.should_not raise_error 
  end
end
