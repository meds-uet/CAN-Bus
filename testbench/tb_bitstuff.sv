// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: 
// A SystemVerilog testbench designed to verify the functionality of the can_bit_stuffer module.
// It checks whether the module correctly inserts a complementary stuff bit after five consecutive 
// identical bits (either 0 or 1) as per CAN protocol requirements.
//
// Author: Nimrajavaid
// Date: 01-August-2025

`timescale 1ns / 10ps

module tb_can_bit_stuffer;

  logic clk;
  logic rst_n;
  logic bit_in;
  logic sample_point;
  logic bit_out;
  logic stuff_inserted;

  // DUT Instance
  can_bit_stuffer uut (
    .clk(clk),
    .rst_n(rst_n),
    .bit_in(bit_in),
    .sample_point(sample_point),
    .bit_out(bit_out),
    .stuff_inserted(stuff_inserted)
  );

  // Clock generation: 10ns period
  always #5 clk = ~clk;

  // Task to send a bit and show result
  task send_bit(input logic b);
    begin
      bit_in = b;
      sample_point = 1;
      #10; // Sample at positive edge
      sample_point = 0;
      #10;

      $display("Time: %0t | Sent: %b | Out: %b | Stuff Inserted: %b",
                $time, b, bit_out, stuff_inserted);
    end
  endtask

  initial begin
    $display("=== Starting CAN Bit Stuffer Test ===");

    // VCD setup
    $dumpfile("can_bit_stuffer.vcd");
    $dumpvars(0, tb_can_bit_stuffer);

    // Init
    clk = 0;
    rst_n = 0;
    bit_in = 0;
    sample_point = 0;
    #20;
    rst_n = 1;

    // === Test 1: 5 consecutive 1s ===
    $display("\nTest 1: 5 consecutive 1s, expect stuffing after 5th");
    send_bit(1); //1
    send_bit(1); //2
    send_bit(1); //3
    send_bit(1); //4
    send_bit(1); //5 -> after this, stuff should be inserted
    send_bit(1); //6 input, but output should be 0 (stuffed)

    // === Test 2: Alternating bits (no stuffing) ===
    $display("\nTest 2: Alternating bits, no stuffing expected");
    send_bit(0);
    send_bit(1);
    send_bit(0);
    send_bit(1);

    // === Test 3: 5 consecutive 0s ===
    $display("\nTest 3: 5 consecutive 0s, expect stuffing after 5th");
    send_bit(0); //1
    send_bit(0); //2
    send_bit(0); //3
    send_bit(0); //4
    send_bit(0); //5 -> stuff should occur
    send_bit(0); //6 input, but output should be 1 (stuffed)

    #50;

    $display("\n=== Finished CAN Bit Stuffer Test ===");
    $finish;
  end

endmodule
