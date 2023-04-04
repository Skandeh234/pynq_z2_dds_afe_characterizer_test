// sample buffer
module sample_buffer # (
  parameter int BUFFER_DEPTH = 1024
)(
  input wire clk, reset,
  Axis_If.Master_Full data_out, // packed pair of samples
  Axis_If.Slave_Simple data_in,
  input wire capture, // trigger capture of samples in buffer
  output logic [21:0] debug
);

assign data_in.ready = 1'b1; // always accept data; we might lose something at some point, but this should work fine

// buffer and trigger logic
enum bit[1:0] {IDLE=1, CAPTURE=2, TRANSFER=3} state;
logic [63:0] buffer [BUFFER_DEPTH];
logic [$clog2(BUFFER_DEPTH)-1:0] write_addr, read_addr;
logic capture_d;
logic [63:0] buffer_data_in;

assign debug = {state, write_addr, read_addr};

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


// lfsr
localparam [47:0] LFSR_POLY = 48'h3A00_0050_0000;
logic [47:0] lfsr;
always @(posedge clk) begin
  if (reset) begin
    lfsr <= 48'hB82E_DC58_BFFB;
  end else begin
    lfsr <= {^(lfsr & LFSR_POLY), lfsr[47:1]};
  end
end

// buffer input
always @(posedge clk) begin
  buffer_data_in <= {data_in.data, data_in.data + lfsr[47:40]};
end


endmodule

// wrapper so this can be instantiated in .v file
module sample_buffer_w (
  input wire clk, reset,
  output [63:0] data_out,
  output data_out_valid, data_out_last,
  input data_out_ready,
  input [31:0] data_in,
  input data_in_valid,
  output data_in_ready,
  input wire capture,
  output logic [21:0] debug
);

Axis_If #(.DWIDTH(32)) data_in_if();
Axis_If #(.DWIDTH(64)) data_out_if();

sample_buffer #(.BUFFER_DEPTH(1024)) buffer_i (
  .clk,
  .reset,
  .data_out(data_out_if),
  .data_in(data_in_if),
  .capture,
  .debug
);

assign data_out = data_out_if.data;
assign data_out_valid = data_out_if.valid;
assign data_out_last = data_out_if.last;
assign data_out_if.ready = data_out_ready;

assign data_in_if.data = data_in;
assign data_in_if.valid = data_in_valid;
assign data_in_ready = data_in_if.ready;
assign data_in_if.last = 1'b0; // this isn't connected, but we can tie it low to suppress the warning

endmodule
