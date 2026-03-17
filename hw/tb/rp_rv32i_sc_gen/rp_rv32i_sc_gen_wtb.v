// Auto-generated Verilog Testbench Wrapper - Coraltb 
 
`timescale 1ns/1ns 

module rp_rv32i_sc_gen_wtb;

  // rp_rv32i_sc_gen instantation signals
  reg         clk;
  reg         rst_n;
  reg         resume;
  reg         halt;
  reg  [31:0] rom_data_i;
  wire [31:0] rom_addr_o;
  wire        rom_en_o;
  wire [31:0] ram_addr_o;
  wire [31:0] ram_wdata_o;
  reg  [31:0] ram_rdata_i;
  wire        ram_we_o;
  wire [3:0]  ram_be_o;
  wire        ram_en_o;






rp_rv32i_sc_gen dut (
  .clk(clk),
  .rst_n(rst_n),
  .resume(resume),
  .halt(halt),
  .rom_data_i(rom_data_i),
  .rom_addr_o(rom_addr_o),
  .rom_en_o(rom_en_o),
  .ram_addr_o(ram_addr_o),
  .ram_wdata_o(ram_wdata_o),
  .ram_rdata_i(ram_rdata_i),
  .ram_we_o(ram_we_o),
  .ram_be_o(ram_be_o),
  .ram_en_o(ram_en_o)
  );

endmodule 
 