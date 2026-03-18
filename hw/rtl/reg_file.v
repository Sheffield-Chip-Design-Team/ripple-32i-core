// =======================================================================
// Module:      RV32I Register File
// Project:     Ripple-32
// Description: The register file contains 32 registers, each 32 bits wide. 
// =======================================================================

module reg_file (
    input  wire        clk,
    input  wire        rst_n,

    // Read port 1
    input  wire [4:0]  rs1_addr,
    output wire [31:0] rd1_data,

    // Read port 2
    input  wire [4:0]  rs2_addr,
    output wire [31:0] rd2_data,

    // Write port
    input  wire [4:0]  rd_addr,
    input  wire [31:0] wr_data,
    input  wire        wr_en
);

    reg [31:0] regs [1:31];   // x1–x31 (x0 omitted — always 0)

    integer i;
    always @(posedge clk) begin
        if (!rst_n) begin
            for (i = 1; i < 32; i = i + 1)
                regs[i] <= 32'b0;
        end else if (wr_en && rd_addr != 5'd0) begin
            regs[rd_addr] <= wr_data;
        end
    end

    assign rd1_data = (rs1_addr == 5'd0) ? 32'b0 : regs[rs1_addr];
    assign rd2_data = (rs2_addr == 5'd0) ? 32'b0 : regs[rs2_addr];

endmodule