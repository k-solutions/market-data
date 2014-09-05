# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/stream/refinery'
init_shared

class RankableDouble
  include Utility::Rankable
end

# tests that the interface hasn't changed
describe RankableDouble, :rankable do
  it_behaves_like "rankable data"
end


describe Stream::Refiner do

  let(:refiner) { Stream::Refiner.new }

  describe "#initialize" do
    it "may accept a threshold" do
      refiner = Stream::Refiner.new(:threshold => 1)
      expect(refiner.threshold).to eq(1)
    end
  end

  it "has a threshold" do
    expect(refiner.threshold).to be
  end

  describe "#refine" do
    subject { Stream::Refiner.new(:threshold => 2) }
    it "returns all Rankables with total_rank above the threshold" do
      rankables = (0..5).map { |n|
        double("Rankable", :total_rank => n)
      }
      output = subject.refine(rankables)
      expect(output).to have(4).items # above threshold: 2, 3, 4, 5
    end
  end
end

describe Stream::TickRefiner do
  describe "#refine" do
    let(:tick_refiner) { Stream::TickRefiner.new(:threshold => 2) }
    let(:rankables) do
       (0..5).map { |n|
        double("RankableTick", :total_rank => n, :value => n)
      }
    end
    subject { tick_refiner.refine(rankables) }
    it "returns all ticks with total_rank above the threshold and aggregate ticks" do
      expect(subject).to have(5).ticks # values: 2, 3, 4, 5, plus aggregate (3.5)
      aggregate_value = (rankables.reduce(0) { |sum, r| sum + r.value}).to_f / rankables.size.to_f
      aggregate_tick = subject.find { |t|  t.value == aggregate_value }
      expect(aggregate_tick.value).to eq(aggregate_value)
    end
  end
end