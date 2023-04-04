module lfsr16 (
  input wire clk, reset,
  output logic [15:0] data_out
);

localparam [15:0] LFSR_POLY = 16'hb400;
always @(posedge clk) begin
  if (reset) begin
    data_out <= 16'hace1;
  end else begin
    data_out <= ({16{data_out[0]}} & LFSR_POLY) ^ {1'b0, data_out[15:1]};
  end
end

endmodule
