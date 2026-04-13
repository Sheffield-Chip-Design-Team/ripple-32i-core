// Auto-generated Verilog Testbench Wrapper - Coraltb 
 
`timescale 1ns/1ns 


module control_unit_wtb;

  // control_unit instantation signals
  reg  [31:0] instr;
  wire [31:0] imm;
  wire [4:0] rs1;
  wire [4:0] rs2;
  wire [4:0] rd;
  wire [3:0] alu_control;
  wire [1:0] alu_a_sel;
  wire  alu_b_sel;
  wire  reg_write;
  wire  mem_read;
  wire  mem_write;
  wire [1:0] mem_size;
  wire  load_unsigned;
  wire [1:0] wb_sel;
  wire [2:0] branch_type;
  wire  jump;
  wire  jalr;
  wire  illegal_instr;

control_unit dut (
      .instr(instr),
      .imm(imm),
      .rs1(rs1),
      .rs2(rs2),
      .rd(rd),
      .alu_control(alu_control),
      .alu_a_sel(alu_a_sel),
      .alu_b_sel(alu_b_sel),
      .reg_write(reg_write),
      .mem_read(mem_read),
      .mem_write(mem_write),
      .mem_size(mem_size),
      .load_unsigned(load_unsigned),
      .wb_sel(wb_sel),
      .branch_type(branch_type),
      .jump(jump),
      .jalr(jalr),
      .illegal_instr(illegal_instr)
  );

endmodule 
 