// =======================================================================
// Module:      Fetch Unit
// Project:     Ripple-32
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

// TODO: add internal regs/wires

// TODO: add reset and fetch behaviour
    
endmodule