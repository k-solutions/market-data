# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/stream/tick'

describe Stream::Msg do
  let( :array_msg )    { ['I:DJI', 'test', Time.now.utc.to_f, 1.2345, 1.2354, 1.2365 ]}
  let( :string_msg ) { array_msg.join( Stream::Msg::SPLIT_FORMAT ) } 
  
  it "should not init with no msg" do
    lambda { Stream::Msg.new }.should raise_error 
  end
  
  it "should not init with bad msg" do
    _ = array_msg.shift 
    lambda { Stream::Msg.new array_msg }.should raise_error 
    lambda { Stream::Msg.new array_msg.join( Stream::Msg::SPLIT_FORMAT ) }.should raise_error 
  end
  
  it "should be able to init with string" do
    res = nil
    lambda { res = Stream::Msg.new string_msg }.should_not raise_error
    res.to_s.should == string_msg
  end

  it "should be able to init with array" do
    res = nil
    lambda { res = Stream::Msg.new array_msg }.should_not raise_error
    res.to_s.should == string_msg
  end
  
  it "should have read/write acces to all message atributes" do
    res = Stream::Msg.new array_msg
    res.market_code.should_not be_nil
    lambda { res.market_code = "test1" }.should_not raise_error
  end
end