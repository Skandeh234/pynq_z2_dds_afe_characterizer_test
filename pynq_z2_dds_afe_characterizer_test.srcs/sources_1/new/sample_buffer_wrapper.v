module sample_buffer_wrapper (
  input wire clk, reset_n,
  output [63:0] data_out,
  output data_out_valid, data_out_last,
  input data_out_ready,
  input [31:0] data_in,
  input data_in_valid,
  output data_in_ready,
  input wire capture,
  output wire [21:0] debug
);

sample_buffer_w buffer_i (
  .clk(clk),
  .reset(~reset_n),
  .data_out(data_out),
  .data_out_valid(data_out_valid),
  .data_out_last(data_out_last),
  .data_out_ready(data_out_ready),
  .data_in(data_in),
  .data_in_valid(data_in_valid),
  .data_in_ready(data_in_ready),
  .capture(capture),
  .debug(debug)
);

endmodule
