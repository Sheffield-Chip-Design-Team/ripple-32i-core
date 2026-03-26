// =======================================================================
// Module:      Control Unit 
// Project:     Ripple-32
// Description: The control unit generates control signals based on 
//              the opcode and function fields of the instr.
// =======================================================================

module control_unit (
  // instruction fields
  input  wire [31:0] instr,     // 7-bit opcode field
  
  // decoded fields
  output reg  [31:0] imm,
  output reg  [4:0]  rs1,
  output reg  [4:0]  rs2,
  output reg  [4:0]  rd
  
  // TODO - add control signals to the rest of the CPU
  
);

// ---------------------------------------------------
// Internal Signals - Broad opcode class
// ---------------------------------------------------
  
  wire        is_alu_reg;
  wire        is_alu_imm;
  wire        is_jalr;
  wire        is_load;
  wire        is_store;
  wire        is_branch;
  wire        is_auipc;
  wire        is_lui;
  wire        is_jal;
  wire        is_system;

// ---------------------------------------------------
// Opcode Decoder
// ---------------------------------------------------

  opcode_decoder u_opcode_decoder (
    .opcode   (instr[6:0]),
    .isALUreg (is_alu_reg),
    .isALUimm (is_alu_imm),
    .isStore  (is_store),
    .isJALR   (is_jalr),
    .isLoad   (is_load),
    .isBranch (is_branch),
    .isAUIPC  (is_auipc),
    .isLUI    (is_lui),
    .isJAL    (is_jal),
    .isSYSTEM (is_system)
  );

// ---------------------------------------------------
// Helper fields for exact instruction decode
// ---------------------------------------------------

wire [2:0]  funct3 = instr[14:12];
wire [6:0]  funct7 = instr[31:25];
wire [11:0] imm12  = instr[31:20];

// ---------------------------------------------------
// Exact RV32I instruction decode (Step 2)
// ---------------------------------------------------

// R-type ALU
wire is_add  = is_alu_reg && (funct3 == 3'b000) && (funct7 == 7'b0000000);
wire is_sub  = is_alu_reg && (funct3 == 3'b000) && (funct7 == 7'b0100000);
wire is_sll  = is_alu_reg && (funct3 == 3'b001) && (funct7 == 7'b0000000);
wire is_slt  = is_alu_reg && (funct3 == 3'b010) && (funct7 == 7'b0000000);
wire is_sltu = is_alu_reg && (funct3 == 3'b011) && (funct7 == 7'b0000000);
wire is_xor  = is_alu_reg && (funct3 == 3'b100) && (funct7 == 7'b0000000);
wire is_srl  = is_alu_reg && (funct3 == 3'b101) && (funct7 == 7'b0000000);
wire is_sra  = is_alu_reg && (funct3 == 3'b101) && (funct7 == 7'b0100000);
wire is_or   = is_alu_reg && (funct3 == 3'b110) && (funct7 == 7'b0000000);
wire is_and  = is_alu_reg && (funct3 == 3'b111) && (funct7 == 7'b0000000);

// I-type ALU
wire is_addi  = is_alu_imm && (funct3 == 3'b000);
wire is_slli  = is_alu_imm && (funct3 == 3'b001) && (funct7 == 7'b0000000);
wire is_slti  = is_alu_imm && (funct3 == 3'b010);
wire is_sltiu = is_alu_imm && (funct3 == 3'b011);
wire is_xori  = is_alu_imm && (funct3 == 3'b100);
wire is_srli  = is_alu_imm && (funct3 == 3'b101) && (funct7 == 7'b0000000);
wire is_srai  = is_alu_imm && (funct3 == 3'b101) && (funct7 == 7'b0100000);
wire is_ori   = is_alu_imm && (funct3 == 3'b110);
wire is_andi  = is_alu_imm && (funct3 == 3'b111);

// Loads
wire is_lb  = is_load && (funct3 == 3'b000);
wire is_lh  = is_load && (funct3 == 3'b001);
wire is_lw  = is_load && (funct3 == 3'b010);
wire is_lbu = is_load && (funct3 == 3'b100);
wire is_lhu = is_load && (funct3 == 3'b101);

// Stores
wire is_sb = is_store && (funct3 == 3'b000);
wire is_sh = is_store && (funct3 == 3'b001);
wire is_sw = is_Store && (funct3 == 3'b010);

// Branches
wire is_beq  = is_branch && (funct3 == 3'b000);
wire is_bne  = is_branch && (funct3 == 3'b001);
wire is_blt  = is_branch && (funct3 == 3'b100);
wire is_bge  = is_branch && (funct3 == 3'b101);
wire is_bltu = is_branch && (funct3 == 3'b110);
wire is_bgeu = is_branch && (funct3 == 3'b111);

// Jump / upper-immediate
wire is_jal_i   = is_jal;
wire is_jalr_i  = is_jalr && (funct3 == 3'b000);
wire is_lui_i   = is_lui;
wire is_auipc_i = is_auipc;

// SYSTEM subset
wire is_ecall  = is_system && (funct3 == 3'b000) && (imm12 == 12'h000);
wire is_ebreak = is_system && (funct3 == 3'b000) && (imm12 == 12'h001);

// ---------------------------------------------------
// Field Decoder (Step 1)
// ---------------------------------------------------
  
always @(*) begin
  // Safe defaults for unused fields
  imm = 32'b0;
  rs1 = 5'b0;
  rs2 = 5'b0;
  rd  = 5'b0;

  // R-type: ALU register-register
  if (is_alu_reg) begin
    rs1 = instr[19:15];
    rs2 = instr[24:20];
    rd  = instr[11:7];
    imm = 32'b0;
  end

  // I-type: ALU immediate, loads, JALR, SYSTEM
  else if (is_alu_imm || is_load || is_jalr || is_system) begin
    rs1 = instr[19:15];
    rd = instr[11:7];
    imm = {{20{instr[31]}}, instr[31:20]};
  end

  // S-type: stores
  else if (is_store) begin
    rs1 = instr[19:15];
    rs2 = instr[24:20];
    imm = {{20{instr[31]}}, instr[31:25], instr[11:7]};
  end

  // B-type: branches
  else if (is_branch) begin
    rs1 = instr[19:15];
    rs2 = instr[24:20];
    imm = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
  end

  // U-type: AUIPC, LUI
  else if (is_auipc || is_lui) begin
    rd = instr[11:7];
    imm = {instr[31:12], 12'b0};
  end

  // J-type: JAL
  else if (is_jal) begin
    rd = instr[11:7];
    imm = {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0};
  end
end

endmodule
