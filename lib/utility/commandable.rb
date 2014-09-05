module Commandable

  def has_command?(command)
    raise ArgumentError, "Commandable#has_command?: no commands have been set yet" unless @accepted_commands
    @accepted_commands.member?(command)
  end

  def command(c)
    raise ArgumentError, "Commandable#command: cannot respond to #{c}" unless has_command?(c)
    send c
  end

  protected
  def accepts_commands(*commands)
    raise ArgumentError, "commands can only be symbols" unless commands.all? { |c| c.is_a?(Symbol) }
    commands.each do |c|
      raise ArgumentError, "command #{c} must have associated public method" unless respond_to?(c) # pass true ass 2nd param to allow private
      # TODO: raise ArgumentError, "commands cannot take any arguments" if ???
    end
    @accepted_commands = commands
  end

end