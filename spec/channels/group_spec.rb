# -*- coding: utf-8 -*-
require 'pry'
require 'spec_helper'
require_relative '../../lib/channels/channel'

describe Channels::Group do
  let( :options )       { { id: 'test.test1' } }
  let( :zmq_options  )  { { id: 'test:test1', type: :zmq } }
  let( :args )          { [ options, zmq_options ]  }
  let( :group )         { Channels::Group.new *args }
  
  it "should respond to create with Channel" do
    expect { group }.to_not raise_error
  end
  
  it "should have proper size" do
    channels = group.channels
    expect( group.channels ).to have(2 ).items
  end
end