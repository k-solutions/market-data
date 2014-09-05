class Observer
  attr_reader :counter, :channel, :value
  
  def initialize target
    @counter = 0
    target.add_observer( self )
  end
  
  def update( channel, value )
    @counter += 1 # @channel, @value = channel, value
  end
end