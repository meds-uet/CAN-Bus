
// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
// Description: 
//A SystemVerilog testbench to verify that can_bit_destuffer correctly detects 
//and flags stuffed bits after five identical bits in a CAN frame
// Author: Nimrajavaid
// Date: 01-August-2025

module can_bit_destuffer (
  input  logic clk,
  input  logic rst_n,
  input  logic bit_in,
  input  logic sample_point,     // renamed from rx_point
  output logic bit_out,
  output logic remove_flag
);

  logic prev_bit;
  logic [2:0] same_count;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      prev_bit   <= 1;
      same_count <= 1;
    end else if (sample_point) begin
      if (bit_in == prev_bit)
        same_count <= same_count + 1;
      else
        same_count <= 1;

      prev_bit <= bit_in;
    end
  end

  assign remove_flag = (same_count == 6);  // 6th same bit = stuffed bit to remove
  assign bit_out     = bit_in;             

endmodule
