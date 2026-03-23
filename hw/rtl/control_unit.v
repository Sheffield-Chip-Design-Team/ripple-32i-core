// =======================================================================
// Module:      Control Unit 
// Project:     Ripple-32
// Description: The control unit generates control signals based on 
//              the opcode and function fields of the instr.
// =======================================================================

module control_unit (
  // instruction fields
  input  wire [31:0] instr,     // 7-bit opcode field
  output reg  [31:0] imm,
  output reg  [4:0]  rs1,
  output reg  [4:0]  rs2,
  output reg  [4:0]  rd
  // TODO - add control signals to the rest of the CPU
  
);

// ---------------------------------------------------
// Internal Signals
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
// Field Decoder
// ---------------------------------------------------
  
// TODO .. write logic for decoding the fields

endmodule
