// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0
// Description: Testbench for CAN Transmitter module without bit stuffing and 8-byte data
// Author: Nimrajavaid
// Date: 29-July-2025

`timescale 1ns / 10ps
`include "can_defs.svh"

module tb_can_transmitter;

  logic clk;
  logic rst_n;
  logic tx_enable;
  logic tx_point;
  logic initiate;
  logic [10:0] tx_id_std;
  logic [17:0] tx_id_ext;
  logic tx_ide;
  logic tx_rtr;
  logic [3:0] tx_dlc;
  logic [7:0] tx_data [0:7];
  logic [14:0] tx_crc;
  logic tx_bit;
  logic tx_done;

  // Clock generation: 100 MHz (10ns period)
  initial clk = 0;
  always #5 clk = ~clk;

  // Bit timing tick (tx_point): 50 MHz (20ns period)
  initial begin
    tx_point = 0;
    forever #10 tx_point = ~tx_point;
  end

  // DUT instantiation
  can_transmitter dut (
    .clk(clk),
    .rst_n(rst_n),
    .tx_enable(tx_enable),
    .tx_point(tx_point),
    .initiate(initiate),
    .tx_id_std(tx_id_std),
    .tx_id_ext(tx_id_ext),
    .tx_ide(tx_ide),
    .tx_rtr(tx_rtr),
    .tx_dlc(tx_dlc),
    .tx_data(tx_data),
    .tx_crc(tx_crc),
    .tx_bit(tx_bit),
    .tx_done(tx_done)
  );

  // Stimulus
  initial begin
    // Initial values
    clk       = 0;
    rst_n     = 0;
    tx_enable = 0;
    initiate  = 1;

    #20;
    rst_n     = 1;
    initiate  = 0;

    // Set up frame
    tx_id_std = 11'b11110101011;   // ID = 0x7AB
    tx_id_ext = 18'd0;             // Not used in standard frame
    tx_ide    = 1'b0;              // Standard frame
    tx_rtr    = 1'b0;              // Data frame
    tx_dlc    = 4'b1000;           // 8 bytes

    tx_data[0] = 8'b10101010; // 0xAA
    tx_data[1] = 8'b11001100; // 0xCC
    tx_data[2] = 8'b11110000; // 0xF0
    tx_data[3] = 8'b00001111; // 0x0F
    tx_data[4] = 8'b11111111; // 0xFF
    tx_data[5] = 8'b00000000; // 0x00
    tx_data[6] = 8'b01010101; // 0x55
    tx_data[7] = 8'b00110011; // 0x33

    tx_crc     = 15'b100100011010100; // Dummy CRC (0x1234)

    // Start transmission
    #30;
    tx_enable = 1;
    #20;
    tx_enable = 0;

    // Wait for TX done
    wait (tx_done == 1);
    $display("Transmission completed at time: %t", $time);

    #100;
    $finish;
  end

endmodule
