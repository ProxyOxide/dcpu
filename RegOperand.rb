class RegOperand

  def initialize(dcpu, reg_num)
    @cpu = dcpu
    @reg_num = reg_num
  end

  def read
    @cpu.reg[@reg_num]
  end

  def write(val)
    @cpu.reg[@reg_num] = val
  end

end
