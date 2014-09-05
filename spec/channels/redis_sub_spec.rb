# -*- coding: utf-8 -*-
require 'spec_helper'
init_channels true

describe Channels::RedisSub do
  
  def channels *items
    items.map { |it| Channels::DEFAULT_MSG_CHANNEL + it.to_s }
  end
  
  let( :subscriber )      { Celluloid::Actor[ Channels::REDIS_SUBSCRIBER ]  || Channels::RedisSub.new }
  let( :publisher )       { Celluloid::Actor[ Channels::REDIS_PUBLISHER  ]  || Channels::RedisPub.new }
  let( :actor )           { Celluloid::Actor[ :test_actor ] || TestActor.new  }
  let( :default_channel ) { Channels::DEFAULT_MSG_CHANNEL }
  it "should init subscriber" do
    lambda { subscriber }.should_not raise_error 
  end
  
  it "should be able to psubscribe" do
    lambda { subscriber.psubscribe [ 'test*' ] } .should_not raise_error
    expect { publisher.publish( 'test1', :test ); }.to change { sleep 0.05; actor.counter } 
  end
  
  describe :subscribe do
    it "should be able to subscribe" do
      lambda { subscriber.subscribe default_channel } .should_not raise_error
      lambda { subscriber.subscribe [ :test, :test1 ] } .should_not raise_error 
    end
    
    it "should be able to call actor callback" do
      subscriber.subscribe default_channel # [ :test, :test1 ] subscriber.channels.should include :test, :test1
      expect { publisher.publish default_channel, :test }.to change { sleep 0.05; actor.counter }
      # expect { publisher.publish( channels( 'test1' ), :test ) }.to change { actor.counter }    
    end
  end
end
