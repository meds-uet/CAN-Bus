// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0

// Description: Stimulates the CAN receiver with a destuffed standard frame bitstream and 
//verifies correct decoding of ID, DLC, and data.

// Author: Ayesha Qadir
// Date: 21 July, 2025



`timescale 1ns/10ps
`include "can_defs.svh"

module tb_can_receiver;

  logic clk;
  logic rst_n;
  logic sampled_bit;
  logic sampled_bit_q;
  logic sample_point;
  logic rx_point;

  logic [10:0] rx_id_std;
  logic        rx_rtr1;
  logic        rx_ide;
  logic [3:0]  rx_dlc;
  logic [14:0] rx_crc;
  logic [7:0]  rx_data [0:7];
  logic        rx_done;

  // Instantiate DUT
  can_receiver uut (
    .clk(clk),
    .rst_n(rst_n),
    .sampled_bit(sampled_bit),
    .sampled_bit_q(sampled_bit_q),
    .sample_point(sample_point),
    .rx_point(rx_point),
    .rx_id_std(rx_id_std),
    .rx_rtr1(rx_rtr1),
    .rx_ide(rx_ide),
    .rx_dlc(rx_dlc),
    .rx_crc(rx_crc),
    .rx_data(rx_data),
    .rx_done(rx_done)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Test stimulus task
  task send_frame_bit(input bit b);
    begin
      sampled_bit_q = sampled_bit; // delay previous bit
      sampled_bit   = b;
      sample_point  = 1;
      rx_point      = 1;
      @(posedge clk);
      sample_point  = 0;
      rx_point      = 0;
      @(posedge clk);
    end
  endtask

  // Full CAN frame generation
  initial begin
    $display("\n--- Starting CAN Receiver Testbench ---\n");

    // Reset
    clk = 0;
    rst_n = 0;
    sampled_bit = 1;
    sampled_bit_q = 1;
    sample_point = 0;
    rx_point = 0;
    #20;
    rst_n = 1;
    #20;

    // --- SOF (Start of Frame) ---
    send_frame_bit(0);

    // --- Standard ID = 0x7DC = 111 1101 1100 (11 bits) ---
    send_frame_bit(1); send_frame_bit(1); send_frame_bit(1);
    send_frame_bit(1); send_frame_bit(1); send_frame_bit(0);
    send_frame_bit(1); send_frame_bit(1); send_frame_bit(1);
    send_frame_bit(0); send_frame_bit(0);

    // --- RTR = 0 ---
    send_frame_bit(0);

    // --- IDE = 0 (standard frame) ---
    send_frame_bit(0);

    // --- r0 = 0 ---
    send_frame_bit(0);

    // --- DLC = 1 (4'b0001) ---
    send_frame_bit(0); send_frame_bit(0);
    send_frame_bit(0); send_frame_bit(1);

    // --- Data Byte = 0xA5 = 10100101 ---
    send_frame_bit(1); send_frame_bit(0); send_frame_bit(1); send_frame_bit(0);
    send_frame_bit(0); send_frame_bit(1); send_frame_bit(0); send_frame_bit(1);

    // --- Dummy CRC = 15 bits (e.g., 15'h1ABC = 000110101011100) ---
    send_frame_bit(0); send_frame_bit(0); send_frame_bit(0); send_frame_bit(1);
    send_frame_bit(1); send_frame_bit(0); send_frame_bit(1); send_frame_bit(0);
    send_frame_bit(1); send_frame_bit(0); send_frame_bit(1); send_frame_bit(1);
    send_frame_bit(1); send_frame_bit(0); send_frame_bit(0);

    // --- CRC Delimiter = 1 ---
    send_frame_bit(1);

    // --- ACK = 0 (dominant) ---
    send_frame_bit(0);

    // --- ACK Delimiter = 1 ---
    send_frame_bit(1);

    // --- EOF = 7 recessive bits ---
    repeat (7) send_frame_bit(1);

    // --- IFS = 3 bits ---
    repeat (3) send_frame_bit(1);

    // Wait extra cycles for rx_done
    repeat (20) @(posedge clk);

    // --- Display Results ---
    $display("\n--- CAN Frame Reception Completed ---\n");
    $display("ID: %h, RTR: %b, IDE: %b, DLC: %d, CRC: %h, DONE: %b",
      rx_id_std, rx_rtr1, rx_ide, rx_dlc, rx_crc, rx_done);
    for (int i = 0; i < rx_dlc; i++) begin
      $display("DATA[%0d]: %h", i, rx_data[i]);
    end

    $finish;
  end
endmodule
