// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//Description: 
// A SystemVerilog testbench designed to verify the functionality of the can_crc15_gen module.
// It applies a sequence of data bits one-by-one to simulate real-time CRC computation in a CAN frame.
// The test checks that the CRC register correctly updates using the CAN polynomial (x^15 + x^14 + x^10 + x^8 + x^7 + x^4 + x^3 + 1),
// and ensures the output matches the expected 15-bit CRC value.
// Author: Nimrajavaid
// Date: 28-july-2025
module can_crc15_gen (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        crc_en,
  input  logic        data_bit,
  input  logic        crc_init,
  output logic [14:0] crc_out
);

  logic [14:0] crc_reg, next_crc;
  logic        feedback;  

  always_comb begin
    next_crc = crc_reg;
    feedback = data_bit ^ crc_reg[14];  

    if (crc_en) begin
      next_crc[14] = crc_reg[13];
      next_crc[13] = crc_reg[12];
      next_crc[12] = crc_reg[11];
      next_crc[11] = crc_reg[10];
      next_crc[10] = crc_reg[9]  ^ feedback;
      next_crc[9]  = crc_reg[8];
      next_crc[8]  = crc_reg[7]  ^ feedback;
      next_crc[7]  = crc_reg[6]  ^ feedback;
      next_crc[6]  = crc_reg[5];
      next_crc[5]  = crc_reg[4];
      next_crc[4]  = crc_reg[3]  ^ feedback;
      next_crc[3]  = crc_reg[2]  ^ feedback;
      next_crc[2]  = crc_reg[1];
      next_crc[1]  = crc_reg[0];
      next_crc[0]  = feedback;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || crc_init)
      crc_reg <= 15'd0;
    else
      crc_reg <= next_crc;
  end

  assign crc_out = crc_reg;

endmodule
