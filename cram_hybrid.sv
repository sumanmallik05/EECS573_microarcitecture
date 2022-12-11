// vim: expandtab tabstop=3 softtabstop=3 shiftwidth=3
//
// Unidirectional crossbar

`timescale 1ns/1ps
`include "generic_xbar_params.sv"

module cram_hybrid #(
   parameter TCQ       = 1,
   parameter XREQ_SIZE = `XBOT,
   parameter XDATA_SIZE = `DATA,
   parameter LOG_XREQ_SIZE = `LOG_REQ,
   parameter PIPE_SIZE = 2

   // parameter XREQ_SIZE = 32,
   // parameter XDATA_SIZE = 128,
   // parameter LOG_XREQ_SIZE = 5,

)(
   input                                                 clk,
   input                                                 rst,
   input          [2*LOG_XREQ_SIZE-2:0][XREQ_SIZE/2-1:0]  sel,
   input          [XREQ_SIZE-1:0][XDATA_SIZE-1:0]        in,
   output         [XREQ_SIZE-1:0][XDATA_SIZE-1:0]        out
);

/* generate column_hybrid */
logic [LOG_XREQ_SIZE-1:0][XREQ_SIZE-1:0][XDATA_SIZE-1:0] left_col_data_in;
logic [LOG_XREQ_SIZE-1:0][XREQ_SIZE-1:0][XDATA_SIZE-1:0] left_col_data_out;
logic [LOG_XREQ_SIZE-1:0][XREQ_SIZE-1:0][XDATA_SIZE-1:0] right_col_data_in;
logic [LOG_XREQ_SIZE-1:0][XREQ_SIZE-1:0][XDATA_SIZE-1:0] right_col_data_out;

assign left_col_data_in[0] = in;
assign right_col_data_in[0] = left_col_data_in[LOG_XREQ_SIZE-1];


//logic [LOG_XREQ_SIZE-1:0][XREQ_SIZE-1:0][XDATA_SIZE-1:0] temp_reg;

genvar i;
generate;
   for(i=0; i<LOG_XREQ_SIZE-1; ++i) begin
      localparam n = 2**i;
      column_left #(
         .XREQ_SIZE(XREQ_SIZE/n),
         .XDATA_SIZE(XDATA_SIZE)
      ) left_col[n-1:0] (
         .in         (left_col_data_in[i]),
         .switch_sel (sel[i]),
         .out        (left_col_data_out[i])
      );

         always_ff @(posedge clk) begin
            if (rst) begin
               left_col_data_in[i+1] <= #TCQ 0;
            end else begin
               left_col_data_in[i+1] <= #TCQ left_col_data_out[i];
            end
         end

   end
endgenerate

generate
   for(i=0; i<LOG_XREQ_SIZE-1; ++i) begin
      localparam n = 2**(LOG_XREQ_SIZE-i-2);
      column_right #(
         .XREQ_SIZE(XREQ_SIZE/n),
         .XDATA_SIZE(XDATA_SIZE)
      ) right_col[n-1:0] (
         .in         (right_col_data_in[i]),
         .switch_sel (sel[i+LOG_XREQ_SIZE-1]),
         .out        (right_col_data_out[i])
      );

         always_ff @(posedge clk) begin
            if (rst) begin
               right_col_data_in[i+1] <= #TCQ 0;
            end else begin
               right_col_data_in[i+1] <= #TCQ right_col_data_out[i];
            end
         end

   end
endgenerate

switch_m #(.XDATA_SIZE(XDATA_SIZE))
   last_col[XREQ_SIZE/2-1:0](
   .in         (right_col_data_in[LOG_XREQ_SIZE-1]),
   .switch     (sel[2*LOG_XREQ_SIZE-2]),
   .out        (out)
);

endmodule

