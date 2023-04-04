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

localparam int N_FREQS = 4;
localparam int N_SAMP_PER_FREQ = 2**14;
int freqs [N_FREQS] = {12_130_000, 517_036_000, 1_729_725_000, 2_759_000};

logic [OUTPUT_WIDTH-1:0] cos_vector [N_FREQS*N_SAMP_PER_FREQ];
logic [PHASE_BITS-1:0] phi_vector [N_FREQS*N_SAMP_PER_FREQ];
logic [PHASE_BITS-1:0] phi_vector_output, phi_vector_output_d;
logic [OUTPUT_WIDTH-1:0] cos_vector_output, cos_vector_output_d;
int vector_index;

always @(posedge clk) begin
  cos_vector_output <= cos_vector[vector_index];
  cos_vector_output_d <= cos_vector_output;
  phi_vector_output_d <= phi_vector_output;
end
assign phi_vector_output = phi_vector[vector_index];


initial begin
  $readmemh("lfsr_dithered_cos.mem", cos_vector);
  $readmemh("lfsr_dithered_phase.mem", phi_vector);
  reset <= 1'b1;
  vector_index <= 0;
  repeat (50) @(posedge clk);
  reset <= 1'b0;
  //repeat (100) @(posedge clk);
  for (int i = 0; i < N_FREQS; i = i + 1) begin
    phase_inc_in.data <= unsigned'(int'($floor((real'(freqs[i])/6_400_000_000.0) * (2**(PHASE_BITS)))));
    phase_inc_in.valid <= 1;
    vector_index <= i*N_SAMP_PER_FREQ;
    repeat (1) @(posedge clk);
    //if (i == 0) begin
    //  repeat (2) @(posedge clk);
    //end else begin
    //  repeat (1) @(posedge clk);
    //end
    vector_index <= vector_index + 1;
    phase_inc_in.valid <= 0;
    repeat (N_SAMP_PER_FREQ-1) begin
      @(posedge clk);
      vector_index <= vector_index + 1;
    end
  end
  $finish;
end

endmodule
