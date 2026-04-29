// =======================================================================
// Module: Fetch Unit
// Project: Ripple-32
// Description: The fetch unit will fetch an instruction from the address
//              supplied to it, then stall the core until the fetch completes
// =======================================================================

module fetch_unit #(
    parameter BOOT_ADDR = 32'h0000_0000
) (
    // Clock and reset
    input wire        clk,
    input wire        rst_n,

    // Address input from PC
    input wire [31:0] fetch_addr_in,

    // Register-configured timeout value
    input wire [7:0]  stall_timeout_val,

    // Generic fetch-side interface inputs
    input wire        bus_if_busy,
    input wire        bus_if_done,
    input wire [31:0] instr_data_in,

    // Fetch Unit outputs
    output reg [31:0] ifu_instr_addr,
    output reg [31:0] instr_data_out,
    output reg        if_ready,
    output reg        if_stall,
    output reg        instr_valid,
    output reg        if_err,
    output reg        stall_err
);

//  internal state
    reg       fetch_active;
    reg       [7:0] stall_count;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ifu_instr_addr <= BOOT_ADDR;
            instr_data_out <= 32'b0;
            if_ready       <= 1'b0;
            if_stall       <= 1'b0;
            instr_valid    <= 1'b0;
            if_err         <= 1'b0;
            stall_err      <= 1'b0;
            fetch_active   <= 1'b0;
            stall_count    <= 8'b0;
        end
        else begin
            if_ready    <= 1'b0;
            instr_valid <= 1'b0;

            if (!fetch_active && !bus_if_busy && !stall_err) begin
                ifu_instr_addr <= fetch_addr_in;
                if_ready       <= 1'b1;
                if_stall       <= 1'b1;
                fetch_active   <= 1'b1;
                stall_count    <= 8'b0;
            end

            else if (fetch_active) begin
                if (bus_if_done) begin
                    instr_data_out <= instr_data_in;
                    instr_valid    <= 1'b1;
                    if_stall       <= 1'b0;
                    fetch_active   <= 1'b0;
                    stall_count    <= 8'b0;
                    if_err         <= 1'b0;
                end
                else begin
                    stall_count <= stall_count + 1'b1;
                    if (stall_count + 1'b1 >= stall_timeout_val) begin
                        stall_err    <= 1'b1;
                        if_err       <= 1'b1;
                        if_stall     <= 1'b1;
                        fetch_active <= 1'b0;
                    end
                end
            end
        end
    end

endmodule