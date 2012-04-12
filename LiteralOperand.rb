class LiteralOperand
  def initialize(dcpu, value)
    @cpu = dcpu
    @value = value
  end

  def read
    @value
  end

  def write
    puts "WARN: Tried to write to a literal operand"
  end

end
