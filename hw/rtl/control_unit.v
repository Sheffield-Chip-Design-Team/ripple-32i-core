// =======================================================================
// Module:      Control Unit 
// Project:     Ripple-32
// Description: The control unit generates control signals based on 
//              the opcode and function fields of the instruction.
// =======================================================================

module control_unit (
    input wire [6:0] opcode,     // 7-bit opcode field
    input wire [6:0] funct3,     
    input wire       funct7,
    output reg       reg_write,   
    output reg       result_src,
    output reg       mem_write,  
    output reg       jump,      
    output reg       alu_control_id, 
    output reg       alu_src,
    output reg       imm_src
  );

// ---------------------------------------------------
// Opcode Decoder
// ---------------------------------------------------

  // TODO - connect the opcode decoder up
  opcode_decoder u_opcode_decoder (
    .opcode(),
    .isALUreg(),
    .isALUimm(),
    .isStore(iStore),
    .isJALR(),
    .isLoad(),
    .isBranch(),
    .isAUIPC(),
    .isLUI(),
    .isJAL(),
    .isSYSTEM()
  )

// ---------------------------------------------------
// Field Decoder
// ---------------------------------------------------

// TODO - add logic to set control signals based on opcode, funct3, and funct7


endmodule