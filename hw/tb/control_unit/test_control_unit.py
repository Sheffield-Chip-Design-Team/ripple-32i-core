import cocotb
from rv_instr_driver import RVInstructionDriver
from random import randint
from cocotb.triggers import Timer

@cocotb.test()
async def test_control_unit_combinational(uut):

  rv_driver = RVInstructionDriver(uut.instr)
  
  # set random input values
  await rv_driver.send_random(count=50)
  
  # TODO do some checking logic

  uut._log.info("Test Complete!")