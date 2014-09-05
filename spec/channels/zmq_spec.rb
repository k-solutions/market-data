# -*- coding: utf-8 -*-
require 'pry'
require 'spec_helper'
require_relative '../../lib/channels/channel'
require_relative '../../lib/utility/random'

describe Channels::Zmq do
  class Observer
    attr_reader :counter, :channel, :value
    
    def initialize target
      @counter = 0
      target.add_observer( self )
    end
    
    def update( channel, value )
      @counter += 1 
      @channel, @value = channel, value
    end
    
    def clear
      @counter = 0
    end
  end
  
  let( :channel )         { Channels::Zmq.new id: 'test1:test2' }
  let( :channel_reg_exp ) { channel.to_reg } 
  let( :observer )        { Observer.new channel }
  
  after( :each ) do 
    channel.unsubscribe
    channel.punsubscribe
  end
  
  it "should respond_to get_last" do
    channel.get_last( "#{channel.to_s}:new" ).should  == "new" # be_true
  end
  
  it "should respond to to_s" do
    channel.to_s.should include 'test1', 'test2', ':'
  end 
  
  it "should respond to to_reg" do
    "test1:test2:DJIA".should match channel_reg_exp # 'test1.test2.*'
    "test3:test2:DJIA".should_not match channel_reg_exp # 'test1.test2.*'
    "test1:test2:DJ".should_not match channel_reg_exp # 'test1.test2.*'
  end
  
  it "should respond to publish" do
    expect { channel.publish data: 'test' }.to_not raise_error
  end
  
  it "should respond to publish" do
    expect { channel.ppublish data: 'test' }.to_not raise_error
  end
  
  it "should respond to subscribe" do
    expect { channel.subscribe }.to_not raise_error
  end
  
  it "should respond to psubscribe" do
    expect { channel.subscribe }.to_not raise_error
  end 
  
  it "should respond to unsubscribe" do
    expect { channel.unsubscribe }.to_not raise_error
  end
  
  it "should respond to unsubscribe" do
    expect { channel.punsubscribe }.to_not raise_error
  end
  
  describe "subscribe to external publisher with async" do
    let( :publisher ) do 
      res = Utility::Random.new( asset: 'test' )
      res.async.run 
      
      res
    end
    let( :channel )   { Channels::Zmq.new id: Utility::Random::CHANNEL, role: :psubscribe }
    
    it "should notify observer" do
      Channels::BROADCASTER.pattern_register.clear
      publisher.should_not be_nil
      channel.role.should == :psubscribe
      observer.counter.should == 0
      expect { sleep 0.5 }.to change { sleep 0.05; observer.counter } #.from(0).to(1)
    end
  end
  
  describe :role do
    let( :channel ) { Channels::Zmq.new id: 'test1:test2', role: :subscribe }
   
    it "should have role and be subscribed" do
      channel.role.should == :subscribe
      observer.counter.should == 0
      sleep 0.5
      expect { channel.publish( data: 'test' ) }.to change { sleep 0.05; observer.counter }.from(0).to(1)
    end
  end
  
  describe :format_on_subscriber do
    let( :channel ) { Channels::Zmq.new id: 'test1:test2', role: :retranslator }
    it "should format value" do
      channel.subscribe
      expect { channel.publish data: "test1,test2" }.to change { sleep 0.0005; observer.counter } 
      observer.value.should include "test1", "test2" # }.from( it ).to( it + 1 )
    end
  end
  
  describe :psubscribe do
    after( :each ) { observer.clear }
    
    it "should notify observer on psubscribe" do
      the_channel = "#{channel.to_s}:new"
      the_channel.should match channel_reg_exp
      observer.counter.should == 0
      channel.count_observers.should == 1
      channel.psubscribe
      # binding.pry
      expect { channel.publish channel: the_channel, data: 'test' }.to change { sleep 0.0005; observer.counter }.from(0).to(1)
    end
  end
  
  describe :subscribe do
    let( :observer ) { Observer.new channel }
    after { observer.clear }
    it "should notify observer on subscribe" do
      observer.counter.should == 0
      channel.count_observers.should == 1
      channel.subscribe # binding.pry
      expect { channel.publish data: 'test' }.to change { sleep 0.0005; observer.counter } # .from(0).to(1)
    end
  end
end