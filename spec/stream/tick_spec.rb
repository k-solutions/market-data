# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/stream/tick'
init_shared

describe Stream::Tick, :rankable do
  let(:market_value) { 1000.0 }

  it_behaves_like "rankable data" do
    let(:rankable) { Stream::Tick.new(1000.0) }
  end
end