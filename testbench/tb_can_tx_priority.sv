`timescale 1ns/1ps

module tb_can_tx_priority;

  // Parameters
  localparam N = 4;

  // DUT signals
  logic clk;
  logic rst;

  logic        we;
  logic [10:0] req_id;
  logic [3:0]  req_dlc;
  logic [7:0]  req_data [0:7];

  logic        re;
  logic        start_tx;
  logic [10:0] tx_id;
  logic [3:0]  tx_dlc;
  logic [7:0]  tx_data [0:7];
  logic        full;
  logic        empty;

  // DUT instantiation
  can_tx_priority #(.N(N)) dut (
    .clk(clk),
    .rst(rst),
    .we(we),
    .req_id(req_id),
    .req_dlc(req_dlc),
    .req_data(req_data),
    .re(re),
    .start_tx(start_tx),
    .tx_id(tx_id),
    .tx_dlc(tx_dlc),
    .tx_data(tx_data),
    .full(full),
    .empty(empty)
  );

  // Clock generator
  initial clk = 0;
  always #5 clk = ~clk; // 100 MHz clock

  // Task: write a frame
  task write_frame(input [10:0] id, input [3:0] dlc);
    begin
      @(posedge clk);
      we     = 1;
      req_id = id;
      req_dlc= dlc;
      for (int i = 0; i < 8; i++) begin
        req_data[i] = i;
      end
      @(posedge clk);
      we = 0;
    end
  endtask

  // Task: read a frame (acknowledge TX done)
  task read_frame;
    begin
      @(posedge clk);
      re = 1;
      @(posedge clk);
      re = 0;
    end
  endtask

  // Test sequence
  initial begin
    // Initialize
    we = 0;
    re = 0;
    req_id = 0;
    req_dlc = 0;
    for (int i=0; i<8; i++) req_data[i] = 0;

    // Apply reset
    rst = 1;
    repeat (2) @(posedge clk);
    rst = 0;
    $display("[%0t] Reset deasserted", $time);

    // Write some frames
    write_frame(11'h300, 4'h8); // ID=0x300
    write_frame(11'h200, 4'h8); // ID=0x200 (higher priority)
    write_frame(11'h100, 4'h8); // ID=0x100 (highest priority)
    write_frame(11'h400, 4'h8); // ID=0x400 (lowest priority)

    // Observe TX
    repeat (2) @(posedge clk);
    $display("[%0t] TX: start=%0b id=%h dlc=%0d", $time, start_tx, tx_id, tx_dlc);

    // Acknowledge first TX
    read_frame();
    $display("[%0t] After read: TX id=%h", $time, tx_id);

    read_frame();
    $display("[%0t] After read: TX id=%h", $time, tx_id);

    read_frame();
    $display("[%0t] After read: TX id=%h", $time, tx_id);

    read_frame();
    $display("[%0t] After read: TX id=%h", $time, tx_id);

    // Done
    #50;
    $finish;
  end

endmodule
