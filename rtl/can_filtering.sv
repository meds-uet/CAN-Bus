// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: A SystemVerilog testbench designed to verify the functionality of the can_filtering module 
// by testing frame acceptance based on CAN identifier filtering.
//
// Author: Nimrajavaid
// Date: 16-july-2025
`timescale 1ns / 1ps
//////////////////////////////////////////////////////


module can_filtering(
  input  logic        ide,                // 0: standard, 1: extended
  input  logic [10:0] id_std,             // 11-bit standard ID
  input  logic [17:0] id_ext,             // 18-bit extended ID

  // Acceptance Codes
  input  logic [7:0]  acceptance_code_0,
  input  logic [7:0]  acceptance_code_1,
  input  logic [7:0]  acceptance_code_2,
  input  logic [7:0]  acceptance_code_3,

  // Acceptance Masks
  input  logic [7:0]  acceptance_mask_0,
  input  logic [7:0]  acceptance_mask_1,
  input  logic [7:0]  acceptance_mask_2,
  input  logic [7:0]  acceptance_mask_3,

  output logic        accept_frame        // 1 = accept, 0 = reject

    );
  logic [28:0] rx_id;
  logic [28:0] acceptance_code_combined;
  logic [28:0] acceptance_mask_combined;

  always_comb begin
    if (!ide) begin
      // Standard Frame: 11-bit
      rx_id = {18'b0, id_std};
      acceptance_code_combined = {18'b0, acceptance_code_0, acceptance_code_1[7:5]};
      acceptance_mask_combined = {18'b0, acceptance_mask_0, acceptance_mask_1[7:5]};
    end else begin
      // Extended Frame: 29-bit
      rx_id = {id_std, id_ext};
      acceptance_code_combined = {
        acceptance_code_0,
        acceptance_code_1,
        acceptance_code_2,
        acceptance_code_3[7:3]
      };
      acceptance_mask_combined = {
        acceptance_mask_0,
        acceptance_mask_1,
        acceptance_mask_2,
        acceptance_mask_3[7:3]
      };
    end

    accept_frame = ((rx_id & acceptance_mask_combined) ==
                    (acceptance_code_combined & acceptance_mask_combined));
  end

endmodule
