# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/markets/market_storage'

describe Markets::MarketStorage do
  let( :markets ) { create_markets }
  let ( :the_storage ) do
    Markets::MarketStorage.instance.clean

    Markets::MarketStorage.instance # Markets::MARKET_STORAGE
  end

  it "should be able to add" do
    the_storage.add( *markets ).should include *markets.map( &:code )
  end

  describe "storage" do
    before { the_storage.add( *markets )  }

    it "should be able to get" do
      the_code = markets.last.code

      market_struct = the_storage.get( the_code )
      market_struct.should be_a Markets::MarketStruct
      # market_struct.utc_open_time.should == markets.last.regular_open_time.in_time_zone(markets.last.timezone).utc.strftime("%T")
      market_struct.tag_list.should include *markets.last.tag_list
    end

    it "should be able to delete" do
      the_storage.delete( *markets ).should be_empty # _not include *markets.map { |m| m.code }

      the_storage.keys.should be_empty
    end

    it "should be able to reset" do
      the_market = markets.first
      the_market.regular_open_time  = ( Time.now - (10*3600) ) 
      the_market.regular_close_time = ( Time.now - (30*60) )
      the_market.precision          = 5
      lambda { the_storage.reset( the_market ) }.should_not raise_error

      the_storage.get( the_market.code ).precision.should == 5
    end
  end
end
