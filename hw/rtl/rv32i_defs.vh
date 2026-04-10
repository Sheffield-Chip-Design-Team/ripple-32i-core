`ifndef RV32I_DEFS_VH
`define RV32I_DEFS_VH

// ---------------------------------------------------
// ALU control encoding
// ---------------------------------------------------
  localparam ALU_ADD  = 4'b0000;
  localparam ALU_SUB  = 4'b0001;
  localparam ALU_SLL  = 4'b0010;
  localparam ALU_SLT  = 4'b0011;
  localparam ALU_SLTU = 4'b0100;
  localparam ALU_XOR  = 4'b0101;
  localparam ALU_SRL  = 4'b0110;
  localparam ALU_SRA  = 4'b0111;
  localparam ALU_OR   = 4'b1000;
  localparam ALU_AND  = 4'b1001;

// ---------------------------------------------------
// ALU A select encoding
// ---------------------------------------------------
  localparam ALU_A_RS1  = 2'b00;
  localparam ALU_A_PC   = 2'b01;
  localparam ALU_A_ZERO = 2'b10;

// ---------------------------------------------------
// Branch type encoding
// ---------------------------------------------------
  localparam BR_NONE = 3'b000;
  localparam BR_BEQ  = 3'b001;
  localparam BR_BNE  = 3'b010;
  localparam BR_BLT  = 3'b011;
  localparam BR_BGE  = 3'b100;
  localparam BR_BLTU = 3'b101;
  localparam BR_BGEU = 3'b110;

// ---------------------------------------------------
// Write-back select encoding
// ---------------------------------------------------
  localparam WB_ALU = 2'b00;
  localparam WB_MEM = 2'b01;
  localparam WB_PC4 = 2'b10;

`endif