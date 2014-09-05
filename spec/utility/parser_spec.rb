# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/utility/config'

describe Utility::Parser do
 let( :config_file ) {  Utility::Config.get '/config/redis.yml' }

 it "should require config file" do
  lambda { Utility::Parser.get }.should raise_error ArgumentError
 end
 
 it "should require readable config file" do
  lambda { Utility::Parser.get '../config/dummy.yml' }.should raise_error # ArgumentError
 end
 
 it "should parse YML file" do
  res = {}
  lambda { res = Utility::Parser.get config_file }.should_not raise_error
  
  res.should_not be_empty
 end
 
 it "should parse a key part from YML file" do
  res = {}
  lambda { res = Utility::Parser.get( config_file, 'test' ) }.should_not raise_error
  
  res.should_not be_empty
 end
 
 it "should parse a key part from YML file and merge" do
  res = {}
  lambda { res = Utility::Parser.get( config_file, 'test', true ) }.should_not raise_error
  
  res.should_not be_empty
 end
end
