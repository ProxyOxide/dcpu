require 'forwardable'
require_relative 'Dcpu'


class DcpuMonitor

  include DcpuConstants

  attr_accessor :dcpu
  attr_accessor :breakpoints
  extend Forwardable
  def_delegators :@dcpu, :cpu_step, :reg, :ram

  def initialize(dcpu=Dcpu.new)
    @dcpu = dcpu
    @breakpoints = []
  end

  def print_status
    print "PC:#{"0x%04x" % reg[PC]} "
    print "SP:#{"0x%04x" % reg[SP]} "
    print "O:#{"0x%04x" % reg[O]}\n"
    print "A:#{"0x%04x" % reg[A]} "
    print "B:#{"0x%04x" % reg[B]} "
    print "C:#{"0x%04x" % reg[C]} "
    print "X:#{"0x%04x" % reg[X]}\n"
    print "Y:#{"0x%04x" % reg[Y]} "
    print "Z:#{"0x%04x" % reg[Z]} "
    print "I:#{"0x%04x" % reg[I]} "
    print "J:#{"0x%04x" % reg[J]}\n"
  end

  def dump_mem(start, stop)
    segment = ram[start..stop]
    segment.each_index do |x|
      if (x % 8) == 0
        print "\n" unless x == 0
        print "0x%04x: " % (start + x)
      end
      print "%04x " % segment[x]
    end
    print "\n"
    return nil
  end

  def set_break(breakpoint)
    @breakpoints << breakpoint
  end

  def remove_break(breakpoint)
    @breakpoints.delete(breakpoint)
  end

  def clear_breaks
    @breakpoints = []
  end

  def run
    begin 
      cpu_step
    end until @breakpoints.include? reg[PC]
  end

end
