// =======================================================================
// Module:      RV32I Opcode Decoder
// Project:     Ripple-32
// Description: The decoder module takes the 7-bit opcode field from the instruction and
//              generates signals indicating the type of instruction (R-type, I-type, etc.)
// =======================================================================

// Elements taken from https://github.com/MichaelBell/tinyQV/blob/main/cpu/decode.v

module opcode_decoder (
  input  wire [6:0] opcode,    // 7-bit opcode field
  output wire       isALUreg,  // R-type
  output wire       isALUimm,  // I-type
  output wire       isJALR,    // I-type
  output wire       isLoad,    // I-type
  output wire       isStore,   // S-type
  output wire       isBranch,  // B-type
  output wire       isAUIPC,   // U-type
  output wire       isLUI,     // U-type
  output wire       isJAL,     // J-type
  output wire       isSYSTEM   // SYSTEM instructions (ECALL, EBREAK, etc.)
);     

  // The opcode field is the first 7 bits of the instruction.
  // The instruction format is based on the RISC-V ISA specification.
  // Reference: https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf

  localparam [6:0] ALU_REG_OPCODE = 7'b0110011;
  localparam [6:0] ALU_IMM_OPCODE = 7'b0010011;
  localparam [6:0] BRANCH_OPCODE  = 7'b1100011;
  localparam [6:0] LOAD_OPCODE    = 7'b0000011;
  localparam [6:0] STORE_OPCODE   = 7'b0100011;
  localparam [6:0] JALR_OPCODE    = 7'b1100111;
  localparam [6:0] JAL_OPCODE     = 7'b1101111;
  localparam [6:0] AUIPC_OPCODE   = 7'b0010111;
  localparam [6:0] LUI_OPCODE     = 7'b0110111;
  localparam [6:0] SYSTEM_OPCODE  = 7'b1110011;

  assign isALUreg = (opcode[6:0] == ALU_REG_OPCODE);   // rd <- rs1 OP rs2   
  assign isALUimm = (opcode[6:0] == ALU_IMM_OPCODE);   // rd <- rs1 OP Iimm
  assign isBranch = (opcode[6:0] == BRANCH_OPCODE);    // if(rs1 OP rs2) PC<-PC+Bimm
  assign isLoad   = (opcode[6:0] == LOAD_OPCODE);      // if(rs1 OP rs2) PC<-PC+Bimm
  assign isStore  = (opcode[6:0] == STORE_OPCODE);     // rs2 <- rs1 OP Simm
  assign isJALR   = (opcode[6:0] == JALR_OPCODE);      // rd <- PC+4; PC <- rs1 + Iimm
  assign isJAL    = (opcode[6:0] == JAL_OPCODE);       // rd <- PC+4; PC <- PC + Jimm
  assign isAUIPC  = (opcode[6:0] == AUIPC_OPCODE);     // rd <- PC + Uimm
  assign isLUI    = (opcode[6:0] == LUI_OPCODE);       // rd <- Uimm
  assign isSYSTEM = (opcode[6:0] == SYSTEM_OPCODE);    // SYSTEM instructions (ECALL, EBREAK, etc.)

endmodule
