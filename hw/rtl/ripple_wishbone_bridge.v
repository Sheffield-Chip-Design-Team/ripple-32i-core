// =======================================================================
// Module:      Wishbone Bridge (Standard Verilog Version)
// Description: Converted to use reg/wire and localparam for compatibility.
// =======================================================================

module wb_m_bus_intf (
    input wire         clk,
    input wire         rst_n,

    // Ripple-32 interface
    input      [31:0]  w_data,
    output wire [31:0] r_data,
    input wire [31:0]  addr,
    input wire         we,
    input wire         en,
    output wire        valid,

    // Wishbone Master interface
    output wire [31:0] adr_o,
    output wire [31:0] dat_o,
    input  wire [31:0] dat_i,
    output wire        we_o,
    output wire [3:0]  sel_o,
    output reg         stb_o, // Changed to reg for use in always block
    output reg         cyc_o, // Changed to reg for use in always block
    input  wire        ack_i
);

    // 1. Define States using localparam instead of enum
    localparam IDLE     = 2'b00;
    localparam BUS_WAIT = 2'b01;
    localparam DONE     = 2'b10;

    reg [1:0] state;      // Using reg instead of logic
    reg [1:0] next_state;

    // 2. Simple Assignments
    assign adr_o = addr;
    assign dat_o = w_data;
    assign r_data = dat_i;
    assign we_o   = we;
    assign sel_o  = 4'b1111;
    assign valid  = ack_i;

    // 3. State Transition Logic (Sequential)
    // replaced always_ff with always @(posedge ...)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) 
            state <= IDLE;
        else 
            state <= next_state;
    end

    // 4. Next State Logic (Combinational)
    // replaced always_comb with always @(*)
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: begin
                if (en) next_state = BUS_WAIT;
            end
            BUS_WAIT: begin
                if (ack_i) next_state = IDLE;
            end
            default: next_state = IDLE;
        endcase
    end

    // 5. Output Logic for STB and CYC
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            cyc_o <= 1'b0;
            stb_o <= 1'b0;
        end else begin
            if (next_state == BUS_WAIT) begin
                cyc_o <= 1'b1;
                stb_o <= 1'b1;
            end else begin
                cyc_o <= 1'b0;
                stb_o <= 1'b0;
            end
        end
    end

endmodule