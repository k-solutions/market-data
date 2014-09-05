# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/stream/stat'
require_relative '../../lib/utility/config'
require_relative '../../lib/channels/channel'
init_channels

# NOTE: this is interface for subcriptions actors
describe Stream::Stat do
  STAT_TIMED_HASHES  = Utility::Factory.timed_hashes type: :stat, assets: [ 'test' ]
  LISTENING_CHANNELS = Channels::Factory.group channel_label: :subscriber
      
  let ( :market_code ) { 'test' }
  let ( :stat )   { Stream::Stat.new listening_channels: LISTENING_CHANNELS, history: STAT_TIMED_HASHES }
  
  it "should init" do
    lambda { stat }.should_not raise_error
    stat.channels.should == LISTENING_CHANNELS # OPTIONS[ :int ][ :channel ]
    stat.get_item( key: market_code ).should_not be_empty
  end
  
  context "do broadcast" do
    let( :current_time ) { Time.now.utc.to_i }
    def set_stats size = MAX_SIZE
      cur_time, the_stat = current_time, stat.get_item( key: market_code ) #  market.code ]
      the_stat.current_time = cur_time
      size.times.each { |it| the_stat[cur_time-it] += 1 }
      
      cur_time
    end
    
    it "should have stat" do
      value = rand
      stat.update( market_code, value ) 
      stat.get_last_item( key: market_code ).should_not == 0
    end
    
    it "should add seconds stat" do
      the_size = stat.get( key: market_code ).size # should have( 1 ).item
      how_long = 3
      set_stats how_long
      seconds_stat = stat.get( key: market_code ) # stat[ market.code ]
      seconds_stat.should have_at_least( how_long ).items
      seconds_stat.delete_if { |v| v == 0 }.should have_at_least( how_long ).items
    end
    
    it "should respond to get_item with Array" do
      res = nil
      lambda { res = stat.get( key: market_code ) }.should_not raise_error 
      res.should be_a Array
    end
    
    it "should raise on no :market option to get" do
      stat.get( key: market_code.to_sym ).should be_empty 
    end
    
    it "should respond to collect" do
      lambda { stat.collect }.should_not raise_error
    end
    
    it "should collect minutes stats" do
      stat.get( interval: 60, key: market_code ).should have( 1 ).item # be_empty
      set_stats 10
      stat.collect
      sec_stat, min_stat = stat.get( key: market_code ), stat.get( key: market_code, interval: 60 )
      
      min_stat.should_not be_empty
      min_stat.first.should == Stream::Stat::SUM_PROC.call( sec_stat )
    end
  end
end