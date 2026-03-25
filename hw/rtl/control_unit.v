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
