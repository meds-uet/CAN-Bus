// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: A SystemVerilog testbench designed to verify the functionality of the can_bit_destuffer module.
// It ensures the module correctly detects and flags the stuffed bit (6th identical bit) inserted 
// during transmission, enabling proper CAN frame de-stuffing on the receiver side.
//
// Author: Nimrajavaid
// Date: 01-Aug-2025
`timescale 1ns / 10ps

module tb_can_bit_destuffer;

  logic clk;
  logic rst_n;
  logic bit_in;
  logic sample_point;
  logic bit_out;
  logic remove_flag;

  can_bit_destuffer uut (
    .clk(clk),
    .rst_n(rst_n),
    .bit_in(bit_in),
    .sample_point(sample_point),
    .bit_out(bit_out),
    .remove_flag(remove_flag)
  );

  // Clock generation: 10ns period
  always #5 clk = ~clk;

  // Task to send one bit
  task send_bit(input logic b);
    begin
      bit_in = b;
      sample_point = 1;
      #10;
      sample_point = 0;
      #10;
    end
  endtask

  initial begin
    $display("=== Starting CAN Bit Destuffer Test ===");
    clk = 0;
    rst_n = 0;
    bit_in = 0;
    sample_point = 0;
    #20;
    rst_n = 1;

    // === Test Case 1: 5 consecutive 1s followed by stuffed 1 ===
    $display("\nTest 1: Expect remove_flag after 5 consecutive 1s and 6th stuffed 1");
    repeat (5) send_bit(1);   // same bits
    send_bit(1);              // stuffed bit (should be flagged)
    $display("remove_flag = %b (expected: 1)", remove_flag);

    // === Test Case 2: Alternating bits ===
    $display("\nTest 2: Alternating bits, expect no remove_flag");
    send_bit(0);
    send_bit(1);
    send_bit(0);
    send_bit(1);
    send_bit(0);
    $display("remove_flag = %b (expected: 0)", remove_flag);

    // === Test Case 3: 5 consecutive 0s followed by stuffed 0 ===
    $display("\nTest 3: Expect remove_flag after 5 consecutive 0s and 6th stuffed 0");
    repeat (5) send_bit(0);   // same bits
    send_bit(0);              // stuffed bit (should be flagged)
    $display("remove_flag = %b (expected: 1)", remove_flag);

    #20;
    $display("\n=== Finished CAN Bit Destuffer Test ===");
    $finish;
  end

endmodule
