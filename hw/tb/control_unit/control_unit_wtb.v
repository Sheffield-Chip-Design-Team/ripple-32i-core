// Auto-generated Verilog Testbench Wrapper - Coraltb 
 
`timescale 1ns/1ns 


module control_unit_wtb;

  // control_unit instantation signals
  reg  [31:0] instr;
  wire [31:0] imm;
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [4:0] rd;

control_unit dut (
      .instr(instr),
      .imm(imm),
      .rs1(rs1),
      .rs2(rs2),
      .rd(rd)
  );

endmodule 
 