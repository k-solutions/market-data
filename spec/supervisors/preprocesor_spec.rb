# -*- coding: utf-8 -*-
require_relative '../spec_helper'
require_relative '../../lib/supervisors/preprocessor'
require_relative '../../lib/supervisors/publisher'
init_channels

describe Supervisors::Preprocessor do
  let( :preprocessor ) do 
    Supervisors::Preprocessor.new unless Celluloid::Actor[ Supervisors::Preprocessor::PREPROCESSOR_KEY ]
    Celluloid::Actor[ Supervisors::Preprocessor::PREPROCESSOR_KEY ] 
  end
  let( :publisher )    do 
    Supervisors::Publisher.new unless Celluloid::Actor[ Supervisors::Publisher::PUBLISHER_KEY ]
    Celluloid::Actor[ Supervisors::Publisher::PUBLISHER_KEY ]
  end
  let( :channel )      { Channels::Redis.new id: 'preprocessor', role: :psubscribe }
  let( :observer )     { Observer.new channel }
 
  it "should be able to init" do
   lambda { Supervisors::Preprocessor.new }.should_not raise_error # ArgumentError
   Celluloid::Actor[ Supervisors::Preprocessor::PREPROCESSOR_KEY ].should_not be_nil
  end

  it "should procesee data" do
   preprocessor.should_not be_nil
   publisher.should_not be_nil
   expect { sleep 0.5 }.to change { observer.counter }
  end
end
