# -*- coding: utf-8 -*-
require 'spec_helper'
init_channels true

describe Channels::SubBus do
  let( :actor )  {  Celluloid::Actor[ :test_actor ] || TestActor.new } 
  let( :subbus ) {  Channels::SubBus.new  } 
  
  it "should init" do
    lambda {  subbus }.should_not raise_error 
  end
  
  it "should be able to set default callback" do
    ctr = actor.counter # .should == 0 
    subbus.callback.should be_a Proc # == Markets::Redis::MsgBus::DEFAULT_BROADCAST
    expect { subbus.callback.call( Channels::DEFAULT_MSG_CHANNEL, :test ) }.to change{ actor.counter }.from( ctr ).to( ctr + 1 )
  end
  
  it "should be able to set send callback" do
    ctr = actor.counter # s.should == 0
    subbus = Channels::SubBus.new :send => [ actor, :broadcast ]
    subbus.callback.should be_a Proc # == Markets::Redis::MsgBus::DEFAULT_BROADCAST
    expect { subbus.callback.call( Channels::DEFAULT_MSG_CHANNEL, :test ) }.to change{ actor.counter }.from( ctr ).to( ctr + 1 )
  end
  
  it "should be able to unsubscribe" do
    subbus.async.subscribed "test"
    lambda { subbus.unsubscribe_all }.should_not raise_error
  end
end
