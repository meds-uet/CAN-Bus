// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0
// Description: Testbench for receiver FSM-based module
// Author: Nimra Javaid
// Date: 11-Aug-2025

`timescale 1ns/1ps

module tb_can_receiver;

  logic clk;
  logic rst_n;
  logic rx_bit_curr;
  logic sample_point;
  logic remove_stuff_bit;

  logic [7:0]  rx_data_array [7:0];
  logic        rx_done_flag;
  logic [10:0] rx_id_std;
  logic [17:0] rx_id_ext;
  logic        rx_ide;
  logic [3:0]  rx_dlc;
  logic        rx_remote_req;

  // Instantiate DUT
  can_receiver dut (
    .clk(clk),
    .rst_n(rst_n),
    .rx_bit_curr(rx_bit_curr),
    .sample_point(sample_point),
    .remove_stuff_bit(remove_stuff_bit),
    .rx_data_array(rx_data_array),
    .rx_done_flag(rx_done_flag),
    .rx_id_std(rx_id_std),
    .rx_id_ext(rx_id_ext),
    .rx_ide(rx_ide),
    .rx_dlc(rx_dlc),
    .rx_remote_req(rx_remote_req)
  );
  always #5 clk = ~clk;
  always #10 sample_point = ~sample_point;

  task send_bit(input bit value);
    begin
      @(posedge sample_point);
      rx_bit_curr = value;
    end
  endtask

  // Send multiple bits task
  task send_bits(input int num_bits, input bit value);
    for (int i = 0; i < num_bits; i++) begin
      send_bit(value);
    end
  endtask

  initial begin
    clk = 0;
    sample_point = 0;
    remove_stuff_bit = 0;
    rx_bit_curr = 1; // idle
    rst_n = 0;

    #20 rst_n = 1;

    // SOF
    send_bit(0);

    // 11-bit ID = 0x7FF
    for (int i = 10; i >= 0; i--)
      send_bit(1);

    // RTR
    send_bit(0);

    // IDE
    send_bit(0);

    // r0
    send_bit(0);

    // DLC = 2 (0010)
    send_bit(0);
    send_bit(0);
    send_bit(1);
    send_bit(0);

    // Data byte 1 = 0xAB
    send_bit(1); send_bit(0); send_bit(1); send_bit(0);
    send_bit(1); send_bit(0); send_bit(1); send_bit(1);

    // Data byte 2 = 0xCD
    send_bit(1); send_bit(1); send_bit(0); send_bit(0);
    send_bit(1); send_bit(1); send_bit(0); send_bit(1);

    // CRC (15 bits dummy = all 1)
    send_bits(15, 1);

    // CRC delimiter
    send_bit(1);

    // ACK
    send_bit(0);

    // ACK delimiter
    send_bit(1);

    // EOF (7 bits recessive)
    send_bits(7, 1);

    // IFS (3 bits recessive)
    send_bits(3, 1);

    // Wait for done
    wait (rx_done_flag == 1);
    $display("Frame received: ID=%h DLC=%0d Data0=%h Data1=%h",
             rx_id_std, rx_dlc, rx_data_array[0], rx_data_array[1]);

    #50 $finish;
  end

endmodule
