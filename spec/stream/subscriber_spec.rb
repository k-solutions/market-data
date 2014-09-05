# -*- coding: utf-8 -*-
require 'spec_helper'
require_relative '../../lib/stream/subscriber'
init_channels
init_shared # set shared examples

describe Stream::Subscriber do
  include_examples "subscriber history", Stream::Subscriber
end