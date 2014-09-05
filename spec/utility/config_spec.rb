# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/utility/config'

describe Utility::Config do
 it "should require config file" do
  lambda { Utility::Config.get }.should raise_error ArgumentError
 end
 
 it "should require readable config file" do
  lambda { Utility::Config.get '/config/dummy.yml' }.should raise_error # ArgumentError
 end
 
 it "should return readable file" do
   res = Utility::Config.get '/config/redis.yml'
   File.readable?(res).should be_true
 end
end
