// vim: expandtab tabstop=3 softtabstop=3 shiftwidth=3
//
// Crosspoint arbitration
`include "generic_xbar_params.sv"

module priority_alg #(
   parameter XREQ_SIZE = `XBOT
)(
   input                           clock,
   input                           reset,
   input          [XREQ_SIZE-1:0]  req,
   input          [XREQ_SIZE-1:0]  rel,
   output logic   [XREQ_SIZE-1:0]  response
);
logic [XREQ_SIZE-1:0][XREQ_SIZE-1:0] local_priority;
logic [XREQ_SIZE-1:0][XREQ_SIZE-1:0] next_priority;
logic [XREQ_SIZE-1:0][XREQ_SIZE-1:0] actual_priority;
logic [XREQ_SIZE-1:0][XREQ_SIZE-1:0] default_priority;

logic [XREQ_SIZE-1:0] winner;
logic [XREQ_SIZE-1:0] next_winner;

// Our FPGA targets don't support wor/wand datatypes.
// We perform the wor equivalent explicitly if an FPGA target is specified.
// Could probably just get rid of the WOR altogether.
`ifdef USE_WOR_FPGA
   logic [XREQ_SIZE-1:0] or_priority;
`else
   wor   [XREQ_SIZE-1:0] or_priority;
`endif
logic won;

// wired-or on arb. priority
`ifdef USE_WOR_FPGA
   assign default_priority = (XREQ_SIZE == 2) ? 4'h4 :
                             (XREQ_SIZE == 4) ? 16'h7310 :
                             1 ; // illegal - only support XREQ_SIZE = 2 or 4 in FPGA
`else
   assign default_priority[0] = 0;
   generate
      for (genvar j = 1; j < XREQ_SIZE; ++j) begin
         assign default_priority[j] = (1 << (j-1)) + default_priority[j-1];
      end
   endgenerate
`endif

`ifdef USE_WOR_FPGA
   always_comb begin
      or_priority = 0;
      for (int j = 0; j < XREQ_SIZE; ++j) begin
         or_priority = or_priority | actual_priority[j];
      end
   end
`else
   generate
      for (genvar j = 0; j < XREQ_SIZE; ++j) begin
         assign or_priority = actual_priority[j];
      end
   endgenerate
`endif

assign response = winner;

always_comb begin
   next_priority = local_priority;
   next_winner = winner;
   won = 0;

   for (int i = 0; i < XREQ_SIZE; ++i) begin
      actual_priority[i] = req[i] ? local_priority[i] : 0;
   end

   if ((winner == 0) || |(winner & rel)) begin
      won = |(~or_priority & req);
   end
   if (won) begin
      for (int i = 0; i < XREQ_SIZE; ++i) begin
         if (~or_priority[i] & req[i]) begin
            next_winner[i] = 1;
         end else begin
            next_winner[i] = 0;
         end
      end
      for (int i = 0; i < XREQ_SIZE; ++i) begin
         if (~or_priority[i] & req[i]) begin
            next_priority[i] = 0;
         end else begin
            next_priority[i] = local_priority[i] | next_winner;
         end
      end
   end else if (|(winner & rel)) begin
      next_winner = 0;
   end
end

always_ff @(posedge clock or posedge reset) begin
   if (reset) begin
      local_priority <= default_priority;
      winner <= 0;
   end else begin
      local_priority <= next_priority;
      winner <= next_winner;
   end
end

endmodule
