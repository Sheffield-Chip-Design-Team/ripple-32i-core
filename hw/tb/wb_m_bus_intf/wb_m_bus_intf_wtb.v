// Auto-generated Verilog Testbench Wrapper - Coraltb 
 
`timescale 1ns/1ns 


module wb_m_bus_intf_wtb;

  // wb_m_bus_intf instantation signals
  reg   clk;
  reg   rst_n;
  reg  [31:0] w_data;
  wire [31:0] r_data;
  reg   addr;
  reg   we;
  reg   en;
  wire  valid;
  wire [31:0] adr_o;
  wire [31:0] dat_o;
  reg  [31:0] dat_i;
  wire  we_o;
  wire [3:0] sel_o;
  wire  stb_o;
  wire  cyc_o;
  reg   ack_i;

wb_m_bus_intf dut (
      .clk(clk),
      .rst_n(rst_n),
      .w_data(w_data),
      .r_data(r_data),
      .addr(addr),
      .we(we),
      .en(en),
      .valid(valid),
      .adr_o(adr_o),
      .dat_o(dat_o),
      .dat_i(dat_i),
      .we_o(we_o),
      .sel_o(sel_o),
      .stb_o(stb_o),
      .cyc_o(cyc_o),
      .ack_i(ack_i)
  );

endmodule 
 