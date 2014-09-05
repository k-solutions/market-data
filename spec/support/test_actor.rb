require 'celluloid/autostart'

class TestActor
  include Celluloid
  include Celluloid::Notifications
  
  attr_reader :counter
  def initialize
    @counter ||= 0
    current_actor.subscribe Channels::DEFAULT_MSG_CHANNEL, :broadcast
  end
  
  def broadcast channel, msg
    @counter += 1 #; puts "Message: #{msg} sent on channnel: #{channel}"
  end
end