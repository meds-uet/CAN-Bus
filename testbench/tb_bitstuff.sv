// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: A SystemVerilog testbench designed to verify the functionality of the can_filtering module 
// by testing frame acceptance based on CAN identifier filtering.
//
// Author: Nimrajavaid
// Date: 22-july-2025
`timescale 1ns / 1ps
`include "can_defs.svh"

module tb_can_bitstuff;

  // Inputs
  logic clk;
  logic rst_n;
  logic bit_in;
  logic sample_point;
  logic insert_mode;

  // Outputs
  logic bit_out;
  logic insert_or_remove;

  // DUT
  can_bitstuff dut (
    .clk(clk),
    .rst_n(rst_n),
    .bit_in(bit_in),
    .sample_point(sample_point),
    .insert_mode(insert_mode),
    .bit_out(bit_out),
    .insert_or_remove(insert_or_remove)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Stimulus
  initial begin
    $display("Starting bit stuffing testbench...");
    clk = 0;
    rst_n = 0;
    bit_in = 1;
    sample_point = 0;
    insert_mode = 1;  // Start with stuffing mode

    #12 rst_n = 1;

    // Send 5 same bits to trigger stuffing
    repeat (5) begin
      @(negedge clk);
      sample_point = 1;
      bit_in = 1;
      @(negedge clk);
      sample_point = 0;
    end

    // 6th bit that should trigger stuffing
    @(negedge clk);
    sample_point = 1;
    bit_in = 1;
    @(negedge clk);
    sample_point = 0;

    // Few more bits to see normal behavior
    @(negedge clk);
    sample_point = 1;
    bit_in = 0;
    @(negedge clk);
    sample_point = 0;

    // Switch to de-stuffing mode
    insert_mode = 0;
    same_count_reset();

    // Now send alternating bits, should not trigger removal
    repeat (6) begin
      @(negedge clk);
      sample_point = 1;
      bit_in = $random % 2;
      @(negedge clk);
      sample_point = 0;
    end

    $display("Testbench completed.");
    $finish;
  end

  // Helper to reset same count between stuffing and de-stuffing
  task same_count_reset;
    begin
      @(negedge clk);
      rst_n = 0;
      @(negedge clk);
      rst_n = 1;
    end
  endtask

endmodule
