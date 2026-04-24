// =======================================================================
// Module:      Control Unit 
// Project:     Ripple-32
// Description: The control unit generates control signals based on 
//              the opcode and function fields of the instr.
// =======================================================================

module control_unit (
  input  wire [31:0] instr,     // 7-bit opcode field
  output reg  [31:0] imm,
  output reg  [4:0]  rs1,
  output reg  [4:0]  rs2,
  output reg  [4:0]  rd,

  output wire [2:0]  funct3,
  output wire [6:0]  funct7,

  output reg  [3:0]  alu_ctrl,
  output reg         rd_wr_en,

  output wire        is_alu_reg,
  output wire        is_alu_imm,
  output wire        is_jalr,
  output wire        is_load,
  output wire        is_store,
  output wire        is_branch,
  output wire        is_auipc,
  output wire        is_lui,
  output wire        is_jal,
  output wire        is_system
);

// ---------------------------------------------------
// Internal Signals
// ---------------------------------------------------

  wire [31:0] i_imm; 
  wire [31:0] s_imm;
  wire [31:0] b_imm;
  wire [31:0] u_imm; 
  wire [31:0] j_imm; 

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

// ---------------------------------------------------
// ALU Control Logic
// ---------------------------------------------------

  always @(*) begin
    if (is_alu_reg) begin
      alu_ctrl = {instr[30], funct3}; 
    end else if (is_alu_imm) begin
      if (funct3 == 3'b101) begin // SRLI/SRAI (special case)
        alu_ctrl = {instr[30], funct3}; 
      end else begin
        alu_ctrl = {1'b0, funct3}; // force  alu_control[3] low for ADD/XOR/OR/AND/etc
    end 
    end else begin // default to ADD
      alu_ctrl = 4'b0000; 
    end
  end

// ---------------------------------------------------
// Regiister File Control Logic
// ---------------------------------------------------

  always @(*) begin
    case (1'b1)
      // Enable write for instructions that write to rd
      is_alu_reg, is_alu_imm, is_jal, is_jalr, is_load: rd_wr_en = 1'b1; 
      default: rd_wr_en = 1'b0; // Disable write for other instructions
    endcase
  end

endmodule