# -*- coding: utf-8 -*
require 'spec_helper'
require_relative '../../lib/utility/sized_hash'
init_shared

describe Utility::SizedHash do
  HASH_INIT = lambda { |hash, key| hash[key] = 0 }

  it "should init without error" do
    lambda {  Utility::SizedHash.new }.should_not raise_error
  end

  it "should init with block" do
    res = nil
    lambda { res = Utility::SizedHash.new( 10, HASH_INIT ) }.should_not raise_error
    res[:test].should == 0
  end

  describe :new_sized do
    include_examples "SizedHash", Utility::SizedHash
  end
  
  context :timed do # NOTE: all this functionality may belong in a subclass
    def set_stats
      the_time = cur_time - 4
      5.times.each { |it| timed_hash[ the_time + it ] = rand }
    end
    
    let( :cur_time ) { Time.now.utc.to_i }
    let( :timed_hash ) do 
      res = Utility::SizedHash.new 3, HASH_INIT
      res.current_time = cur_time
      
      res
    end
    
    it "should respond to last" do
      timed_hash.last.should == 0
    end 
    
    it "should respond to get" do
      set_stats
      timed_hash.get.should_not be_empty
    end
    
    it "should be able to set current_time" do
      res, the_cur_time = nil, cur_time
      lambda { res = ( timed_hash.current_time = the_cur_time ) }.should_not raise_error
      timed_hash.last.should == timed_hash[ the_cur_time ]
    end
    
    it "should be callable with range" do
      res, the_time = nil, cur_time
      set_stats
      
      timed_hash.hash.keys.should include the_time
      timed_hash.last.should_not == 0
      
      lambda { res = timed_hash.get( range: (the_time - 1)..the_time ) }.should_not raise_error # ArgumentError
      
      res.should be_a Array
      res.size.should == 2
    end
    
    it "should be callable with start and length" do
      res, the_time = nil, cur_time 
      set_stats
      
      lambda { res = timed_hash.get( start: (the_time - 1), length: 2 ) }.should_not raise_error ArgumentError
      res.should be_a Array
      res.size.should == 2
    end
    
    it "should be callable with end and length" do
      res, the_time = nil, cur_time 
      set_stats
      lambda { res = timed_hash.get( end: the_time , length: 2 ) }.should_not raise_error ArgumentError
      res.should be_a Array
      res.size.should == 2
    end
  end
end
