// sample buffer
module sample_buffer # (
  parameter int BUFFER_DEPTH = 1024
)(
  input wire clk, reset,
  Axis_If.Master_Full data_out, // packed pair of samples
  Axis_If.Slave_Simple phase_inc_in,
  input wire capture//, // trigger capture of samples in buffer
  //output logic [21:0] debug
);

Axis_If #(.DWIDTH(4*18)) data_in();

assign data_in.ready = 1'b1; // always accept data; we might lose something at some point, but this should work fine

// buffer and trigger logic
enum bit[1:0] {IDLE=1, CAPTURE=2, TRANSFER=3} state;
logic [63:0] buffer [BUFFER_DEPTH];
logic [$clog2(BUFFER_DEPTH)-1:0] write_addr, read_addr;
logic capture_d;
logic [63:0] buffer_data_in;

//assign debug = {state, write_addr, read_addr};

always @(posedge clk) begin
  if (reset) begin
    state <= IDLE;
  end else begin
    unique case (state)
      IDLE: if (capture && !capture_d) state <= CAPTURE;
      CAPTURE: if (write_addr == {$clog2(BUFFER_DEPTH){1'b1}}) state <= TRANSFER;
      TRANSFER: if (read_addr == {$clog2(BUFFER_DEPTH){1'b1}}) state <= IDLE;
    endcase
  end
end

always @(posedge clk) begin
  capture_d <= capture;
  // this is wrong
  data_out.last <= (read_addr == {$clog2(BUFFER_DEPTH){1'b1}});
  if (reset) begin
    write_addr <= '0;
    read_addr <= '0;
    data_out.valid <= 1'b0;
  end else begin
    unique case (state)
      IDLE: begin
        write_addr <= '0;
        read_addr <= '0;
        data_out.valid <= 1'b0;
      end
      CAPTURE: begin
        data_out.valid <= 1'b0;
        if (data_in.valid) begin
          buffer[write_addr] <= buffer_data_in;
          write_addr <= write_addr + 1'b1;
        end
      end
      TRANSFER: begin
        if (data_out.ready) begin
          data_out.valid <= 1'b1;
          data_out.data <= buffer[read_addr];
          read_addr <= read_addr + 1'b1;
        end
      end
    endcase
  end
end


// lfsr to model noise
logic [15:0] lfsr;
lfsr16 lfsr_i (
  .clk,
  .reset,
  .enable(1'b1),
  .data_out(lfsr)
);

// buffer input
always @(posedge clk) begin
  buffer_data_in <= {data_in.data[4*18-1-:16], data_in.data[3*18-1-:16], data_in.data[2*18-1-:16], data_in.data[17-:16]};
end

dds #(.PHASE_BITS(24), .OUTPUT_WIDTH(18), .QUANT_BITS(12), .PARALLEL_SAMPLES(4)) dds_i (
  .clk,
  .reset,
  .cos_out(data_in),
  .phase_inc_in
);

endmodule

// wrapper so this can be instantiated in .v file
module sample_buffer_w (
  input wire clk, reset,
  output [63:0] data_out,
  output data_out_valid, data_out_last,
  input data_out_ready,
  input [23:0] phase_inc_in,
  input phase_inc_in_valid,
  output phase_inc_in_ready,
  input wire capture//,
  //output logic [21:0] debug
);

Axis_If #(.DWIDTH(24)) phase_inc_in_if();
Axis_If #(.DWIDTH(64)) data_out_if();

sample_buffer #(.BUFFER_DEPTH(32768)) buffer_i (
  .clk,
  .reset,
  .data_out(data_out_if),
  .phase_inc_in(phase_inc_in_if),
  .capture
  //.debug
);

assign data_out = data_out_if.data;
assign data_out_valid = data_out_if.valid;
assign data_out_last = data_out_if.last;
assign data_out_if.ready = data_out_ready;

assign phase_inc_in_if.data = phase_inc_in;
assign phase_inc_in_if.valid = phase_inc_in_valid;
assign phase_inc_in_ready = phase_inc_in_if.ready;
assign phase_inc_in_if.last = 1'b0; // this isn't connected, but we can tie it low to suppress the warning

endmodule
