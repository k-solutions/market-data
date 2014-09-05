# -*- coding: utf-8 -*-
require_relative '../spec_helper'
require_relative '../../lib/supervisors/stat'
init_channels

describe Supervisors::Stat do
 it "should be able to init" do
   lambda { Supervisors::Stat.new }.should_not raise_error # ArgumentError
   Celluloid::Actor[ :stat ].should_not be_nil
 end
end
