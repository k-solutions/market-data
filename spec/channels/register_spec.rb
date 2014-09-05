# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/channels/broadcaster'

describe Channels::Register do
  let( :channel )  { 'test1:test2' }
  let( :callback ) { lambda { channel } } 
  let( :register ) { Channels::Register.new }
  
  it "should respond to set" do
    expect { register.set channel, callback }.to_not raise_error
  end
  
  it "should respond to clear" do
    register.set channel, callback
    register.get( channel ).should_not be_empty
    expect { register.clear }.to_not raise_error
    register.get( channel ).should be_empty
  end
  
  it "should respond to get" do
    register.set channel, callback
    res = nil
    expect { res = register.get channel }.to_not raise_error
    res.should_not be_empty
    res.first.call.should == callback.call
  end
  
  it "should accumulate on set" do
    register.clear
    3.times { |it|  register.set channel, callback }
    res = register.get channel
    res.size.should == 3
  end
  
  it "should unset callback" do
    register.clear
    3.times { |it|  register.set channel, callback }
    register.get( channel ).size.should == 3
    register.unset channel, callback
    register.get( channel ).size == 2
  end
  
  describe :regexp do
    let( :regexp ) { Regexp.new "#{Regexp.escape("#{channel}\:")}\\w" }
    
    it "should be able to set with regexp" do
      expect { register.set regexp, callback }.to_not raise_error
    end
    
    it "should be able to get" do
      register.set regexp, callback
      res = nil
      expect { res = register.get "#{channel}:test" }.to_not raise_error
      res.should_not be_empty
      res.first.call.should == callback.call
    end
  end
end