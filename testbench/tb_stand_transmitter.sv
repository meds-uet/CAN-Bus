// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0
// Description: Testbench for CAN Transmitter FSM-based module
// Author: Nimra Javaid
// Date: 5-Aug-2025
`timescale 1ns / 1ps
`include "can_defs.svh"

module tb_can_transmitter;

  logic clk;
  logic rst_n;
  logic sample_point;
  logic start_tx;
  logic tx_remote_req;
  logic [10:0] tx_id_std;
  logic [17:0] tx_id_ext;
  logic tx_ide;
  logic tx_rtr1;
  logic tx_rtr2;
  logic [3:0] tx_dlc;
  logic [14:0] tx_crc;
  logic [7:0] tx_data[0:7];
  logic tx_bit;
  logic tx_done;
  logic rd_tx_data_byte;
  logic arbitration_active;

  // Instantiate DUT
  can_transmitter dut (
    .clk(clk),
    .rst_n(rst_n),
    .sample_point(sample_point),
    .start_tx(start_tx),
    .tx_remote_req(tx_remote_req),
    .tx_id_std(tx_id_std),
    .tx_id_ext(tx_id_ext),
    .tx_ide(tx_ide),
    .tx_rtr1(tx_rtr1),
    .tx_rtr2(tx_rtr2),
    .tx_dlc(tx_dlc),
    .tx_crc(tx_crc),
    .tx_data(tx_data),
    .tx_bit(tx_bit),
    .tx_done(tx_done),
    .rd_tx_data_byte(rd_tx_data_byte),
    .arbitration_active(arbitration_active)
  );

  // Clock generation
  always #5 clk = ~clk;

  // Sample point generation (you can change it to simulate bus timing more accurately)
  always #10 sample_point = ~sample_point;

  // Test sequence
  initial begin
    // Initialize
    clk = 0;
    sample_point = 0;
    rst_n = 0;
    start_tx = 0;

    tx_id_std = 11'h7FF;     // Max 11-bit ID
    tx_id_ext = 18'h0;       // Not used
    tx_ide = 1'b0;           // Standard frame
    tx_rtr1 = 1'b0;          // Data frame
    tx_rtr2 = 1'b0;
    tx_remote_req = 1'b0;    // Not a remote frame
    tx_dlc = 4'b0010;           // 2 bytes of data
    tx_crc = 15'h1234;       // Dummy CRC

    tx_data[0] = 8'hAB;      // Data byte 0
    tx_data[1] = 8'hCD;      // Data byte 1
    tx_data[2] = 8'h00;
    tx_data[3] = 8'h00;
    tx_data[4] = 8'h00;
    tx_data[5] = 8'h00;
    tx_data[6] = 8'h00;
    tx_data[7] = 8'h00;

    #20;
    rst_n = 1;

    // Wait for a few clock cycles
    #20;

    // Start transmission
    @(posedge clk);
    start_tx = 1;

    @(posedge clk);
    start_tx = 0;

    // Wait for tx_done signal
    wait (tx_done);

    $display("Transmission completed.");
    $finish;
  end

endmodule
