# -*- coding: utf-8 -*-
require_relative '../spec_helper'
require_relative '../../lib/markets/publisher'
require_relative '../../lib/utility/random'
init_channels

describe Markets::Publisher do
  CHANNEL             = 'zmq:internal'
  OPTIONS             = ::Utility::Parser.get( ::Markets::Publisher::CONFIG_FILE, ::Markets::Publisher::RAILS_ENV, true )[ 'subscriptions' ]

  let( :init_options ) { { listening_channels:  ::Channels::Factory.group( channel_label: :publisher, role: :subscriber ), 
                           publishing_channels: ::Channels::Factory.group( channel_label: :publisher, role: :publisher ) } }
  let( :markets ) { OPTIONS.keys[0..2].inject( [] ) { |res, code| res << double("market", :code => "DJIA", :precision => 2, :to_s => "DJIA" ) } } # MS.get( code ) 
  let( :worker ) do # Channels::BROADCASTER
    res = Utility::Random.new( asset: markets.first.code )
    res.async.run 
    res
  end
  let ( :publisher )  { Markets::Publisher.new init_options }
  let ( :subscriber ) { publisher.listening_channels.first }
  
  it "should have subscriptions" do
    publisher.subscriptions.should_not be_empty
    ( markets.map( &:code ) - publisher.subscriptions.keys ).should be_empty
    res = nil
    lambda { res = publisher.msg_data.call( markets.first.code, 1.2234 ) }.should_not raise_error
    res.should be_kind_of Array
    res.size.should == 6
  end
  
  it "should be able to process" do
   res = nil
   lambda { res = publisher.process( markets.first.code, 1.2345 ) }.should_not raise_error
   res.should_not be_nil
  end
  
  it "should broadcast" do
    publisher.counter.should == 0
    val = rand
    res = publisher.update( "DJIA", val )
    res.should include "DJIA" # , val ]
    res[1].should include val
    publisher.counter.should == 1 # ).from(0).to(1)
  end
  
  it "should update counter with worker" do
    publisher.counter.should == 0
    worker.should_not be_nil
    old_val = worker.value
    expect { sleep 0.7 }.to change { sleep 0.1; publisher.counter }
    worker.value.should_not == old_val
  end
end