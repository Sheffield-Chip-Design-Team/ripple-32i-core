// =======================================================================
// Module:      Ripple-32 Core Top
// Project:     Ripple-32
// Description: The top-level module for the Ripple-32i core.
// =======================================================================

module ripple_32i_core_top (
  // Clock and Reset
  input  wire           clk,        
  input  wire           rst_n,      
    
  // JTAG Debug interface
  input                 tck,
  input                 tms,
  input                 tdi,
  output                tdo,

  // core halt signal (for debugging)
  input wire            halt,

  // Instruction bus (Wishbone Master Interface)
  output wire [31:0] i_adr_o,
  input  wire [31:0] i_dat_i,
  output wire        i_stb_o,
  output wire [3:0]  i_sel_o,
  output wire        i_cyc_o,
  input  wire        i_ack_i,

  // Data bus (Wishbone Master interface)
  output wire [31:0] d_adr_o,
  output wire [31:0] d_dat_o,
  input  wire [31:0] d_dat_i,
  output wire        d_we_o,
  output wire [3:0]  d_sel_o,
  output wire        d_stb_o,
  output wire        d_cyc_o,
  input  wire        d_ack_i
 
);

// ---------------------------------------------------
// Internal Signals
// ---------------------------------------------------




// ---------------------------------------------------
// Fetch
// ---------------------------------------------------

  ripple_wishbone_bridge u_instruction_fetch (
    .clk(clk),
    .rst_n(rst_n),
    
    // generic memory interface 
    .r_data(),
    .addr(),
    .en(),             // Enable when strobe is active
    .valid(),          // Valid when acknowledgment is received
    
    // Wishbone Master interface
    .adr_o(i_adr_o),
    .dat_i(i_dat_i),
    .stb_o(i_stb_o), 
    .sel_o(i_sel_o),   
    .cyc_o(i_cyc_o),
    .ack_i(i_ack_i),

    // For instruction fetch, we don't need to write data, so we can tie these signals off
    .dat_o(),        
    .w_data(32'b0),     // No writes for instruction fetch
    .we_o(1'b0),        // No writes for instruction fetch
    .we(1'b0)           // writing is disabled for instruction fetch
  );

// ---------------------------------------------------
// Decode 
// ---------------------------------------------------



// ---------------------------------------------------
// Execute
// ---------------------------------------------------



// ---------------------------------------------------
// Memory Access
// ---------------------------------------------------



// ---------------------------------------------------
// Write Back
// ---------------------------------------------------





endmodule