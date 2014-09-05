# -*- coding: utf-8 -*
require 'spec_helper'
require_relative '../../lib/init'
require_relative '../../lib/utility/timed_hashes'

describe Utility::TimedHashes do
  HASH_INIT = lambda { |hash, key| hash[key] = 0 }
  INTERVALS = [ 1, 10 ]
  KEYS      = [ :test1, :test2 ]
                
  let( :default_options ) { { hash_options: { keys: KEYS } } }
  let( :options )         { default_options.rmerge( time_intervals: INTERVALS, hash_options: { default_proc: HASH_INIT } ) }

  it "should init with no options" do
    lambda {  Utility::TimedHashes.new }.should_not raise_error
  end
  
  it "should init with options" do
    lambda {  Utility::TimedHashes.new options }.should_not raise_error
  end

  context "new with default" do
    let( :timed_hashes ) { Utility::TimedHashes.new default_options }
    
    it "should be able to get default intervals element" do
      item = timed_hashes.get_last_item( key: :test1 )
      item.should be_empty
      expect{ item << 1 }.to change{ item.size }.from(0).to(1)
    end
    
    it "should respond to has_preset_keys?" do
      timed_hashes.has_preset_keys?.should be_true
    end
    
    it "should respond to has_key?" do
      timed_hashes.has_key?( key: :test1 ).should be_true 
      timed_hashes.has_key?( key: :test ).should be_false
    end
  end
  
  context :new do
    let( :timed_hashes ) { Utility::TimedHashes.new options }
    
    it "should have default interval" do
      lambda { timed_hashes.default }.should_not raise_error
    end
    
    it "should have timers and intervals" do
      timed_hashes.hashes.should_not be_empty
      timed_hashes.hashes.keys.should include *INTERVALS
      timed_hashes.current_times.should_not be_empty
    end
    
    it "should responds to get" do
      res = nil
      lambda { res = timed_hashes.get( key: :test1 ) }.should_not raise_error
      res.should_not be_nil
    end
    
    it "should be able to get default intervals element" do
      timed_hashes.get_last_item( key: :test1 ).should == 0
      expect{ timed_hashes.do_with_last( key: :test1 ) { |last| last += 1 } }.to change{ timed_hashes.get_last_item( key: :test1 ) }.from(0).to(1)
    end
  end
end
