// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:
// This module implements CAN bus error detection
// and error state management logic according to the CAN protocol
// It detects five key error types (bit, stuff, form, CRC, ACK), 
// updates TEC (Transmit Error Counter) and REC (Receive Error Counter),
// and manages the node’s error state (error_active, error_passive, bus_off).
//
// Author: Aryam Shabbir
// Date: 6th August,2025


`include "can_defs.svh"

module can_error_detection (
    input  logic clk,
    input  logic rst,
    input  logic rx_bit,          
    input  logic tx_bit,          
    input  logic tx_active,       
    input  logic sample_point,    

    // For stuff error detection
    input  logic bit_de_stuffing_ff,
    input  logic remove_stuff_bit,
    input  logic rx_bit_curr,
    input  logic rx_bit_prev,

    // For bit error exceptions
    input  logic in_arbitration,   // Are we in arbitration field?
    input  logic in_ack_slot,      // Are we in ACK slot?
    input  logic sending_error_flag_passive,  // For passive error flag

    // For form error
   
    input logic in_crc_delimiter, // High when in CRC delimiter bit
    input logic in_ack_delimiter, // High when in ACK delimiter bit
    input logic in_eof,

    // For CRC error
    input  logic crc_check_done,
    input  logic crc_rx_valid,
    input  logic crc_rx_match,

    output logic bit_error,
    output logic stuff_error,
    output logic crc_error,
    output logic form_error,
    output logic ack_error,
    output logic [4:0] tec,
    output logic [7:0] rec,
    output logic error_active,
    output logic error_passive,
    output logic bus_off
);

// --- STUFF ERROR ---
   
    assign stuff_error = sample_point & bit_de_stuffing_ff & remove_stuff_bit & (rx_bit_curr == rx_bit_prev);
// BIT ERROR
    assign bit_error = sample_point & tx_active & 
     (tx_bit != rx_bit) &  ~((tx_bit == 1'b1) &&(rx_bit == 1'b0) && (in_arbitration ||in_ack_slot ||sending_error_flag_passive));
// ACK ERROR
    assign ack_error = sample_point & tx_active & in_ack_slot & (rx_bit == 1'b1);  
// FORM ERROR 
    assign form_error= sample_point & !rx_bit & (in_crc_delimiter || in_ack_delimiter || in_eof);

// CRC ERROR
assign crc_error = crc_check_done & crc_rx_valid & ~crc_rx_match;
always_ff @(posedge clk or negedge rst) begin
        if (!rst) begin
            tec <= 5'd0;
            rec <= 8'd0;
        end else begin
            // Transmit errors 
            if (tx_active && (bit_error || form_error || ack_error)) begin
                if (tec <= 5'd31)   // Prevent overflow beyond 511
                    tec <= tec + 1; 
            end

            // Receive errors 
            if (!tx_active && (bit_error || form_error || stuff_error || crc_error)) begin
                 if (rec < 8'd254)   // Only increment if less than 255
                         rec <= rec + 1;
                 
         end 
     end
end
//  ERROR STATE LOGIC 
always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        error_active  <= 1'b1;
        error_passive <= 1'b0;
        bus_off       <= 1'b0;
    end else begin
        // Bus-Off condition
        if (tec >= 5'd31) begin
            bus_off       <= 1'b1;
            error_passive <= 1'b0;
            error_active  <= 1'b0;

        // Passive state
        end else if ((tec >= 5'd16) || (rec >= 8'd128)) begin
            bus_off       <= 1'b0;
            error_passive <= 1'b1;
            error_active  <= 1'b0;

        // Active state
        end else begin
            bus_off       <= 1'b0;
            error_passive <= 1'b0;
            error_active  <= 1'b1;
        end
    end
end


endmodule

