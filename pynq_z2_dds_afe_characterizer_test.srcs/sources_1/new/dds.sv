module dds #(
  parameter int PHASE_BITS = 24,
  parameter int OUTPUT_WIDTH = 18,
  parameter int QUANT_BITS = 8
) (
  input wire clk, reset,
  Axis_If.Master_Simple cos_out,
  Axis_If.Slave_Simple phase_inc_in
);


localparam int LUT_ADDR_BITS = PHASE_BITS - QUANT_BITS;
localparam int LUT_DEPTH = 2**LUT_ADDR_BITS;

logic [PHASE_BITS-1:0] phase_inc;
logic [PHASE_BITS-1:0] phase;
assign phase_inc_in.ready = 1'b1;
always @(posedge clk) begin
  if (reset) begin
    phase_inc <= '0;
    phase <= '0;
  end else begin
    if (phase_inc_in.ready && phase_inc_in.valid) begin
      phase_inc <= phase_inc_in.data;
    end
    phase <= phase + phase_inc;
  end
end

// dither LFSR
localparam [15:0] LFSR_POLY = 16'hb400;
logic [15:0] lfsr;
always @(posedge clk) begin
  if (reset) begin
    lfsr <= 16'hace1;
  end else begin
    lfsr <= ({16{lfsr[0]}} & LFSR_POLY) ^ {1'b0, lfsr[15:1]};
  end
end

logic [PHASE_BITS-1:0] phase_dithered;
generate
  if (QUANT_BITS > 16) begin
    assign phase_dithered = {lfsr, {(QUANT_BITS - 16){1'b0}}} + phase;
  end else begin
    assign phase_dithered = lfsr[QUANT_BITS-1:0] + phase;
  end
endgenerate

logic [LUT_ADDR_BITS-1:0] phase_quant;
always @(posedge clk) begin
  phase_quant <= phase_dithered[PHASE_BITS-1:QUANT_BITS];
end


localparam real PI = 3.14159265;
logic signed [OUTPUT_WIDTH-1:0] lut [LUT_DEPTH];
initial begin
  for (int i = 0; i < LUT_DEPTH; i = i + 1) begin
    lut[i] = signed'(int'($floor($cos(2*PI/(LUT_DEPTH)*i)*(2**(OUTPUT_WIDTH-1) - 0.5) - 0.5)));
  end
end

always @(posedge clk) begin
  if (reset) begin
    cos_out.valid <= 1'b0;
    cos_out.data <= '0;
  end else begin
    cos_out.valid <= 1'b1;
    cos_out.data <= lut[phase_quant];
  end
end


endmodule
