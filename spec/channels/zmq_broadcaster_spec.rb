# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/channels/broadcaster'

describe Channels::ZmqBroadcaster do
  class Counter
    @@counter = 0
    class << self
      def clear
       @@counter = 0 
      end
      
      def counter
        @@counter
      end
      
      def add
        @@counter += 1
      end
    end
  end
  
  before { Counter.clear }
  let( :base )        { 'test1:test2' }
  let( :channel )     { "#{base}:test" }
  let( :callback )    { lambda { |channel, value| Counter.add } } 
  let( :regexp  )     { Regexp.new "#{Regexp.escape("#{base}\:")}\\w" }
  let( :broadcaster ) { Channels::ZmqBroadcaster.new }
  let( :register )    { broadcaster.register }
  let( :pregister )   { broadcaster.pattern_register }
  # after { broadcaster.remove channel, callback }
  
  it "should respond to publish" do
    expect { broadcaster.publish channel, 'test' }.to_not raise_error
  end 
  
  it "should respond to subscribe" do
    expect { broadcaster.subscribe channel, :_broadcast }.to_not raise_error
  end
  
  it "should respond to listen" do
    expect { broadcaster.listen channel, callback }.to_not raise_error
    expect { broadcaster._broadcast channel, 'test' }.to change { broadcaster.callbacks.size }.from( 0 ).to( 1 )
    broadcaster.callbacks.should include callback
  end
  
  it "should respond to plisten" do 
    expect { broadcaster.plisten regexp, callback }.to_not raise_error
    expect { broadcaster._pbroadcast channel, 'test' }.to change { broadcaster.callbacks.size }.from( 0 ).to( 1 )
    broadcaster.callbacks.should include callback
  end
  
  it "should be able to remove on listen" do
    broadcaster.listen channel, callback
    register.get( channel ).size.should == 1
    expect { broadcaster.remove channel, callback }.to_not raise_error
    register.get( channel ).size.should == 0
  end
  
  it "should be able to remove on plisten" do
    broadcaster.plisten regexp, callback
    pregister.get( channel ).size.should == 1
    expect { broadcaster.premove regexp, callback }.to_not raise_error
    pregister.get( channel ).size.should == 0
  end 
  
  it "should be able to transfer with listen" do
    broadcaster.listen channel, callback
    the_counter = Counter.counter 
    the_counter.should == 0
    expect { broadcaster.publish channel, 'test' }.to change { Counter.counter } #.from( the_counter ).to( the_counter + 1 )
  end
  
  it "should be able to transfer with plisten" do
    broadcaster.plisten regexp, callback
    the_counter = Counter.counter 
    the_counter.should == 0
    expect { broadcaster.publish channel, 'test' }.to change { Counter.counter } #.from( the_counter ).to( the_counter + 1 )
 end
end
