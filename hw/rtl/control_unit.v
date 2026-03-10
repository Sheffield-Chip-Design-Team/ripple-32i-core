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
);

// ---------------------------------------------------
// Internal Signals
// ---------------------------------------------------

  wire [31:0] i_imm; 
  wire [31:0] s_imm;
  wire [31:0] b_imm;
  wire [31:0] u_imm; 
  wire [31:0] j_imm; 

  wire [2:0]  funct3;
  wire [6:0]  funct7;

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
  
  // Extract register fields
  assign rs1 = instr[19:15];
  assign rs2 = instr[24:20]; 
  assign rd  = instr[11:7];

  assign funct3 = instr[14:12];
  assign funct7 = instr[31:25];

  // Sign-extend immediate values for I,S,B and J types
  assign i_imm = {{21{instr[31]}}, instr[30:20]};                                        
  assign s_imm = {{21{instr[31]}}, instr[30:25], instr[11:7]};  
  assign b_imm = {{20{instr[31]}}, instr[7],     instr[30:25], instr[11:8], 1'b0}; 
  assign u_imm = {instr[31:12],    12'b0};                                     
  assign j_imm = {{12{instr[31]}}, instr[19:12], instr[20], instr[30:21],1'b0};                                       
  
  // select imm based on instruction type
  always @(*) begin 
    case (1'b1)
      is_lui:    imm = u_imm;
      is_store:  imm = s_imm;
      is_branch: imm = b_imm;
      is_jal:    imm = j_imm;
      default:   imm = i_imm;
    endcase
  end

endmodule