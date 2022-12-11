// vim: expandtab tabstop=3 softtabstop=3 shiftwidth=3
//
// Generic bidirection crossbar
// =========================================

`timescale 1ns/1ps

// reged requst in
// reged data_out

// no bank conflict allowed: the schduler must solve it
`include "generic_xbar_params.sv"

module generic_xbar #(
   parameter XBOT_N = `XBOT, // number of requesters
   parameter LOG_REQ_N = `LOG_REQ,
   parameter DATA_W = `DATA  // width of (generic) data signal

   // parameter XBOT_N = 32, // number of requesters
   // parameter LOG_REQ_N = 5,
   // parameter DATA_W = 128  // width of (generic) data signal
)(
   // to downstream
   output [XBOT_N-1:0][DATA_W-1:0]  data_o, // generic output data to down

   // from upstream
   input [XBOT_N-1:0][DATA_W-1:0]   data_i, // generic data bits to downstream

   // from schduler
   input [2*LOG_REQ_N-2:0][XBOT_N/2-1:0]   sel_i, 
   // misc
   input                            clk,
   input                            rst
);

reg [2*LOG_REQ_N-2:0][XBOT_N/2-1:0]   sel_reg;

/* registered request input */
always_ff @(posedge clk) begin
   if (rst) begin
      sel_reg <= 0;
   end
   else begin
      sel_reg <= sel_i;
   end
end

/* registered data output */
reg [XBOT_N-1:0][DATA_W-1:0]  data_reg;
wire [XBOT_N-1:0][DATA_W-1:0] data_cram_o;

always_ff @(posedge clk) begin
   if (rst) begin
      data_reg <= 0;
   end else begin
      data_reg <= data_cram_o;
   end
end

assign data_o = data_reg;

// Downstream arbiter instance
cram_hybrid #(
   .XREQ_SIZE     (XBOT_N),
   .XDATA_SIZE    (DATA_W),
   .LOG_XREQ_SIZE (LOG_REQ_N)
) u_cram (
   .in            (data_i),
   .sel           (sel_i),
   .clk           (clk),
   .rst           (rst),
   .out           (data_cram_o)
);


endmodule
