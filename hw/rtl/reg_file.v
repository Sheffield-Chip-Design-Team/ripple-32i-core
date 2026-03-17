// =======================================================================
// Module:      RV32I Register File
// Project:     Ripple-32
// Description: The register file contains 32 registers, each 32 bits wide. 
// =======================================================================

module reg_file (
  input wire         clk,        
  input wire         rst_n,
  
  // Write port
  input wire         rd_w_en,   // Enable signal for writing to destination register
  input wire [4:0]   rd_addr,   // Address of destination register
  input wire [31:0]  rd_data,   // Data to write to destination register
  
  // Rs1 Read ports
  input wire [4:0]   rs1_addr,  // Address of source register 1
  input wire [4:0]   rs2_addr,  // Address of source register
  
  // rs2 Read ports
  output wire [31:0] rs1_data,  // Data read from source register
  output wire [31:0] rs2_data   // Data read from source register
);

  // 32 registers, each 32 bits wide
  reg [31:0] regs [31:0]; 

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      // Reset all registers to 0
      integer i;
      for (i = 0; i < 32; i = i + 1) begin
        regs[i] <= 32'b0;
      end
    end else begin
      // Write to the register file 
      if (rd_w_en && (rd_addr != 0)) begin
        regs[rd_addr] <= rd_data;
      end
    end
  end

  assign rs1_data = (rs1_addr == 0) ? 32'b0 : regs[rs1_addr];
  assign rs2_data = (rs2_addr == 0) ? 32'b0 : regs[rs2_addr];
  
endmodule