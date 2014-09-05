# -*- coding: utf-8 -*-
# require 'pry'
require 'spec_helper'
require_relative '../../lib/channels/channel'
init_channels

describe Channels::Redis do
  class Observer
    attr_reader :counter, :channel, :value
    
    def initialize target
      @counter = 0
      target.add_observer( self )
    end
    
    def update( channel, value )
      @counter += 1 
      # binding.pry # puts 
      @channel, @value = channel, value
    end
    
    def clear
      @counter = 0
    end
  end
  
  let( :channel_id  ) { 'test1.test2' }
  let( :channel )     { Channels::Redis.new id: channel_id }
  let( :observer )    { Observer.new channel }
  
  after( :each ) do 
    channel.unsubscribe
    channel.punsubscribe
  end
  
  it "should respond_to get_last" do
    channel.get_last( "#{channel_id}.new" ).should  == "new" # be_true
  end
  
  it "should respond_to match" do
    channel.match?( "#{channel_id}.new" ).should be_true
  end
  
  it "should respond to to_s" do
    channel.to_s.should include 'test1', 'test2', '.'
  end 
  
  it "should respond to to_reg" do
    channel.to_reg.should include 'test1', 'test2', '.', '*' # 'test1.test2.*'
  end
  
  it "should respond to publish" do
    expect { channel.publish data: 'test' }.to_not raise_error
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
  
  describe "subscribe to external publisher" do
    let( :publisher ) { Channels::PUBLISHER }
    let( :channel )   { Channels::Redis.new id: 'test', role: :subscribe }
    
    it "should notify observer" do
      publisher.should_not be_nil
      channel.role.should == :subscribe
      observer.counter.should == 0
      expect { publisher.publish 'test', 'test' }.to change { sleep 0.05; observer.counter } #.from(0).to(1)
    end
  end
  
  describe :format_on_publish do
    let( :channel ) { Channels::Redis.new id: channel_id, format: ',', format_method: :join }
    
    after( :each ) do 
      observer.clear
      channel.unsubscribe
      channel.punsubscribe
    end
    
    it "should format value on subscribe" do
      channel.subscribe
      sleep 0.5
      expect { channel.publish data: ["test1", "test2" ] }.to change { sleep 0.05; observer.counter }.from(0).to(1)
      observer.value.should include "test1", "test2" # }.from( it ).to( it + 1 )
      observer.value.should have( 11 ).items
    end
  end  
  
  describe :format_no_subscriptions do
    let( :channel ) { Channels::Redis.new id: channel_id, role: :subscribe, format: ',', format_method: :split }
    
    after( :each ) do 
      observer.clear
      channel.unsubscribe
      channel.punsubscribe
    end
    
    it "should format value on subscribe" do
      channel.role.should == :subscribe
      sleep 0.5
      expect { channel.publish data: "test1,test2" }.to change { sleep 0.05; observer.counter }.from(0).to(1)
      observer.value.should include "test1", "test2" # }.from( it ).to( it + 1 )
      observer.value.should have( 2 ).items
    end
  end
  
  describe :role do
    let( :channel ) { Channels::Redis.new id: channel_id, role: :subscribe }
    
    after( :each ) do 
      observer.clear
      channel.unsubscribe
      channel.punsubscribe
    end
    
    it "should have role and be subscribed" do
      channel.role.should == :subscribe
      observer.counter.should == 0
      sleep 0.5
      expect { channel.publish( data: 'test' ) }.to change { sleep 0.05; observer.counter }.from(0).to(1)
    end
  end
  
  describe :psubscribe do
    after( :each ) { observer.clear }
    
    it "should notify observer on psubscribe" do
      # the_channel = "#{channel.to_s}.new"
      observer.counter.should == 0
      channel.count_observers.should == 1
      channel.psubscribe
      expect { channel.ppublish( channel: "new", data: 'test' ) }.to change { sleep 0.05; observer.counter }.from(0).to(1)
    end
  end
  
  describe :subscribe do
    after { observer.clear }
    
    it "should notify observer on subscribe" do
      observer.counter.should == 0
      channel.count_observers.should == 1
      channel.subscribe
      # binding.pry
      expect { channel.publish data: 'test' }.to change { sleep 0.05; observer.counter }.from(0).to(1)
    end
    
    it "should have proper observer calls" do
      channel.subscribe
      observer.counter.should == 0
      3.times do |it|
        expect { channel.publish data: it }.to change { sleep 0.05; observer.counter }.from( it ).to( it + 1 )
      end
    end
  end
end