# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/utility/redis'

describe Utility::Redis do
 it "should require config file" do
   lambda { Utility::Redis.get }.should_not raise_error ArgumentError
 end
 
 it "should parse a key part from YML file" do
  res = {}
  lambda { res = Utility::Redis.get( :hiredis ) }.should_not raise_error
  
  res.should_not be_empty
 end
end
