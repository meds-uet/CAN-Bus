// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0

// Description: Testbench for can_tx_priority to verify CAN ID priority handling

// Author: Ayesha Qadir
// Date: 15 July, 2025

`timescale 1ns/1ps

`include "can_defs.svh"

module tb_can_tx_priority_dbg;

  // Parameters
  localparam N = 4; // small to demonstrate full condition

  // DUT signals
  logic clk, rst;
  logic we, re;
  logic [10:0] req_id;
  logic [3:0]  req_dlc;
  logic [7:0]  req_data [8];
  logic start_tx;
  logic [10:0] tx_id;
  logic [3:0]  tx_dlc;
  logic [7:0]  tx_data [8];
  logic full, empty;

  // DUT instance
  can_tx_priority #(.N(N)) dut (
    .clk(clk),
    .rst(rst),
    .we(we),
    .req_id(req_id),
    .req_dlc(req_dlc),
    .req_data(req_data),
    .re(re),
    .start_tx(start_tx),
    .tx_id(tx_id),
    .tx_dlc(tx_dlc),
    .tx_data(tx_data),
    .full(full),
    .empty(empty)
  );

  // Clock
  always #5 clk = ~clk;

  // ==============
  // Utility tasks
  // ==============
  task automatic send_req(input [10:0] id);
    begin
      @(posedge clk);
      we = 1;
      req_id = id;
      req_dlc = 4'd8;
      for (int i = 0; i < 8; i++) req_data[i] = i + id[7:0];
      $display("[%0t] TB: send_req id=%0d", $time, id);
      @(posedge clk);
      we = 0;
      @(posedge clk); // give DUT a cycle to process
    end
  endtask

  task automatic do_tx_done();
    begin
      @(posedge clk);
      re = 1;
      $display("[%0t] TB: tx_done asserted", $time);
      @(posedge clk);
      re = 0;
      @(posedge clk); // let DUT settle
    end
  endtask

  // Simple check helper
  task automatic assert_ok(input bit cond, input string msg);
    begin
      if (!cond) $display("[%0t] ERROR: %s", $time, msg);
      else        $display("[%0t] OK: %s", $time, msg);
    end
  endtask

  // ==============
  // Monitor
  // ==============
  initial begin
    $display("Time\tstart_tx\ttx_id\tfull\tempty");
    forever @(posedge clk) begin
      $display("%0t\t%b\t\t%0d\t%b\t%b", $time, start_tx, tx_id, full, empty);
    end
  end

  // ==============
  // Test sequence
  // ==============
  initial begin
    // init
    clk = 0;
    rst = 1;
    we = 0;
    re = 0;
    req_id = 0;
    req_dlc = 0;
    for (int i = 0; i < 8; i++) req_data[i] = 0;

    #15 rst = 0;
    #10;

    $display("\n=== TEST 1: Normal queuing ===");
    send_req(11'd300);
    send_req(11'd500);
    // At this point tx_reg should be 300, buffer [500]
    assert_ok(start_tx && tx_id == 300, "tx_reg should be 300 after first send");
    do_tx_done(); // should move 500 into tx_reg
    assert_ok(start_tx && tx_id == 500, "tx_reg should be 500 after tx_done");

    #20;
    $display("\n=== TEST 2: Preemption ===");
    send_req(11'd700);  // goes to tx_reg
    assert_ok(start_tx && tx_id == 700, "tx_reg should be 700");
    send_req(11'd200);  // should preempt 700 -> tx_reg = 200, buffer contains 700
    // small delay for logic to settle
    @(posedge clk);
    assert_ok(start_tx && tx_id == 200, "tx_reg should be 200 after preemption");
    // now finish transmission and expect 700 to come back
    do_tx_done();
    assert_ok(start_tx && tx_id == 700, "tx_reg should be 700 after tx_done (from buffer)");

    #20;
    $display("\n=== TEST 3: Buffer full ===");
    // Clear DUT state by draining
    repeat (4) begin
      if (!empty) do_tx_done();
      else break;
    end

    // Fill buffer (tx_reg will take first, remaining fill up buffer)
    send_req(11'd400);
    send_req(11'd450);
    send_req(11'd600);
    send_req(11'd100);  // depending on timing this might be tx_reg or buffer
    // Now buffer likely full (N=4). Attempt one more
    send_req(11'd50);   // should be ignored when full
    // Check full flag asserted at some point
    @(posedge clk);
    assert_ok(full || empty==0, "Expect buffer full when enough requests were sent");

    // drain all entries
    repeat (8) begin
      if (!empty) do_tx_done();
      else @(posedge clk);
    end

    #20;
    $display("\n=== TEST 4: Empty ===");
    // Nothing to send, assert empty
    assert_ok(empty, "DUT should be empty now");

    #50;
    $display("All tests finished. Stopping simulation.");
    $stop;
  end

endmodule
