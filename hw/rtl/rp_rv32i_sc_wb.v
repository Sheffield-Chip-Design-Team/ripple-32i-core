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
  input wire          resume,
  input wire          halt,

  // Instruction bus (ROM interface)
  input  wire [31:0] rom_data_i,
  output reg  [31:0] rom_addr_o,
  output reg         rom_en_o,

  // Data bus (RAM interface)
  output wire [31:0] ram_addr_o,
  output wire [31:0] ram_wdata_o,
  input  wire [31:0] ram_rdata_i,
  output wire        ram_we_o,
  output wire [3:0]  ram_be_o,
  output wire        ram_en_o
);

// ---------------------------------------------------
// Internal Signals
// ---------------------------------------------------
  
  // Fetch stage outputs
  reg  [31:0] f_pc;          // Program counter
  wire [31:0] f_pc_next; 
  reg  [31:0] f_instr;        // Fetched instruction

  // decode-stage outputs
  wire [4:0]  d_rs1;
  wire [4:0]  d_rs2;
  wire [4:0]  d_rd;
  wire [31:0] d_imm;
  wire [2:0]  d_funct3;
  wire [6:0]  d_funct7;
  wire [31:0] d_rs1_data;
  wire [31:0] d_rs2_data;

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

  // execute-stage signals
  wire [31:0] e_src_a;
  wire [31:0] e_src_b;

  wire [31:0] e_alu_result;
  wire [31:0] e_rs1_data;
  wire [31:0] e_rs2_data;

  wire        e_zero;

  // memory access stage outputs
  reg [3:0]   m_byte_en_mask;

  // write-back stage outputs
  wire [31:0] w_rd_data;

// ---------------------------------------------------
// Fetch
// ---------------------------------------------------

  always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      f_pc         <= 32'b0; 
      rom_en_o     <= 1'b0; 
    end else begin
      rom_addr_o   <= f_pc;       // Set ROM address to PC
      rom_en_o     <= 1'b1;       // Enable ROM
      f_instr      <= rom_data_i; // Fetch instruction from ROM
      f_pc         <= pc_next ;   // Increment PC for next instruction
    end
  end
  
  // TODO - add branch logic to update pc_next based on control signals from the control unit
  assign f_pc_next = pc + 4; 

// ---------------------------------------------------
// Decode
// ---------------------------------------------------

  control_unit u_control_unit (
    // instruction input
    .instr      (f_instr),

    // decoded instruction fields
    .imm        (d_imm),
    .rs1        (d_rs1),
    .rs2        (d_rs2),
    .rd         (d_rd),
    .funct3     (d_funct3),
    .funct7     (d_funct7),

    // execution control signals
    .alu_ctrl   (d_alu_ctrl),
    .rd_wr_en   (d_rd_wr_en),

    // opcode type signals
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
// Execute
// ---------------------------------------------------

  // Reigster File instance
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

  // ALU
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
    case (funct3)
      3'b000:  byte_en_mask = 4'b0001 << ex_alu_result[1:0];          // byte
      3'b001:  byte_en_mask = ex_alu_result[1] ? 4'b1100 : 4'b0011;   // halfword
      3'b010:  byte_en_mask = 4'b1111;                                // word
      default: byte_en_mask = 4'b0000;
    endcase
  end

  assign ram_en_o    = is_load | is_store;
  assign ram_we_o    = is_store;
  assign ram_addr_o  = ex_alu_result;
  assign ram_wdata_o = ex_rs2_data;
  assign ram_bstrb_o = byte_en_mask;

// ---------------------------------------------------
// Write Back
// ---------------------------------------------------

  assign rd_data = is_load ? ram_rdata_i : alu_result;

endmodule