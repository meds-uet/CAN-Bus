// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
// Description: Description: A SystemVerilog testbench to validate the bitwise CRC generation 
// for CAN frames using the can_crc15_gen module.

// Author: Nimrajavaid
// Date: 28-july-2025

`timescale 1ns / 1ps

module tb_can_crc15_frame;

  // Inputs to DUT
  logic clk, rst_n, crc_en, data_bit, crc_init;

  // Output from DUT
  logic [14:0] crc_out;

  // Instantiate the DUT
  can_crc15_gen dut (
    .clk(clk),
    .rst_n(rst_n),
    .crc_en(crc_en),
    .data_bit(data_bit),
    .crc_init(crc_init),
    .crc_out(crc_out)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Example CAN frame data to include in CRC calculation
  logic [26:0] frame_bits = {
    1'b0,                     // SOF
    11'b00001010101,         // ID
    1'b0,                    // RTR
    1'b0,                    // IDE
    1'b0,                    // r0
    4'b0001,                 // DLC = 1 byte
    8'b11001100              // DATA byte
  };

  integer i;

  initial begin
    $display("\n===== CAN Frame CRC Test =====");
    clk = 0;
    rst_n = 0;
    crc_en = 0;
    crc_init = 0;
    data_bit = 0;

    // Reset
    #10 rst_n = 1;

    // Initialize CRC register
    #10 crc_init = 1;
    #10 crc_init = 0;

    // Apply frame bits one-by-one
    for (i = 26; i >= 0; i--) begin
      @(posedge clk);
      data_bit = frame_bits[i];
      crc_en = 1;
      @(posedge clk);
      $display("Time: %0t ns | Bit[%0d] = %b | CRC = %015b", $time, i, data_bit, crc_out);
    end

    crc_en = 0;
    $display("==== Final CRC Output: %015b ====", crc_out);
    $finish;
  end

endmodule
