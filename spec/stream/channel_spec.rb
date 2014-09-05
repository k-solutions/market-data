# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/stream/channel'

describe Stream::Channel do
  let(:channel) { Stream::Channel.new id: 'test1.test2' }

  it "should init" do
    lambda { channel }.should_not raise_error
  end
  
  it "should have role" do
    channel.role.should_not be_nil
    channel.role.should == Stream::Channel::ROLES.first
  end
  
  it "should have items" do
    channel.items.should_not be_nil
    channel.items.should_not be_empty
  end
  
  it "should respond to parse" do
    channel.parse.should_not be_empty
    channel.parse( 'test.new_test' ).should include 'test', 'new_test'
    channel.parse( 'test:new_test', :zmq ).should include 'test', 'new_test'
  end
  
  it "should respond to to_s" do
    channel.to_s.should include 'test1', 'test2', '.'
  end
  
  it "should respond to to_reg" do
    channel.to_reg.should include 'test1', 'test2'
    channel.type.should == :redis
    channel.to_reg.should == 'test1.test2.*'
  end
  
  describe :role do
    let( :channel ) { Stream::Channel.new id: 'test1:test2', role: :retranslator }
    
    it "should respond to publish" do
      channel.role.should == :retranslator
      expect { channel.publish }.to_not raise_error
    end
  end
  
  describe :ZMQ do
    let(:channel) { Stream::Channel.new id: 'test1:test2', type: :zmq }
    let( :channel_reg_exp ) { channel.to_reg }
    
    it "should have type :zmq" do
      channel.type.should == :zmq
    end
    
    it "should respond to to_s" do
      Stream::Channel::SEPARATORS.keys.should include :redis, :zmq
      channel.to_s.should include 'test1', 'test2', ':'
    end 
    
    it "should respond to to_reg" do
      "test1:test2:DJIA".should match channel_reg_exp # 'test1.test2.*'
      "test3:test2:DJIA".should_not match channel_reg_exp # 'test1.test2.*'
      "test1:test2:DJ".should_not match channel_reg_exp # 'test1.test2.*'
    end
    
    describe :role do
      let( :channel ) { Stream::Channel.new id: 'test1:test2', role: :retranslator }
      
      it "should respond to publish" do
        channel.role.should == :retranslator
        expect { channel.publish }.to_not raise_error
      end
    end
  end
end