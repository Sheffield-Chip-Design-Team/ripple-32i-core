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
  output wire       isStore,   // S-type
  output wire       isJALR,    // I-type
  output wire       isLoad,    // I-type
  output wire       isBranch,  // B-type
  output wire       isAUIPC,   // U-type
  output wire       isLUI,     // U-type
  output wire       isJAL,     // J-type
  output wire       isSYSTEM   // SYSTEM instructions (ECALL, EBREAK, etc.)
);     

  // TODO - add all 10 instruction types -  See the table P. 105 in RISC-V manual
  // https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf

  localparam [6:0] ALU_REG_OPCODE = 7'b0110011;
  localparam [6:0] ALU_IMM_OPCODE = 7'b0010011;
  localparam [6:0] BRANCH_OPCODE  = 7'b1100011;

  assign isALUreg = (opcode[6:0] == ALU_REG_OPCODE);   // rd <- rs1 OP rs2   
  assign isALUimm = (opcode[6:0] == ALU_IMM_OPCODE);   // rd <- rs1 OP Iimm
  assign isBranch = (opcode[6:0] == BRANCH_OPCODE);    // if(rs1 OP rs2) PC<-PC+Bimm
  // ... add more instruction types here

endmodule
