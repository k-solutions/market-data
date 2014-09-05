# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/channels/channel'

describe Channels::Factory do
  let( :options ) { { id: 'test.test1'  } }
  
  it "should respond to create" do
    expect { Channels::Factory.create options }.to_not raise_error
  end
  
  it "should have proper class" do
    Channels::Factory.create( options ).should be_a Channels::Redis
  end
  
  describe :group do
    let( :options ) { { channel_label: :subscriber, role: :publisher } }
    
    it "should respond to group" do
      expect { Channels::Factory.group options }.to_not raise_error
    end
    
    it "should have proper class" do
      Channels::Factory.group( options ).should be_a Channels::Group
    end
  end
end