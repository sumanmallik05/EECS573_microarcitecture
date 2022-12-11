// vim: expandtab tabstop=3 softtabstop=3 shiftwidth=3
//
// Xbar column
`include "generic_xbar_params.sv"

module switch_m #(
   parameter XDATA_SIZE = `DATA
)(
   input       [1:0][XDATA_SIZE-1:0]            in,
   input                                        switch,
   output      [1:0][XDATA_SIZE-1:0]            out
);

assign out[0] = switch==1'b0 ? in[0] : in[1];
assign out[1] = switch==1'b1 ? in[0] : in[1];

endmodule

module column_left #(
   parameter XREQ_SIZE = `XBOT,
   parameter XDATA_SIZE = `DATA
)(
   input        [XREQ_SIZE-1:0][XDATA_SIZE-1:0] in,
   input        [XREQ_SIZE/2-1:0]               switch_sel,
   output logic [XREQ_SIZE-1:0][XDATA_SIZE-1:0] out
);
/* select */
wire [XREQ_SIZE-1:0][XDATA_SIZE-1:0] rea_data;
switch_m #(.XDATA_SIZE(XDATA_SIZE))
   data_s[XREQ_SIZE/2-1:0] (
      .in         (in),
      .switch     (switch_sel),
      .out        (rea_data)
);

/* rearrange data */
genvar i;
generate 
   for (i = 0; i < XREQ_SIZE/2; ++i) begin
      assign out[i] = rea_data[i*2];
      assign out[i+XREQ_SIZE/2] = rea_data[i*2+1];
   end
endgenerate


endmodule


module column_right #(
   parameter XREQ_SIZE = `XBOT,
   parameter XDATA_SIZE = `DATA
)(
   input        [XREQ_SIZE-1:0][XDATA_SIZE-1:0] in,
   input        [XREQ_SIZE/2-1:0]               switch_sel,
   output logic [XREQ_SIZE-1:0][XDATA_SIZE-1:0] out
);
/* select */
wire [XREQ_SIZE-1:0][XDATA_SIZE-1:0] rea_data;

switch_m #(.XDATA_SIZE(XDATA_SIZE))
   data_s[XREQ_SIZE/2-1:0] (
      .in         (in),
      .switch     (switch_sel),
      .out        (rea_data)
);

/* rearrange data */
genvar i;
generate 
   for (i = 0; i < XREQ_SIZE/2; ++i) begin
      assign out[i*2] = rea_data[i];
      assign out[i*2+1] = rea_data[i+XREQ_SIZE/2];
   end
endgenerate


endmodule
