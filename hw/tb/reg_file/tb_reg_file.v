
`timescale 1ns/1ns

module reg_file_wtb;


    reg         clk;
    reg         rst_n;

    reg  [4:0]  rs1_addr;
    wire [31:0] rd1_data;


    reg  [4:0]  rs2_addr;
    wire [31:0] rd2_data;

    // Write port
    reg  [4:0]  rd_addr;
    reg  [31:0] wr_data;
    reg         wr_en;

  
    reg_file dut (
        .clk      (clk),
        .rst_n    (rst_n),
        .rs1_addr (rs1_addr),
        .rd1_data (rd1_data),
        .rs2_addr (rs2_addr),
        .rd2_data (rd2_data),
        .rd_addr  (rd_addr),
        .wr_data  (wr_data),
        .wr_en    (wr_en)
    );


    initial clk = 0;
    always #5 clk = ~clk;

endmodule