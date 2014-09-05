# -*- coding: utf-8 -*-
require_relative '../spec_helper'
require_relative '../../lib/supervisors/publisher'
init_channels

describe Supervisors::Publisher do
 let( :publisher ) do 
   Supervisors::Publisher.new unless Celluloid::Actor[ Supervisors::Publisher::PUBLISHER_KEY ]
   Celluloid::Actor[ Supervisors::Publisher::PUBLISHER_KEY ] 
 end
 let( :channel )   { Channels::Zmq.new id: 'zmq:internal', role: :psubscribe }
 let( :observer )  { Observer.new channel }
 
 it "should be able to init" do
   lambda { publisher }.should_not raise_error # ArgumentError
   publisher.should_not be_nil
   publisher.valid_codes.should_not be_empty
   publisher.valid_codes.each { |asset| Celluloid::Actor[ Supervisors::Publisher::WORKER_SYMBOL.call( asset ) ].should_not be_nil }
 end
 
 it "should publish random" do
   publisher.should_not be_nil
   observer.counter.should == 0
   expect { sleep 0.7 }.to change { observer.counter }
 end
end
