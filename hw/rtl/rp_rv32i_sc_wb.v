// =======================================================================
// Module:      Ripple-32 Core Top
// Project:     Ripple-32
// Description: The top-level module for the Ripple-32i core.
// =======================================================================

module rp_rv32i_sc_gen (
  // Clock and Reset
  input  wire         clk,
  input  wire         rst_n,

  // debugging interface
  input  wire         resume,
  input  wire         halt,

  // Instruction bus (ROM interface)
  input  wire [31:0]  rom_data_i,
  output reg  [31:0]  rom_addr_o,
  output reg          rom_en_o,

  // Data bus (RAM interface)
  output wire [31:0]  ram_addr_o,
  output wire [31:0]  ram_wdata_o,
  input  wire [31:0]  ram_rdata_i,
  output wire         ram_we_o,
  output wire [3:0]   ram_be_o,
  output wire         ram_en_o
);

// ---------------------------------------------------
// Internal Signals
// ---------------------------------------------------

  // Fetch stage
  reg  [31:0] f_pc;
  wire [31:0] f_pc_next;
  reg  [31:0] f_instr;

  // Decode stage
  wire [4:0]  d_rs1;
  wire [4:0]  d_rs2;
  wire [4:0]  d_rd;
  wire [31:0] d_imm;
  wire [2:0]  d_funct3;
  wire [6:0]  d_funct7;

  wire        d_rd_wr_en;
  wire        d_is_alu_reg;
  wire        d_is_alu_imm;
  wire        d_is_jalr;
  wire [3:0]  d_alu_ctrl;
  wire        d_is_load;
  wire        d_is_store;
  wire        d_is_branch;
  wire        d_is_auipc;
  wire        d_is_lui;
  wire        d_is_jal;
  wire        d_is_system;

  // Register file outputs
  wire [31:0] e_rs1_data;
  wire [31:0] e_rs2_data;

  // Execute stage
  wire [31:0] e_src_a;
  wire [31:0] e_src_b;
  wire [31:0] e_alu_result;
  wire        e_zero;

  // Memory stage
  reg [3:0]   m_byte_en_mask;

  // Writeback stage
  wire [31:0] w_rd_data;


// ---------------------------------------------------
// Fetch
// ---------------------------------------------------

  always @(posedge clk or negedge rst_n) begin
      if (!rst_n) begin
          f_pc     <= 32'b0;
      end
      else begin
          f_pc     <= f_pc_next;   // update PC every cycle, no boot delay
      end
  end

  assign rom_en_o   = rst_n;        // enable ROM on reset release for simplicity
  assign rom_addr_o = f_pc >> 2;    // word-aligned addresses, so drop the bottom 2 bits
  assign f_instr    = rom_data_i;

// ---------------------------------------------------
// Decode
// ---------------------------------------------------

control_unit u_control_unit (
  .instr      (f_instr),

  .imm        (d_imm),
  .rs1        (d_rs1),
  .rs2        (d_rs2),
  .rd         (d_rd),
  .funct3     (d_funct3),
  .funct7     (d_funct7),

  .alu_ctrl   (d_alu_ctrl),
  .rd_wr_en   (d_rd_wr_en),

  .is_alu_reg (d_is_alu_reg),
  .is_alu_imm (d_is_alu_imm),
  .is_jalr    (d_is_jalr),
  .is_load    (d_is_load),
  .is_store   (d_is_store),
  .is_branch  (d_is_branch),
  .is_auipc   (d_is_auipc),
  .is_lui     (d_is_lui),
  .is_jal     (d_is_jal),
  .is_system  (d_is_system)
);

// ---------------------------------------------------
// Register File
// ---------------------------------------------------

reg_file u_reg_file (
  .clk      (clk),
  .rst_n    (rst_n),

  .rd_w_en  (d_rd_wr_en),
  .rd_addr  (d_rd),
  .rd_data  (w_rd_data),

  .rs1_addr (d_rs1),
  .rs2_addr (d_rs2),

  .rs1_data (e_rs1_data),
  .rs2_data (e_rs2_data)
);


// ---------------------------------------------------
// Execute
// ---------------------------------------------------

assign e_src_a = e_rs1_data;
assign e_src_b = d_is_alu_imm ? d_imm : e_rs2_data;

alu u_alu (
  .src_a       (e_src_a),
  .src_b       (e_src_b),
  .alu_control (d_alu_ctrl),
  .alu_result  (e_alu_result),
  .zero        (e_zero)
);

// ---------------------------------------------------
// Memory Access
// ---------------------------------------------------

always @(*) begin
  case (d_funct3)
    3'b000:  m_byte_en_mask = 4'b0001 << e_alu_result[1:0];         // byte
    3'b001:  m_byte_en_mask = e_alu_result[1] ? 4'b1100 : 4'b0011;  // halfword
    3'b010:  m_byte_en_mask = 4'b1111;                              // word
    default: m_byte_en_mask = 4'b0000;
  endcase
end

assign ram_en_o    = d_is_load | d_is_store;
assign ram_we_o    = d_is_store;
assign ram_addr_o  = e_alu_result;
assign ram_wdata_o = e_rs2_data;
assign ram_be_o    = m_byte_en_mask;

// ---------------------------------------------------
// Write Back
// ---------------------------------------------------

assign w_rd_data = d_is_load ? ram_rdata_i :
  (d_is_jal || d_is_jalr) ? (f_pc + 32'd4) :
  e_alu_result;

wire        take_branch    = d_is_branch && e_zero;
wire [31:0] pc_jump_target = f_pc + d_imm;
wire [31:0] pc_jalr_target = (e_rs1_data + d_imm) & 32'hFFFF_FFFE;

assign f_pc_next = d_is_jalr ? pc_jalr_target :
   (d_is_jal || take_branch) ? pc_jump_target :
   f_pc + 32'd4;

endmodule