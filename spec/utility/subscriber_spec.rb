# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/stream/subscriber'

init_shared # set shared examples

describe Stat::Subscriber do
  include_examples "subscriber history", Stat::Subscriber
end