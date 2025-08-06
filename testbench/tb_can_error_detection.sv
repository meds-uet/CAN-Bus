// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:
// This testbench stimulates and verifies
// how your CAN error handling module behaves 
// under various types of CAN protocol errors: bit, stuff, CRC, ACK, and form errors.
//
// Author: Aryam Shabbir
// Date: 6th August,2025


`timescale 1ns/1ps

module tb_can_error_detection;

    // Inputs
    logic clk;
    logic rst;
    logic rx_bit;
    logic tx_bit;
    logic tx_active;
    logic sample_point;

    logic bit_de_stuffing_ff;
    logic remove_stuff_bit;
    logic rx_bit_curr;
    logic rx_bit_prev;

    logic in_arbitration;
    logic in_ack_slot;
    logic sending_error_flag_passive;

    logic in_crc_delimiter;
    logic in_ack_delimiter;
    logic in_eof;

    logic crc_check_done;
    logic crc_rx_valid;
    logic crc_rx_match;

    // Outputs
    logic bit_error;
    logic stuff_error;
    logic crc_error;
    logic form_error;
    logic ack_error;
    logic [8:0] tec;
    logic [7:0] rec;
    logic error_active;
    logic error_passive;
    logic bus_off;

    // DUT
    can_error_detection dut (
        .clk(clk),
        .rst(rst),
        .rx_bit(rx_bit),
        .tx_bit(tx_bit),
        .tx_active(tx_active),
        .sample_point(sample_point),
        .bit_de_stuffing_ff(bit_de_stuffing_ff),
        .remove_stuff_bit(remove_stuff_bit),
        .rx_bit_curr(rx_bit_curr),
        .rx_bit_prev(rx_bit_prev),
        .in_arbitration(in_arbitration),
        .in_ack_slot(in_ack_slot),
        .sending_error_flag_passive(sending_error_flag_passive),
        .in_crc_delimiter(in_crc_delimiter),
        .in_ack_delimiter(in_ack_delimiter),
        .in_eof(in_eof),
        .crc_check_done(crc_check_done),
        .crc_rx_valid(crc_rx_valid),
        .crc_rx_match(crc_rx_match),
        .bit_error(bit_error),
        .stuff_error(stuff_error),
        .crc_error(crc_error),
        .form_error(form_error),
        .ack_error(ack_error),
        .tec(tec),
        .rec(rec),
        .error_active(error_active),
        .error_passive(error_passive),
        .bus_off(bus_off)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize all
        clk = 0;
        rst = 0;
        rx_bit = 1;
        tx_bit = 1;
        tx_active = 0;
        sample_point = 0;

        bit_de_stuffing_ff = 0;
        remove_stuff_bit = 0;
        rx_bit_curr = 1;
        rx_bit_prev = 1;

        in_arbitration = 0;
        in_ack_slot = 0;
        sending_error_flag_passive = 0;

        in_crc_delimiter = 0;
        in_ack_delimiter = 0;
        in_eof = 0;

        crc_check_done = 0;
        crc_rx_valid = 0;
        crc_rx_match = 1;

        // Reset pulse
        #10 rst = 1;

        // Test 1: BIT ERROR (Tx mode)
        #10;
        sample_point = 1;
        tx_active = 1;
        tx_bit = 1;
        rx_bit = 0;
        #10;
       $display("Test 1 - Bit Error: bit_error = %b | TEC = %0d | REC = %0d | active = %b | passive = %b | bus_off = %b",
       bit_error, tec, rec, error_active, error_passive, bus_off);

        sample_point = 0;
        tx_active = 0;

        // Test 2: STUFF ERROR (Rx mode)
        #10;
        bit_de_stuffing_ff = 1;
        remove_stuff_bit = 1;
        sample_point = 1;
        rx_bit_curr = 1;
        rx_bit_prev = 1;
        #10;
       $display("Test 2 - Stuff Error: stuff_error = %b | TEC = %0d | REC = %0d | active = %b | passive = %b | bus_off = %b",
       stuff_error, tec, rec, error_active, error_passive, bus_off);
        sample_point = 0;
        bit_de_stuffing_ff = 0;
        remove_stuff_bit = 0;

        // Test 3: CRC ERROR (Rx mode)
        #10;
        crc_check_done = 1;
        crc_rx_valid = 1;
        crc_rx_match = 0;
        #10;
       $display("Test 3 - CRC Error: crc_error = %b | TEC = %0d | REC = %0d | active = %b | passive = %b | bus_off = %b",
       crc_error, tec, rec, error_active, error_passive, bus_off);
        crc_check_done = 0;
        crc_rx_valid = 0;

        // Test 4: ACK ERROR (Tx mode)
        #10;
        tx_active = 1;
        in_ack_slot = 1;
        rx_bit = 1;
        sample_point = 1;
        #10;
       $display("Test 4 - ACK Error: ack_error = %b | TEC = %0d | REC = %0d | active = %b | passive = %b | bus_off = %b",
       ack_error, tec, rec, error_active, error_passive, bus_off);
        in_ack_slot = 0;
        tx_active = 0;

        // Test 5: FORM ERROR (ACK delimiter, Rx mode)
        #10;
        sample_point = 1;
        in_ack_delimiter = 1;
        rx_bit = 0;
        #20;
       $display("Test 5 - Form Error: form_error = %b | TEC = %0d | REC = %0d | active = %b | passive = %b | bus_off = %b",
       form_error, tec, rec, error_active, error_passive, bus_off);
        sample_point = 0;
        in_ack_delimiter = 0;

        $display("Simulation done");
        #20 $finish;
    end

endmodule
