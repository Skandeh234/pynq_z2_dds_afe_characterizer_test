module sample_buffer_wrapper (
  input wire clk, reset_n,
  output [127:0] data_out,
  output data_out_valid, data_out_last,
  input data_out_ready,
  input [23:0] phase_inc_in,
  input phase_inc_in_valid,
  output phase_inc_in_ready,
  input wire capture
  //output wire [21:0] debug
);

sample_buffer_w buffer_i (
  .clk(clk),
  .reset(~reset_n),
  .data_out(data_out),
  .data_out_valid(data_out_valid),
  .data_out_last(data_out_last),
  .data_out_ready(data_out_ready),
  .phase_inc_in(phase_inc_in),
  .phase_inc_in_valid(phase_inc_in_valid),
  .phase_inc_in_ready(phase_inc_in_ready),
  .capture(capture)
  //.debug(debug)
);

endmodule
