# -*- coding: utf-8 -*-

require_relative '../spec_helper'
require_relative '../../lib/channels/channel'
init_market_storage 
init_channels
require_relative '../../lib/markets/preprocessor' # daemons do not follow Rails autoloader rules

# NOTE: make sure you warmup your market cache by exec rake app:cache:warmup
describe Markets::PreProcessor do
   CONFIG_FILE         = 'config/channels.yml'
   PUBLISHING_OPTIONS  = Utility::Parser.get( CONFIG_FILE, :preprocessor )[ :publisher  ]
   LISTENING_OPTIONS   = Utility::Parser.get( CONFIG_FILE, :preprocessor )[ :subscriber ]
#   PUBLISHING_CHANNELS = Channels::Group.new *PUBLISHING_OPTIONS
#   LISTENING_CHANNELS  = Channels::Group.new *LISTENING_OPTIONS
  
  let( :pub_channel )           { Channels::Factory.create LISTENING_OPTIONS.last.update( role: :none, format_method: :join ) }
  let( :sub_channel )           { Channels::Factory.create PUBLISHING_OPTIONS.first.update( role: :psubscribe ) }
  let( :observer )              { Observer.new sub_channel }
  
  let( :init_options )          { { listening_channels:  ::Channels::Factory.group( channel_label: :preprocessor, role: :subscriber ), 
                                    publishing_channels: ::Channels::Factory.group( channel_label: :preprocessor, role: :publisher ) } }
  let( :pre_proc )              { Markets::PreProcessor.new( init_options ) }
  let( :inverted_keys )         { pre_proc.subscriptions.invert }
  let( :all_keys )              { inverted_keys.keys }
  let( :market_code_for_avg )   { Markets::PreProcessor::ASSETS_EXPECT_BIDASK.to_a.detect { |mc| all_keys.include?( mc ) } }
  let( :market_key )            { inverted_keys[ market_code_for_avg ] }
  
  let( :post_msg_with_avg )     { Stream::Msg.new [ market_code_for_avg, 'test', Time.now.utc.to_f, 1.2345, 1.2354, 1.2365 ] }
  let( :post_msg_without_avg )  { Stream::Msg.new [ market_code_for_avg, 'test', Time.now.utc.to_f, -1.2345, 1.2354, -1.6532 ] }
  let( :msg_with_avg )          { Stream::Msg.new [ market_key , 'test', Time.now.utc.to_f, 1.2345, 1.2354, 1.2365 ] }
  let( :msg_without_avg )       { Stream::Msg.new [ market_key , 'test', Time.now.utc.to_f, -1.2345, 1.2354, -1.6523 ] }  
  
  it "should load options" do
    pre_proc.listening_channels.should_not be_empty
    pre_proc.publishing_channels.should_not be_empty
    pre_proc.subscriptions.should_not be_empty
  end

  it "should have markets map" do
    Markets::PreProcessor::THE_MARKETS.size.should > 2
    (assets = Markets::PreProcessor::ASSETS_EXPECT_BIDASK).should_not be_empty
    # pre_proc.subscriptions.should_not be_empty
    subscriptions_set = pre_proc.subscriptions.values.to_set
    ( subscriptions_set - assets ).should_not be_nil
    ( subscriptions_set & assets ).should_not be_nil
  end
  
  it "should have market code with avg" do
    market_code_for_avg.should_not be_nil
    Markets::PreProcessor::ASSETS_EXPECT_BIDASK.should include market_code_for_avg
  end
  
  it "should have market key with avg" do
    market_key.should_not be_nil
    pre_proc.subscriptions.should include market_key
  end
  
  it "should return avg" do
   pre_proc.avg_value( post_msg_with_avg ).should_not == "-1" # }.should_not raise_error
  end
  
  it "should not return avg" do
   pre_proc.avg_value( post_msg_without_avg ).should == "-1" # }.should_not raise_error
  end
  
  it "should have avg in processed message" do
    pre_proc.post_process( msg_with_avg ).should_not include "-1" # }.should_not raise_error
  end

  it "should not have avg in processed message" do
   pre_proc.post_process( msg_without_avg ).should include "-1" # }.should_not raise_error
  end
  
  describe :observed do
    it "should count on publish" do
      pre_proc.should_not    be_nil
      observer.should_not    be_nil
      pub_channel.should_not be_nil
      # expect { pub_channel.ppublish channel: all_keys.first, data: msg_with_avg.to_a }.to change { sleep 0.7; observer.counter }
    end
  end
end
