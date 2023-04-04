`timescale 1ns / 1ps
module dds_test ();

logic clk = 0;
localparam CLK_RATE_HZ = 100_000_000;
always #(0.5s/CLK_RATE_HZ) clk = ~clk;

logic reset;

localparam PHASE_BITS = 24;
localparam OUTPUT_WIDTH = 18;
localparam QUANT_BITS = 8;

Axis_If #(.DWIDTH(PHASE_BITS)) phase_inc_in();
Axis_If #(.DWIDTH(OUTPUT_WIDTH)) cos_out();

dds #(.PHASE_BITS(PHASE_BITS), .OUTPUT_WIDTH(OUTPUT_WIDTH), .QUANT_BITS(QUANT_BITS)) dut_i (
  .clk,
  .reset,
  .cos_out,
  .phase_inc_in
);

initial begin
  reset = 1'b1;
  repeat (50) @(posedge clk);
  reset = 1'b0;
  repeat (100) @(posedge clk);
  phase_inc_in.data = 16384;
  phase_inc_in.valid = 1;
  @(posedge clk);
  phase_inc_in.valid = 0;
  repeat (10000) @(posedge clk);
  phase_inc_in.data = 1723456;
  phase_inc_in.valid = 1;
  @(posedge clk);
  phase_inc_in.valid = 0;
  repeat (10000) @(posedge clk);
  $finish;
end

endmodule
