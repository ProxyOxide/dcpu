require_relative "MemOperand.rb"
require_relative "RegOperand.rb"
require_relative "LiteralOperand.rb"

module DcpuConstants
  #Constants for register numbers
  A, B, C, X, Y, Z, I, J, PC, SP, O = (0..10).to_a
end

class Dcpu

  include DcpuConstants

  #Accessors for ram and registers
  attr_accessor :ram
  attr_accessor :reg

  #Set initial state.
  def initialize
    @ram = Array.new(0x10000,0)
    @reg = Array.new(11,0)
    @reg[SP] = 0xFFFF
  end

  #Get the value of ram[PC] and increment PC by one
  def next_word
    result = @ram[@reg[PC]]
    @reg[PC] += 1
    return result
  end

  def opcode(inst)
    inst & 0xf
  end

  def a_val(inst)
    inst = inst >> 4
    inst & 0x3F
  end

  def b_val(inst)
    inst = inst >> 10
    inst & 0x3F
  end

  def skip_pc(val)
    skip_words = (0x10..0x17).to_a + [0x1E, 0x1F]
    @reg[PC] += 1 if skip_words.include?(val)
  end

  def skip_next_instr
    instruction = next_word
    op = opcode(instruction)
    if op == 0
      skip_pc(b_val(instruction))
    else
      skip_pc(a_val(instruction))
      skip_pc(b_val(instruction))
    end
  end

  #Parse an operand value and return an object representing
  #the location of the operand.
  def parse_operand(value)
    case value
    when 0x00..0x07 #register
      return RegOperand.new(self,value)
    when 0x08..0x0F #[register]
      return MemOperand.new(self,reg[value - 0x08])
    when 0x10..0x17 #[next word + register]
      return MemOperand.new(self,reg[value - 0x10] + next_word)
    when 0x18 #POP
      res = MemOperand.new(self,reg[SP])
      reg[SP] += 1
      return res
    when 0x19 #PEEK
      return MemOperand.new(self,reg[SP])
    when 0x1A #PUSH
      reg[SP] -= 1
      return MemOperand.new(self,reg[SP])
    when 0x1B #SP
      return RegOperand.new(self,SP)
    when 0x1C #PC
      return RegOperand.new(self,PC)
    when 0x1D #O
      return RegOperand.new(self,O)
    when 0x1E #[next word]
      return MemOperand.new(self,next_word)
    when 0x1F #next word
      return LiteralOperand.new(self, next_word)
    when 0x20..0x3F #literal value 0x00-0x1F
      return LiteralOperand.new(self, value-0x20)
    end
  end

  def standard_op(op,a,b)
    case op
    when 0x01
      set(a,b)
    when 0x02
      add(a,b)
    when 0x03
      sub(a,b)
    when 0x04
      mul(a,b)
    when 0x05
      div(a,b)
    when 0x06
      mod(a,b)
    when 0x07
      shl(a,b)
    when 0x08
      shr(a,b)
    when 0x09
      op_and(a,b)
    when 0x0A
      bor(a,b)
    when 0x0B
      xor(a,b)
    when 0x0C
      ife(a,b)
    when 0x0D
      ifn(a,b)
    when 0x0E
      ifg(a,b)
    when 0x0F
      ifb(a,b)
    end
  end

  def extended_op(eop,b)
    case eop
    when 0x01
      jsr(b)
    end
  end

  def cpu_step
    instruction = next_word
    op = opcode(instruction)
    if op == 0
      eop = a_val(instruction)
      b = parse_operand(b_val(instruction))
      extended_op(eop,b)
    else
      a = parse_operand(a_val(instruction))
      b = parse_operand(b_val(instruction))
      standard_op(op,a,b)
    end
  end

  def set(dest,src)
    dest.write(src.read)
  end

  def add(a,b)
    result = a.read + b.read
    a.write(result & 0xFFFF)
    reg[O] = 0x1 if result > 0xFFFF
  end

  def sub(a,b)
    result = a.read - b.read
    if result < 0
      reg[O] = 0xFFFF
      result = 0x10000 - result.abs
    end
    a.write(result)
  end

  def mul(a,b)
    result = (a.read * b.read)
    reg[O] = result >> 16 if result > 0xFFFF
    a.write(result & 0xFFFF)
  end

  def div(a,b)
    if b.read == 0
      a.write(0)
      reg[O] = 0
    else
      result = (a.read / b.read) & 0xFFFF
      reg[O] = ((a.read << 16) / b.read) & 0xFFFF
      a.write(result)
    end
  end

  def mod(a,b)
    if b.read == 0 then a.write(0)
    else a.write(a.read % b.read)
    end
  end

  def shl(a,b)
    result = (a.read << b.read) & 0xFFFF
    reg[O] = ((a.read << b.read) >> 16) & 0xFFFF
    a.write(result)
  end

  def shr(a,b)
    result = (a.read >> b.read) & 0xFFFF
    reg[O] = ((a.read << 16) >> b.read) & 0xFFFF
    a.write(result)
  end

  def op_and(a,b)
    a.write(a.read & b.read)
  end

  def bor(a,b)
    a.write(a.read | b.read)
  end

  def xor(a,b)
    a.write(a.read ^ b.read)
  end

  def ife(a,b)
    skip_next_instr() unless a.read == b.read
  end

  def ifn(a,b)
    skip_next_instr() unless a.read != b.read
  end

  def ifg(a,b)
    skip_next_instr() unless a.read > b.read
  end

  def ifb(a,b)
    skip_next_instr() unless (a.read & b.read) != 0
  end

  def jsr(b)
    @reg[SP] -= 1
    @ram[@reg[SP]] = @reg[PC]
    @reg[PC] = b.read
  end

end
