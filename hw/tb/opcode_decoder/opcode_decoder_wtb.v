// Auto-generated Verilog Testbench Wrapper - Coraltb 
 
`timescale 1ns/1ns 

module opcode_decoder_wtb;

  // opcode_decoder instantation signals
  reg  [6:0] opcode;
  wire  isALUreg;
  wire  isALUimm;
  wire  isStore;
  wire  isJALR;
  wire  isLoad;
  wire  isBranch;
  wire  isAUIPC;
  wire  isLUI;
  wire  isJAL;
  wire  isSYSTEM;
  
  // debug signal
  wire [9:0] outputs;

  opcode_decoder dut (
      .opcode(opcode),
      .isALUreg(isALUreg),
      .isALUimm(isALUimm),
      .isStore(isStore),
      .isJALR(isJALR),
      .isLoad(isLoad),
      .isBranch(isBranch),
      .isAUIPC(isAUIPC),
      .isLUI(isLUI),
      .isJAL(isJAL),
      .isSYSTEM(isSYSTEM)
  );

  // 1-hot encoding of outputs for easier testing
  assign outputs = {isSYSTEM, isJAL, isLUI, isAUIPC, isBranch, isLoad, isJALR, isStore, isALUimm, isALUreg};

endmodule 
 