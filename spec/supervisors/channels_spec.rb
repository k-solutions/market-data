# -*- coding: utf-8 -*-
require_relative '../spec_helper'
require_relative '../../lib/supervisors/channels'

describe Supervisors::Channels do
 it "should be able to init" do
   lambda { Supervisors::Channels.run! }.should_not raise_error # ArgumentError
   Celluloid::Actor[ Channels::REDIS_SUBSCRIBER ].should_not be_nil
   Celluloid::Actor[ Channels::REDIS_PUBLISHER ].should_not be_nil
 end
end
