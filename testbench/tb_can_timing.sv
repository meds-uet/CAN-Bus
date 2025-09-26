`timescale 1ns/1ps
`include "can_defs.svh"

module tb_can_timing;

  // Clock & reset
  logic clk;
  logic rst_n;

  // DUT inputs
  logic go_error_frame, go_overload_frame, send_ack;
  logic rx, tx, tx_next;
  logic transmitting, transmitter;
  logic rx_idle, rx_inter, go_tx;
  logic node_error_passive;

  type_reg2tim_s reg2tim_i;

  // DUT outputs
  logic sample_point;
  logic sampled_bit;
  logic sampled_bit_q;
  logic tx_point;
  logic hard_sync;

  // Instantiate DUT
  can_timing dut (
    .rst_n(rst_n),
    .clk(clk),
    .go_error_frame(go_error_frame),
    .go_overload_frame(go_overload_frame),
    .send_ack(send_ack),
    .rx(rx),
    .tx(tx),
    .tx_next(tx_next),
    .transmitting(transmitting),
    .transmitter(transmitter),
    .rx_idle(rx_idle),
    .rx_inter(rx_inter),
    .go_tx(go_tx),
    .node_error_passive(node_error_passive),
    .reg2tim_i(reg2tim_i),
    .sample_point(sample_point),
    .sampled_bit(sampled_bit),
    .sampled_bit_q(sampled_bit_q),
    .tx_point(tx_point),
    .hard_sync(hard_sync)
  );

  // Clock generation
  always #5 clk = ~clk;  // 100 MHz

  // Stimulus
  initial begin
    // Default
    clk = 0;
    rst_n = 0;
    go_error_frame = 0;
    go_overload_frame = 0;
    send_ack = 0;
    rx = 1; // recessive (bus idle)
    tx = 1;
    tx_next = 1;
    transmitting = 0;
    transmitter = 0;
    rx_idle = 1;
    rx_inter = 0;
    go_tx = 0;
    node_error_passive = 0;

    // CAN timing config
    reg2tim_i.tseg1 = 3'd4;          // 4 TQ
    reg2tim_i.tseg2 = 3'd3;          // 3 TQ
    reg2tim_i.sjw   = 3'd2;          // SJW = 2
    reg2tim_i.baud_prescaler = 8'd1; // simple baud divider

    // Reset release
    #50 rst_n = 1;

    // Wait idle
    #100;

    // 1. HARD SYNC test: Start Of Frame (SOF)
    $display("=== HARD SYNC TEST ===");
    rx_idle = 1;
    @(posedge clk);
    rx <= 0; // dominant edge = SOF
    #200;

    // 2. Normal bit sampling
    $display("=== BIT SAMPLING ===");
    repeat (10) begin
      @(posedge sample_point);
      $display("[%0t] Sampled bit = %0b", $time, sampled_bit);
    end

    // 3. RESYNC test: inject edge in middle of bit
    $display("=== RESYNC TEST ===");
    rx_idle = 0;
    rx_inter = 0;
    #100;
    rx <= 1;  // force an unexpected recessive edge
    #200;

    // 4. Drive TX
    $display("=== TX TEST ===");
    go_tx = 1;
    transmitting = 1;
    transmitter = 1;
    tx_next = 0; // send dominant
    @(posedge tx_point);
    $display("[%0t] TX_POINT asserted", $time);
    #200;

    $display("=== TEST COMPLETE ===");
    $finish;
  end

endmodule
