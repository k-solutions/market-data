# -*- coding: utf-8 -*-
require_relative 'spec_helper'
require_relative '../lib/options'

describe Options::Daemons do
 it "should get properly" do
   res = nil
   lambda { res = Options::Daemons.get }.should_not raise_error 
   
   res.should be_a Hash
   res.should_not be_empty
 end
end
