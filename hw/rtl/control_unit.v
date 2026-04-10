// =======================================================================
// Module:         Control Unit
// Project:        Ripple-32
// Description:    The control unit generates control signals based on
//                 the opcode and function fields of the instruction.
// Implementation:
//                 Step 1: field decode (imm, rs1, rs2, rd) for each
//                         instruction type
//                 Step 2: grouped RVB32I instruction-family decode
//                 Step 3: datapath control-signal generation
// =======================================================================
`include "rv32i_defs.vh" // contains the localparams

module control_unit (
  // Instruction input
  input  wire [31:0] instr,

  // Decoded outputs for step 1
  output reg  [31:0] imm,
  output reg  [4:0]  rs1,
  output reg  [4:0]  rs2,
  output reg  [4:0]  rd,

  // Step 3 outputs
  output reg [3:0] alu_control,   // 4-bits wide - must match ALU encoding width
  output reg [1:0] alu_a_sel,     // 00 = rs1, 01 = pc, 10 = zero
  output reg       alu_b_sel,     // 0 = rs2, 1 = imm
  output reg       reg_write,
  output reg       mem_read,
  output reg       mem_write,
  output reg [1:0] mem_size,      // 00 = byte, 01 = half, 10 = word
  output reg       load_unsigned, // 0 = signed load, 1 = unsigned load
  output reg [1:0] wb_sel,        // 00 = ALU, 01 = MEM, 10 = PC+4
  output reg [2:0] branch_type,   // for none, beq, bne, blt, bge, bltu, bgeu
  output reg       jump,
  output reg       jalr,
  output reg       illegal_instr
);

// ---------------------------------------------------
// Internal Signals - Broad opcode class
// ---------------------------------------------------
  
  wire is_alu_reg;
  wire is_alu_imm;
  wire is_jalr;
  wire is_load;
  wire is_store;
  wire is_branch;
  wire is_auipc;
  wire is_lui;
  wire is_jal;
  wire is_system;

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
// Helper fields
// ---------------------------------------------------

// For instruction decoding
wire [2:0]  funct3 = instr[14:12];
wire [6:0]  funct7 = instr[31:25];
wire [11:0] imm12  = instr[31:20];

// For illegal detection
reg valid_instr;

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
  illegal_instr = 1'b0;
  valid_instr   = 1'b0;

  // R-type ALU instructions
  if (is_alu_reg) begin
    reg_write = 1'b1;

    case (funct3)
      3'b000: begin
        if (funct7 == 7'b0000000) begin
          alu_control = ALU_ADD;
          valid_instr = 1'b1;
        end
        else if (funct7 == 7'b0100000) begin
          alu_control = ALU_SUB;
          valid_instr = 1'b1;
        end
      end

      3'b001: begin
        if (funct7 == 7'b0000000) begin
          alu_control = ALU_SLL;
          valid_instr = 1'b1;
        end
      end

      3'b010: begin
        if (funct7 == 7'b0000000) begin
          alu_control = ALU_SLT;
          valid_instr = 1'b1;
        end
      end

      3'b011: begin
        if (funct7 == 7'b0000000) begin
          alu_control = ALU_SLTU;
          valid_instr = 1'b1;
        end
      end

      3'b100: begin
        if (funct7 == 7'b0000000) begin
          alu_control = ALU_XOR;
          valid_instr = 1'b1;
        end
      end

      3'b101: begin
        if (funct7 == 7'b0000000) begin
          alu_control = ALU_SRL;
          valid_instr = 1'b1;
        end
        else if (funct7 == 7'b0100000) begin
          alu_control = ALU_SRA;
          valid_instr = 1'b1;
        end
      end

      3'b110: begin
        if (funct7 == 7'b0000000) begin
          alu_control = ALU_OR;
          valid_instr = 1'b1;
        end
      end

      3'b111: begin
        if (funct7 == 7'b0000000) begin
          alu_control = ALU_AND;
          valid_instr = 1'b1;
        end
      end
    endcase

    if (!valid_instr) begin
      reg_write = 1'b0;
    end
  end

  // I-type ALU instructions
  else if (is_alu_imm) begin
    alu_b_sel = 1'b1;
    reg_write = 1'b1;

    case (funct3)
      3'b000: begin // addi
        alu_control = ALU_ADD;
        valid_instr = 1'b1;
      end

      3'b001: begin // slli
        if (funct7 == 7'b0000000) begin
          alu_control = ALU_SLL;
          valid_instr = 1'b1;
        end
      end

      3'b010: begin // slti
        alu_control = ALU_SLT;
        valid_instr = 1'b1;
      end

      3'b011: begin // sltiu
        alu_control = ALU_SLTU;
        valid_instr = 1'b1;
      end

      3'b100: begin // xori
        alu_control = ALU_XOR;
        valid_instr = 1'b1;
      end

      3'b101: begin
        if (funct7 == 7'b0000000) begin // srli
          alu_control = ALU_SRL;
          valid_instr = 1'b1;
        end
        else if (funct7 == 7'b0100000) begin // srai
          alu_control = ALU_SRA;
          valid_instr = 1'b1;
        end
      end

      3'b110: begin // ori
        alu_control = ALU_OR;
        valid_instr = 1'b1;
      end

      3'b111: begin // andi
        alu_control = ALU_AND;
        valid_instr = 1'b1;
      end
    endcase

    if (!valid_instr) begin
      reg_write = 1'b0;
    end
  end

  // Loads
  else if (is_load) begin
    alu_control = ALU_ADD; // address = rs1 + imm
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
    mem_read    = 1'b1;
    wb_sel      = WB_MEM;

    case (funct3)
      3'b000: begin // lb
        mem_size      = 2'b00;
        load_unsigned = 1'b0;
        valid_instr   = 1'b1;
      end

      3'b001: begin // lh
        mem_size      = 2'b01;
        load_unsigned = 1'b0;
        valid_instr   = 1'b1;
      end

      3'b010: begin // lw
        mem_size      = 2'b10;
        load_unsigned = 1'b0;
        valid_instr   = 1'b1;
      end

      3'b100: begin // lbu
        mem_size      = 2'b00;
        load_unsigned = 1'b1;
        valid_instr   = 1'b1;
      end

      3'b101: begin // lhu
        mem_size      = 2'b01;
        load_unsigned = 1'b1;
        valid_instr   = 1'b1;
      end
    endcase

    if (!valid_instr) begin
      reg_write = 1'b0;
      mem_read  = 1'b0;
    end
  end

  // Stores
  else if (is_store) begin
    alu_control = ALU_ADD; // address = rs1 + imm
    alu_b_sel   = 1'b1;
    mem_write   = 1'b1;

    case (funct3)
      3'b000: begin // sb
        mem_size    = 2'b00;
        valid_instr = 1'b1;
      end

      3'b001: begin // sh
        mem_size    = 2'b01;
        valid_instr = 1'b1;
      end

      3'b010: begin // sw
        mem_size    = 2'b10;
        valid_instr = 1'b1;
      end
    endcase

    if (!valid_instr) begin
      mem_write = 1'b0;
    end
  end

  // Branches

  else if (is_branch) begin
    case (funct3)
      3'b000: begin // beq
        alu_control = ALU_SUB;
        branch_type = BR_BEQ;
        valid_instr = 1'b1;
      end

      3'b001: begin // bne
        alu_control = ALU_SUB;
        branch_type = BR_BNE;
        valid_instr = 1'b1;
      end

      3'b100: begin // blt
        alu_control = ALU_SLT;
        branch_type = BR_BLT;
        valid_instr = 1'b1;
      end

      3'b101: begin // bge
        alu_control = ALU_SLT;
        branch_type = BR_BGE;
        valid_instr = 1'b1;
      end

      3'b110: begin // bltu
        alu_control = ALU_SLTU;
        branch_type = BR_BLTU;
        valid_instr = 1'b1;
      end

      3'b111: begin // bgeu
        alu_control = ALU_SLTU;
        branch_type = BR_BGEU;
        valid_instr = 1'b1;
      end
    endcase
  end

  // JAL
  else if (is_jal) begin
    reg_write   = 1'b1;
    wb_sel      = WB_PC4;
    jump        = 1'b1;
    valid_instr = 1'b1;
  end

  // JALR
  else if (is_jalr) begin
    if (funct3 == 3'b000) begin
    alu_control = ALU_ADD; // target = rs1 + imm
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
    wb_sel      = WB_PC4;
    jump        = 1'b1;
    jalr        = 1'b1;
    valid_instr = 1'b1;
    end
  end

  // LUI
  else if (is_lui) begin
    alu_control = ALU_ADD; // 0 + imm
    alu_a_sel   = ALU_A_ZERO;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
    wb_sel      = WB_ALU;
    valid_instr = 1'b1;
  end

  // AUIPC
  else if (is_auipc) begin
    alu_control = ALU_ADD; // pc + imm
    alu_a_sel   = ALU_A_PC;
    alu_b_sel   = 1'b1;
    reg_write   = 1'b1;
    wb_sel      = WB_ALU;
    valid_instr = 1'b1;
  end

  // SYSTEM subset
  else if (is_system) begin
    if ((funct3 == 3'b000) && (imm12 == 12'h000)) begin
      // ecall
      valid_instr = 1'b1;
    end
    else if ((funct3 == 3'b000) && (imm12 == 12'h001)) begin
      // ebreak
      valid_instr = 1'b1;
    end
  end

  // Final illegal-instruction detection
  if (!valid_instr) begin
    illegal_instr = 1'b1;
  end
end


endmodule
