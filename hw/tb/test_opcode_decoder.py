import cocotb
from random import randint
from cocotb.triggers import Timer

@cocotb.test()
async def test_opcode_decoder_combinational(uut):

  opcode_dict = {
    0b0110011: "isALUreg",
    0b0010011: "isALUimm",
    0b1100111: "isJALR",
    0b0000011: "isLoad",
    0b0100011: "isStore",
    0b1100011: "isBranch",
    0b0010111: "isAUIPC",
    0b0110111: "isLUI",
    0b1101111: "isJAL", 
    0b1110011: "isSYSTEM"
  }

  tests_passed = 0
  for i in range(64):
    uut.opcode.value = i
    uut._log.info(f"Setting opcode to {uut.opcode.value}")

    if int(uut.opcode.value) in opcode_dict:
      assert uut.outputs.value == (1 << (9 - list(opcode_dict.keys()).index(int(uut.opcode.value)))), f"Test FAILED! Expected {opcode_dict[int(uut.opcode.value)]} to be 1 but got outputs: {uut.outputs.value}"
    await Timer(randint(1,10), unit="ns")
    tests_passed = i+1
    uut._log.info(f"{tests_passed}/64 opcode tests passed!")

  uut._log.info(f"All {tests_passed} tests passed!")

  uut._log.info("Test Complete!")


