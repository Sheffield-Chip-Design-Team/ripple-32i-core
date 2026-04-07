// =======================================================================
// Module:         Control Unit 
// Project:        Ripple-32
// Description:    The control unit generates control signals based on
//                 the opcode and function fields of the instr.
// Implementation:
//                 Step 1: field decode (imm, rs1, rs2, rd) for each
//                         instruction type
//                 Step 2: exact RV32I instruction decode
//                 Step 3: datapath control-signal generation
// =======================================================================

module control_unit (
  // instruction fields
  input  wire [31:0] instr,     // 7-bit opcode field

  // Decoded outputs for step 1
  output reg  [31:0] imm,
  output reg  [4:0]  rs1,
  output reg  [4:0]  rs2,
  output reg  [4:0]  rd,
  
  // Step 3 outputs
  output reg [3:0] alu_control,   // 4-bits wide - this needs to match in the ALU
  output reg [1:0] alu_a_sel,     // 00 = rs1, 01 = pc, 10 = zero
  output reg       alu_b_sel,     // 0 = rs2, 1 = imm
  output reg       reg_write,
  output reg       mem_read,
  output reg       mem_write,
  output reg [1:0] mem_size,      // 00 = byte, 01 = half, 10 = word
  output reg       load_unsigned, // 0 = signed load, 1 = unsigned load
  output reg [1:0] wb_sel,        // 00 = ALU, 01 = MEM, 10 = PC+4
  output reg [2:0] branch_type,   // for none, beq, bne, blt, bge, bltu,
  output reg       jump,
  output reg       jalr
);

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
wire is_sw = is_store && (funct3 == 3'b010);

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

// ---------------------------------------------------
// Control Signal Generator (Step 3)
// ---------------------------------------------------
always @(*) begin
  // Safe defaults
  alu_control   = ALU_ADD;
  alu_a_sel     = ALU_A_RS1;
  alu_b_sel     = 1'b0;      // rs2
  reg_write     = 1'b0;
  mem_read      = 1'b0;
  mem_write     = 1'b0;
  mem_size      = 2'b10;     // word default
  load_unsigned = 1'b0;
  wb_sel        = WB_ALU;
  branch_type   = BR_NONE;
  jump          = 1'b0;
  jalr          = 1'b0;

  // R-type ALU
  if (is_add) begin
    alu_control = ALU_ADD;
    reg_write   = 1'b1;
  end
  else if (is_sub) begin
    alu_control = ALU_SUB;
    reg_write   = 1'b1;
  end
  else if (is_sll) begin
    alu_control = ALU_SLL;
    reg_write   = 1'b1;
  end
  else if (is_slt) begin
    alu_control = ALU_SLT;
    reg_write   = 1'b1;
  end
  else if (is_sltu) begin
    alu_control = ALU_SLTU;
    reg_write   = 1'b1;
  end
  else if (is_xor) begin
    alu_control = ALU_XOR;
    reg_write   = 1'b1;
  end
  else if (is_srl) begin
    alu_control = ALU_SRL;
    reg_write   = 1'b1;
  end
  else if (is_sra) begin
    alu_control = ALU_SRA;
    reg_write   = 1'b1;
  end
  else if (is_or) begin
    alu_control = ALU_OR;
    reg_write   = 1'b1;
  end
  else if (is_and) begin
    alu_control = ALU_AND;
    reg_write   = 1'b1;
  end

  // I-type ALU
  else if (is_addi) begin
    alu_control = ALU_ADD;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
  end
  else if (is_slli) begin
    alu_control = ALU_SLL;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
  end
  else if (is_slti) begin
    alu_control = ALU_SLT;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
  end
  else if (is_sltiu) begin
    alu_control = ALU_SLTU;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
  end
  else if (is_xori) begin
    alu_control = ALU_XOR;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
  end
  else if (is_srli) begin
    alu_control = ALU_SRL;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
  end
  else if (is_srai) begin
    alu_control = ALU_SRA;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
  end
  else if (is_ori) begin
    alu_control = ALU_OR;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
  end
  else if (is_andi) begin
    alu_control = ALU_AND;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
  end

  // Loads
  else if (is_lb) begin
    alu_control   = ALU_ADD;
    alu_b_sel     = 1'b1;
    reg_write     = 1'b1;
    mem_read      = 1'b1;
    mem_size      = 2'b00;
    load_unsigned = 1'b0;
    wb_sel        = WB_MEM;
  end
  else if (is_lh) begin
    alu_control   = ALU_ADD;
    alu_b_sel     = 1'b1;
    reg_write     = 1'b1;
    mem_read      = 1'b1;
    mem_size      = 2'b01;
    load_unsigned = 1'b0;
    wb_sel        = WB_MEM;
  end
  else if (is_lw) begin
    alu_control   = ALU_ADD;
    alu_b_sel     = 1'b1;
    reg_write     = 1'b1;
    mem_read      = 1'b1;
    mem_size      = 2'b10;
    load_unsigned = 1'b0;
    wb_sel        = WB_MEM;
  end
    else if (is_lbu) begin
    alu_control   = ALU_ADD;
    alu_b_sel     = 1'b1;
    reg_write     = 1'b1;
    mem_read      = 1'b1;
    mem_size      = 2'b00;
    load_unsigned = 1'b1;
    wb_sel        = WB_MEM;
  end
    else if (is_lhu) begin
    alu_control   = ALU_ADD;
    alu_b_sel     = 1'b1;
    reg_write     = 1'b1;
    mem_read      = 1'b1;
    mem_size      = 2'b01;
    load_unsigned = 1'b1;
    wb_sel        = WB_MEM;
  end

  // Stores
  else if (is_sb) begin
    alu_control = ALU_ADD;
    alu_b_sel   = 1'b1;
    mem_write   = 1'b1;
    mem_size    = 2'b00;
  end
  else if (is_sh) begin
    alu_control = ALU_ADD;
    alu_b_sel   = 1'b1;
    mem_write   = 1'b1;
    mem_size    = 2'b01;
  end
  else if (is_sw) begin
    alu_control = ALU_ADD;
    alu_b_sel   = 1'b1;
    mem_write   = 1'b1;
    mem_size    = 2'b10;
  end

  // Branches

  else if (is_beq) begin
    alu_control = ALU_ADD;
    branch_type = BR_BEQ;
  end
  else if (is_bne) begin
    alu_control = ALU_SUB;
    branch_type = BR_BNE;
  end
  else if (is_blt) begin
    alu_control = ALU_SLT;
    branch_type = BR_BLT;
  end
  else if (is_bge) begin
    alu_control = ALU_SLT;
    branch_type = BR_BGE;
  end
  else if (is_bltu) begin
    alu_control = ALU_SLTU;
    branch_type = BR_BLTU;
  end
  else if (is_bgeu) begin
    alu_control = ALU_SLTU;
    branch_type = BR_BGEU;
  end

  // Jumps / upper-immediate
  else if (is_jal_i) begin
    reg_write = 1'b1;
    wb_sel    = WB_PC4;
    jump      = 1'b1;
  end
  else if (is_jalr_i) begin
    alu_control = ALU_ADD; // target = rs1 + imm
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
    wb_sel      = WB_PC4;
    jump        = 1'b1;
    jalr        = 1'b1;
  end
  else if (is_lui_i) begin
    alu_control = ALU_ADD; // 0 + imm
    alu_a_sel   = ALU_A_ZERO;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
    wb_sel      = WB_ALU;
  end
  else if (is_auipc_i) begin
    alu_control = ALU_ADD; // pc + imm
    alu_a_sel   = ALU_A_PC;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
    wb_sel      = WB_ALU;
  end

  // SYSTEM subset
  else if (is_ecall) begin
    // leave defaults for now
  end
  else if (is_ebreak) begin
    // leave defaults for now
  end
end


endmodule
