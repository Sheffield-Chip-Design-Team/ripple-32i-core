// =======================================================================
// Module:      Wishbone Bridge
// Project:     Ripple-32
// Description: The Wishbone interface module connects the core to 
//              the external interconnect and memory system using the Wishbone protocol.
// =======================================================================

module ripple_wishbone_bridge (
  input wire        clk,        
  input wire        rst_n,      

  // Ripple-32 (generic memory interface)
  input        [31:0]  w_data,
  output wire  [31:0]  r_data,  //r_data
  input  wire          addr,  
  input  wire          we,   
  input  wire          en,     
  output wire          valid,   //valid

  // Data bus (Wishbone Master interface)
  output wire [31:0] adr_o,   //addr
  output wire [31:0] dat_o,   //w_data
  input  wire [31:0] dat_i,
  output wire        we_o,    //we
  output wire [3:0]  sel_o,   //sel
  output wire        stb_o,   //en
  output wire        cyc_o,   //en
  input  wire        ack_i 
);

// TODO: Implement the Wishbone bridge logic here. 
// This will involve translating the generic memory interface signals (w_data, r_data, addr, we, sel) 
// into the appropriate Wishbone signals (d_adr_o, d_dat_o, d_we_o, d_sel_o, d_stb_o, d_cyc_o)
// and handling the acknowledgment from the Wishbone bus (d_ack_i).
   
   // 1. master set address and data
   assign adr_o = addr;
   assign dat_o = w_data;
   assign r_data = dat_i;

   // 2. master indicate write or read and select
   assign we_o = we;
   assign sel_o = 4'b1111;

   // 3. master pulls CYC and STB high
   assign stb_o = en;
   assign cyc_o = en;
   
   // 4. wait for slave set ACK high, once seen, cycle complete
   assign valid = ack_i;

endmodule