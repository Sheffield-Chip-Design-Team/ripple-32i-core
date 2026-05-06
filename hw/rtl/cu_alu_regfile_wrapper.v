`include "rv32i_defs.vh"

module cu_alu_regfile_wrapper(
    input wire          clk,
    input wire          rst_n,
    input wire [31:0]   instr,
    input wire [31:0]   pc,

    // Optional debug outputs
    output wire [31:0]  debug_imm,
    output wire [4:0]   debug_rs1,
    output wire [4:0]   debug_rs2,
    output wire [4:0]   debug_rd,
    output wire [31:0]  debug_rd1_data,
    output wire [31:0]  debug_rd2_data,
    output wire [31:0]  debug_alu_operand_a,
    output wire [31:0]  debug_alu_operand_b,
    output wire [31:0]  debug_alu_result,
    output wire         debug_reg_write,
    output wire         debug_illegal_instr
);

// =======================================================================
// Control unit outputs
// =======================================================================
    wire [31:0] imm;
    wire [4:0]  rs1;
    wire [4:0]  rs2;
    wire [4:0]  rd;

    wire [3:0]  alu_control;
    wire [1:0]  alu_a_sel;
    wire        alu_b_sel;
    wire        reg_write;
    wire        mem_read;
    wire        mem_write;
    wire [1:0]  mem_size;
    wire        load_unsigned;
    wire [1:0]  wb_sel;
    wire [2:0]  branch_type;
    wire        jump;
    wire        jalr;
    wire        illegal_instr;

    // =======================================================================
    // Register file outputs
    // =======================================================================
    wire [31:0] rd1_data;
    wire [31:0] rd2_data;

    // =======================================================================
    // ALU input signals
    // =======================================================================
    reg [31:0] alu_operand_a;
    reg [31:0] alu_operand_b;

    // =======================================================================
    // ALU outputs
    // =======================================================================
    wire [31:0] alu_result;
    wire        alu_zero;
    wire        alu_carry;
    wire        alu_overflow;

    // =======================================================================
    // Write-back path - write back to ALU result only
    // =======================================================================
    wire [31:0] writeback_data;
    assign writeback_data = alu_result;

    // =======================================================================
    // Control Unit instantiation
    // ======================================================================
    control_unit u_control_unit (
        .instr            (instr),
        .imm              (imm),
        .rs1              (rs1),
        .rs2              (rs2),
        .rd               (rd),
    
        .alu_control      (alu_control), // ALU should match 4-bit signal 
        .alu_a_sel        (alu_a_sel),
        .alu_b_sel        (alu_b_sel),
        .reg_write        (reg_write),
        .mem_read         (mem_read),
        .mem_write        (mem_write),
        .mem_size         (mem_size),
        .load_unsigned    (load_unsigned),
        .wb_sel           (wb_sel),
        .branch_type      (branch_type),
        .jump             (jump),
        .jalr             (jalr),
        .illegal_instr    (illegal_instr)
    );

    // =======================================================================
    // Register File instantiation
    // =======================================================================
    reg_file u_reg_file (
        .clk      (clk),
        .rst_n    (rst_n),

        .rs1_addr (rs1),
        .rd1_data (rd1_data),

        .rs2_addr (rs2),
        .rd2_data (rd2_data),

        .rd_addr  (rd),
        .wr_data  (writeback_data),
        .wr_en    (reg_write)
    );

    // =======================================================================
    // ALU operand A mux
    // alu_a_sel chooses between:
    //   ALU_A_RS1 ->  rd1_data
    //   ALU_A_PC  ->  pc
    //   ALU_A_ZERO -> 32'b0
    // =======================================================================
    always @(*) begin
        case (alu_a_sel)
            ALU_A_RS1: alu_operand_a = rd1_data;
            ALU_A_PC:  alu_operand_a = pc;
            ALU_A_ZERO:alu_operand_a = 32'b0;
            default:   alu_operand_a = 32'b0; // Default case to avoid latches
        endcase
    end

    // =======================================================================
    // ALU operand B mux
    // alu_b_sel chooses between:
    //   0 -> rd2_data
    //   1 -> imm
    // =======================================================================
    always @(*) begin
        case (alu_b_sel)
            1'b0: alu_operand_b = rd2_data;
            1'b1: alu_operand_b = imm;
            default: alu_operand_b = 32'b0; // Default case to avoid latches
        endcase
    end

    // =======================================================================
    // ALU instantiation
    // =======================================================================
    alu u_alu (
        .a (alu_operand_a),
        .b (alu_operand_b),
        .alu_control (alu_control),
        .result (alu_result),
        .zero (alu_zero),
        .carry (alu_carry),
        .overflow (alu_overflow)
    );

    // =======================================================================
    // Optional debug outputs
    // =======================================================================
    assign debug_imm = imm;
    assign debug_rs1 = rs1;
    assign debug_rs2 = rs2;
    assign debug_rd = rd;
    assign debug_rd1_data = rd1_data;
    assign debug_rd2_data = rd2_data;
    assign debug_alu_operand_a = alu_operand_a;
    assign debug_alu_operand_b = alu_operand_b;
    assign debug_alu_result = alu_result;
    assign debug_reg_write = reg_write;
    assign debug_illegal_instr = illegal_instr;


endmodule