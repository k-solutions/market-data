# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/stream/refinery'
init_shared

describe Stream::Refinery do
  let(:channels) do
    {:publish => PublishChannel.new("publish"),
     :data => SubscriptionChannel.new("data") }
  end
  subject { Stream::Refinery.new channels }

  describe "#initialize" do
    it "accepts a Refiner" do
      expect{
        Stream::Refinery.new(channels, double("Refiner"))
      }.to_not raise_error(ArgumentError)
    end
    it "requires a channel to recieve data from and to publish to" do
      refinery = nil
      expect{
        refinery = Stream::Refinery.new(
          {:publish => PublishChannel.new("publish2"),
           :data => SubscriptionChannel.new("data2")} )
      }.to_not raise_error(ArgumentError)
      expect(refinery.publish_channel).to be_a(Channel)
      expect(refinery.publish_channel.channel_id).to eq("publish2")
      expect(refinery.data_channel).to be_a(Channel)
      expect(refinery.data_channel.channel_id).to eq("data2")
    end
    it "creates a RankablesList" do
      expect(subject.rankables).to be_a(Stream::Rankables)
    end
    # the details of Channel and subscriptions must be shared
    # here we need to test the subscription
    it "accepts and subscribes to a Command channel" do
      refinery = nil
      expect{
        refinery = Stream::Refinery.new(
          channels.merge({:command => SubscriptionChannel.new("command")}) )
      }.to_not raise_error(ArgumentError)
      expect(refinery.command_channel).to be_a(Channel)
      expect(refinery.command_channel.channel_id).to eq("command")
    end
  end

  describe "#register_ranker" do
    it "stores the Ranker" do
      rankers = (1..5).map { |n| double("Ranker") }
      rankers.each { |ranker| subject.register_ranker ranker }
      expect(subject.rankers).to have(5).rankers
    end
  end

  describe "#set_channels" do
    it "sets all channels passed in" do
      channels =  {:publish => PublishChannel.new("publish2"),
                   :data    => SubscriptionChannel.new("data2"),
                   :command => SubscriptionChannel.new("command2")}
      subject.set_channels(channels)
      expect(subject.publish_channel).to be_a(Channel)
      expect(subject.publish_channel.channel_id).to eq("publish2")
      expect(subject.data_channel).to be_a(Channel)
      expect(subject.data_channel.channel_id).to eq("data2")
      expect(subject.command_channel).to be_a(Channel)
      expect(subject.command_channel.channel_id).to eq("command2")
    end
  end

  describe "#store" do
    it "creates and stores a Rankable" do
      expect{ subject.store( double("data") ) }.to_not raise_error ArgumentError
      expect( subject.rankables.first ).to be_a(Stream::Rankable)
    end
  end

  describe "#refine" do

    it "prunes the Rankables list" do
      subject.store(double("Rankable"))
      subject.store(double("Rankable", :delete? => true))
      expect(subject.rankables).to have(2).rankables
      expect { subject.refine }.to change{ subject.rankables.size }.from(2).to(1) # .rankable
    end

    let(:refiner) { double("Refiner", :refine => [double("Rankable")]) }
    subject { Stream::Refinery.new(channels, refiner) }

    it "calls its Refiner#refine with stored rankables" do
      refiner.should_receive(:refine).with(subject.rankables)
      subject.refine
    end

    it "publishes to publish channel" do
      subject.should_receive(:publish)
      subject.refine
    end
  end

  describe "#command" do
    context "Rank" do
      it "calls rank" do

      end
    end
  end
end