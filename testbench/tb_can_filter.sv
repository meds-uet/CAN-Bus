// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: A SystemVerilog testbench designed to verify the functionality of the 
// can_filtering module by testing frame acceptance based on CAN identifier filtering.
//
// Author: Nimrajavaid
// Date: 16/07/2025
`timescale 1ns / 1ps
module tb_can_filter;
  logic        ide;
  logic [10:0] id_std;
  logic [17:0] id_ext;
  logic [7:0]  acceptance_code_0, acceptance_code_1, acceptance_code_2, acceptance_code_3;
  logic [7:0]  acceptance_mask_0, acceptance_mask_1, acceptance_mask_2, acceptance_mask_3;
  logic        accept_frame;

  // Instantiate the module
  can_filtering dut (
    .ide(ide),
    .id_std(id_std),
    .id_ext(id_ext),
    .acceptance_code_0(acceptance_code_0),
    .acceptance_code_1(acceptance_code_1),
    .acceptance_code_2(acceptance_code_2),
    .acceptance_code_3(acceptance_code_3),
    .acceptance_mask_0(acceptance_mask_0),
    .acceptance_mask_1(acceptance_mask_1),
    .acceptance_mask_2(acceptance_mask_2),
    .acceptance_mask_3(acceptance_mask_3),
    .accept_frame(accept_frame)
  );

  initial begin
    

//    Test 1: Standard Frame - NOT MATCH
    ide = 0;
    id_std = 11'b10100111111;

    acceptance_code_0 = 8'b10100100;
    acceptance_code_1 = 8'b00000000;
    acceptance_mask_0 = 8'b11111111;
    acceptance_mask_1 = 8'b11100000;

    acceptance_code_2 = 0;
    acceptance_code_3 = 0;
    acceptance_mask_2 = 0;
    acceptance_mask_3 = 0;

    #30;
//  Test 2: Standard Frame - MATCH
    ide = 0;
    id_std = 11'b10100111111;

    acceptance_code_0 = 8'b10100111;
    acceptance_code_1 = 8'b11100000;
    acceptance_mask_0 = 8'b11111111;
    acceptance_mask_1 = 8'b11100000;

    #30;


//  Test 3: Extended Frame - MATCH
ide = 1;

    id_std = 11'b10101010101;
    id_ext = 18'b010101010101010101;


    acceptance_code_0 = 8'b10101010;
    acceptance_code_1 = 8'b10101010;
    acceptance_code_2 = 8'b10101010;
    acceptance_code_3 = 8'b10101000; // only bits [7:6] matter ? top 2 bits of last byte

    // Mask = all bits 1 ? full compare
    acceptance_mask_0 = 8'b11111111;
    acceptance_mask_1 = 8'b11111111;
    acceptance_mask_2 = 8'b11111111;
    acceptance_mask_3 = 8'b11111000; // bits [7:6] ? top 2 bits = total 29 bits

    #30;

    //  Test 4: Extended Frame - NOT MATCH
    ide = 1;
    id_std = 11'b11111111111;
    id_ext = 18'b000000000000000000;

    acceptance_code_0 = 8'b10101010;
    acceptance_code_1 = 8'b10101111;
    acceptance_code_2 = 8'b00001111;
    acceptance_code_3 = 8'b00000000;

    acceptance_mask_0 = 8'b11111111;
    acceptance_mask_1 = 8'b11111111;
    acceptance_mask_2 = 8'b11111111;
    acceptance_mask_3 = 8'b11000000;

    #30;
   
  end
endmodule
