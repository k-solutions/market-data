# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/utility/random'

describe Utility::Random do
  let ( :market_code ) { "test" }
  let ( :worker ) { Utility::Random.new asset: market_code }

  it "should channel trough with market code" do
    worker.channel.should include market_code
  end

  it "should init with rand value" do
    worker.value.should_not == Utility::Random.new( asset: market_code ).value
  end

  it "should generate set value" do
    worker.generate.should == worker.value
  end

  it "should return timer on run" do
    worker.run.should be_a Timers::Timer # Timer
  end

  it "should run with random values" do
    old_value = worker.value
    worker.run
    worker.value.should == old_value
    sleep ( Utility::Random::PERIOD + 0.1 )
    worker.value.should_not == old_value
  end
end