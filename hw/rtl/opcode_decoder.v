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

  // TODO - add all opcode types See from P. 105, and the table on page 130 in RISC-V manual
  // https://github.com/riscv/riscv-isa-manual/releases/download/Ratified-IMAFDQC/riscv-spec-20191213.pdf
  
  // More consice table here:
  // https://www.cs.sfu.ca/~ashriram/Courses/CS295/assets/notebooks/RISCV/RISCV_CARD.pdf

  localparam [6:0] ALU_REG_OPCODE             = 7'b0110011;
  localparam [6:0] ALU_IMM_OPCODE             = 7'b0010011;
  localparam [6:0] JUMP_AND_LINK_REG_OPCODE   = 7'b1100111;
  localparam [6:0] LOAD_BYTE_OPCODE           = 7'b0000011;
  localparam [6:0] STORE_BYTE_OPCODE          = 7'b0100011;
  localparam [6:0] BRANCH_OPCODE              = 7'b1100011;
  localparam [6:0] ADD_UPPER_IMM_TO_PC_OPCODE = 7'b0010111;
  localparam [6:0] LOAD_UPPER_IMM_OPCODE      = 7'b0110111;
  localparam [6:0] JUMP_AND_LINK_OPCODE       = 7'b1101111;
  localparam [6:0] ENVIRONMENT_OPCODE         = 7'b1110011;
 
  assign isALUreg = (opcode[6:0] == ALU_REG_OPCODE);   // rd <- rs1 OP rs2   
  assign isALUimm = (opcode[6:0] == ALU_IMM_OPCODE);   // rd <- rs1 OP Iimm
  assign isBranch = (opcode[6:0] == BRANCH_OPCODE);    // if(rs1 OP rs2) PC<-PC+Bimm
  assign isLoad   = (opcode[6:0] == LOAD_BYTE_OPCODE); 
  assign isStore  = (opcode[6:0] == STORE_BYTE_OPCODE);
  assign isJAL    = (opcode[6:0] == JUMP_AND_LINK_OPCODE);
  assign isJALR   = (opcode[6:0] == JUMP_AND_LINK_REG_OPCODE);
  assign isLUI    = (opcode[6:0] == LOAD_UPPER_IMM_OPCODE);
  assign isAUIPC  = (opcode[6:0] == ADD_UPPER_IMM_TO_PC_OPCODE);
  assign isSYSTEM = (opcode [6:0] == ENVIRONMENT_OPCODE);


endmodule
