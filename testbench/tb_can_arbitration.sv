// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0

// Description:  Verifies arbitration loss detection under various scenarios by simulating CAN bus behavior.

// Author: Ayesha Qadir
// Date: 21 July, 2025
`timescale 1ns / 1ps

module tb_can_arbitration;

  // Inputs
  logic clk;
  logic rst_n;
  logic tx_bit;
  logic rx_bit;
  logic sample_point;
  logic arbitration_active;

  // Output
  logic arbitration_lost;

  // Instantiate DUT
  can_arbitration dut (
    .clk(clk),
    .rst_n(rst_n),
    .tx_bit(tx_bit),
    .rx_bit(rx_bit),
    .sample_point(sample_point),
    .arbitration_active(arbitration_active),
    .arbitration_lost(arbitration_lost)
  );

  // Clock generator: 10ns period
  initial clk = 0;
  always #5 clk = ~clk;

  // Stimulus
  initial begin
    $display("Starting CAN Arbitration Testbench");
    $dumpfile("tb_can_arbitration.vcd");  // For waveform viewing (optional)
    $dumpvars(0, tb_can_arbitration);

    // Initial values
    rst_n = 0;
    tx_bit = 1;
    rx_bit = 1;
    sample_point = 0;
    arbitration_active = 0;

    // Apply reset
    #10;
    rst_n = 1;

    // Case 1: No arbitration active => arbitration_lost should remain 0
    arbitration_active = 0;
    sample_point = 1;
    tx_bit = 1;
    rx_bit = 0;
    #10;
    assert(arbitration_lost == 0) else $fatal("FAIL: arbitration_lost triggered without arbitration_active");

    // Case 2: Arbitration active, but tx == rx => should NOT lose
    arbitration_active = 1;
    tx_bit = 0;
    rx_bit = 0;
    #10;
    sample_point = 1;
    #10;
    sample_point = 0;
    assert(arbitration_lost == 0) else $fatal("FAIL: arbitration_lost triggered when tx == rx");

    // Case 3: Arbitration active, tx=1, rx=0 => LOSS
    tx_bit = 1;
    rx_bit = 0;
    sample_point = 1;
    #10;
    sample_point = 0;
    assert(arbitration_lost == 1) else $fatal("FAIL: arbitration_lost not triggered on loss");

    // Case 4: End arbitration => loss should clear
    arbitration_active = 0;
    #10;
    assert(arbitration_lost == 0) else $fatal("FAIL: arbitration_lost did not reset");

    // Case 5: Another loss again (to test re-trigger)
    arbitration_active = 1;
    tx_bit = 1;
    rx_bit = 0;
    sample_point = 1;
    #10;
    assert(arbitration_lost == 1) else $fatal("FAIL: arbitration_lost not triggered again");

    $display("All test cases passed!");
    #10 $finish;
  end

endmodule
