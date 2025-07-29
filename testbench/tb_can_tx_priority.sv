// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0

// Description: Testbench for can_tx_priority to verify CAN ID priority handling

// Author: Ayesha Qadir
// Date: 15 July, 2025

`timescale 1ns/1ps

module tb_can_tx_priority;

  // Parameter to define number of simultaneous request entries the DUT can handle
  parameter N = 4;

  // Testbench signals
  logic clk, rst;
  logic tx_request;
  logic [10:0] req_id;         // Requested CAN ID
  logic [3:0] req_dlc;         // Data Length Code
  logic [7:0] req_data [8];    // 8-byte data array

  logic start_tx;
  logic [10:0] tx_id;          // Output CAN ID (selected for transmission)
  logic [3:0] tx_dlc;          // Output DLC
  logic [7:0] tx_data [8];     // Output data
  logic tx_done;               // Acknowledge signal to indicate transmission is done

  // Instantiate the DUT (Device Under Test)
  can_tx_priority #(.N(N)) dut (
    .clk(clk),
    .rst(rst),
    .tx_request(tx_request),
    .req_id(req_id),
    .req_dlc(req_dlc),
    .req_data(req_data),
    .start_tx(start_tx),
    .tx_id(tx_id),
    .tx_dlc(tx_dlc),
    .tx_data(tx_data),
    .tx_done(tx_done)
  );

  // Clock generation: toggles every 5ns => 10ns clock period = 100MHz
  always #5 clk = ~clk;

  // Task to generate a request and insert into the DUT
  task send_request(input [10:0] id, input [3:0] dlc, input [7:0] data_val);
    integer j;
    begin
      @(negedge clk);  // Wait for negative edge
      tx_request = 1;  // Set request high
      req_id = id;     // Assign ID and DLC
      req_dlc = dlc;

      // Fill 8 bytes with incremental data starting from data_val
      for (j = 0; j < 8; j++) begin
        req_data[j] = data_val + j;
      end

      @(negedge clk);  // Keep tx_request high for one cycle
      tx_request = 0;  // Lower the request
    end
  endtask

 initial begin
  // Initialization
  clk = 0;
  rst = 1;
  tx_request = 0;
  tx_done = 0;
  req_id = 0;
  req_dlc = 0;
  for (int j = 0; j < 8; j++) begin
    req_data[j] = 8'h00;
  end

  // Deassert reset after one negative clock edge
  @(negedge clk);
  rst = 0;

  // --- Send 3 CAN requests ---
  send_request(11'd300, 4'd8, 8'hA0); // Low priority
  send_request(11'd100, 4'd8, 8'hB0); // Highest priority
  send_request(11'd200, 4'd8, 8'hC0); // Mid priority

  // Wait for arbiter to select highest priority (lowest ID)
  repeat (5) @(negedge clk);

  if (start_tx && tx_id == 11'd100)
    $display("PASS: Selected ID = %0d", tx_id);
  else
    $display("FAIL: Incorrect ID selected = %0d", tx_id);

  // Simulate end of transmission
  @(negedge clk);
  tx_done = 1;
  @(negedge clk);
  tx_done = 0;

  // Wait for next arbitration
  repeat (5) @(negedge clk);

  if (start_tx && tx_id == 11'd200)
    $display("PASS: Selected ID = %0d", tx_id);
  else
    $display("FAIL: Incorrect ID selected = %0d", tx_id);

  // Simulate end of transmission
  @(negedge clk);
  tx_done = 1;
  @(negedge clk);
  tx_done = 0;

  // Wait for next arbitration
  repeat (5) @(negedge clk);

  if (start_tx && tx_id == 11'd300)
    $display("PASS: Selected ID = %0d", tx_id);
  else
    $display("FAIL: Incorrect ID selected = %0d", tx_id);

  $finish;
end

endmodule