class MemOperand

  def initialize(dcpu, address)
    @cpu = dcpu
    @address = address
  end

  def read
    @cpu.ram[@address]
  end

  def write(val)
    @cpu.ram[@address] = val
  end

end
