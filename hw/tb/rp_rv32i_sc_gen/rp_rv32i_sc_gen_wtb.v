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

  block_ram_model #(
    .ADDR_WIDTH(32),
    .DATA_WIDTH(32),
    .INIT_VALUE(32'h0000_0013),
    .RAM_WORDS(1024),
    .READ_DELAY(0)
  ) prog_rom (
    .clk      (clk),
    .addr     (rom_addr_o),
    .wdata    (32'b0),
    .bit_strb (32'd0),
    .en       (rom_en_o),
    .wr_en    (1'b0),
    .rdata    (rom_data_i)
  );

  rp_rv32i_sc_gen dut (
    .clk          (clk),
    .rst_n        (rst_n),
    .resume       (resume),
    .halt         (halt),
    
    // Generic Program ROM interface
    .rom_data_i   (rom_data_i),
    .rom_addr_o   (rom_addr_o),
    .rom_en_o     (rom_en_o),
    
    // Generic Data RAM interface
    .ram_addr_o   (ram_addr_o),
    .ram_wdata_o  (ram_wdata_o),
    .ram_rdata_i  (ram_rdata_i),
    .ram_we_o     (ram_we_o),
    .ram_be_o     (ram_be_o),
    .ram_en_o     (ram_en_o)
  );

endmodule 
 