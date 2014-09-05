require_relative '../../lib/channels/channel'
require_relative '../../lib/stream/subscriber'
require_relative '../../lib/utility/config'
require_relative '../../lib/utility/timed_hashes'

shared_examples_for "subscriber history" do |the_class|

  TIMED_HASHES        = Utility::Factory.timed_hashes assets: [ 'test' ]
  LISTENNING_CHANNELS = Channels::Factory.group( channel_label: :subscriber )
  
  let( :subscriber ) { the_class.new listening_channels: LISTENNING_CHANNELS, history: TIMED_HASHES }
  let( :message )    { return "test", rand }
  
  it "should init" do
    lambda { subscriber }.should_not raise_error
    subscriber.history.should_not be_nil
  end
  
  it "should set history" do
    channel, value = message # "#{subscriber.channels}.test", rand
    subscriber.update( channel, value ).should == [ "test", value ]
    subscriber.history.get_last_item( key: "test" ).should_not be_empty
  end
  
  it "should not set history on out of channels message" do 
    channel, value = message # "#{channeled_subscriber.channels.first.to_s}.test1", rand
    subscriber.update( channel << "1", value ).should == [ nil, nil ]
  end
end