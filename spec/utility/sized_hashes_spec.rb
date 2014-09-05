# -*- coding: utf-8 -*
require_relative '../spec_helper'
require_relative '../../lib/utility/sized_hash'

describe Utility::SizedHashes do
  HASH_INIT = lambda { |hash, key| hash[key] = 0 }
  let( :options )    { { keys: [ :test1, :test2 ], default_proc: HASH_INIT } }

  it "should init" do
    lambda {  Utility::SizedHashes.new options }.should_not raise_error
  end
  
  it "should respond to has_preset_keys?" do
    lambda { Utility::SizedHashes.new( options.update( keys: [] ) ).has_preset_keys? }.should_not raise_error
  end

  context :new do
    let( :sized_hashes ) { Utility::SizedHashes.new options }
    
    it "should respond to has_channels?" do
      lambda {  }
    end
    
    it "should have keys" do
      sized_hashes.keys.should include *options[:keys]
      sized_hashes[ :test ].should be_nil
      sized_hashes[ :test1 ].should be_a Utility::SizedHash
      sized_hashes[ :test1 ][ :test ].should == 0
    end
    
    it "should set current time" do
      the_cur_time = Time.now.utc.to_i
      lambda { sized_hashes.current_time = the_cur_time }.should_not raise_error
      sized_hashes.each { |key, val| val.last.should == val[ the_cur_time ] }
    end
    
    it "should respond to get" do
      res = nil
      lambda { res = sized_hashes.get }.should_not raise_error
      res.should_not be_nil
    end
  end
end
