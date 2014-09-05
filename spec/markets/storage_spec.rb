# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/markets/storage'

describe Markets::Storage do
    Stored = Struct.new( :code, :precision )

    let( :store ) do
      res = Markets::Storage.new :test
      res.clean

      res
    end

    it "should be able to dump" do
      obj = Stored.new( :test, 2 )
      res = Marshal.dump( obj ) # .to_json
      res.should_not be_empty
      res.should be_a String
      # JSON.parse( res ).should == obj
      Marshal.load( res ).should == obj
    end

    it "should be clean" do
      store.keys.should be_empty
    end

    it "should be able to add" do
      keys = []
      lambda { keys = store.add [ :key1, Stored.new( :test1, 2 ) ], [ :key2, Stored.new( :test2, 3 ) ] }.should_not raise_error
      keys.should include 'key1', 'key2' #  ]
    end

    describe "preset" do
      let( :stored ) { Stored.new( :test2, 3 ) }
      before { store.add :key1, stored }

      it "should not reset value with add" do
        store.get( 'key1' ).should_not be_nil
        new_stored = Stored.new( :test3, 3 )
        store.add( :key1, new_stored ).should include 'key1'
        res = store.get( 'key1' )
        res.should_not == new_stored
        res.should == stored
      end

      it "should be able to get" do
        store.get( :key1 ).should == stored # Stored.new( :test1, 2 )
      end

      it "should be able to delete" do
        store.delete( :key1 ).should_not include 'key1'
      end

      it "should be able to reset" do
        stored = Stored.new( :test2, 3 )
        store.reset [ 'key1', stored ]
        store.get( 'key1' ).should == stored
      end
    end
end
