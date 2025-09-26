// Copyright 2023 University of Engineering and Technology Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: CAN timing module. 
//
// Author: Muhammad Tahir, UET Lahore
// Date: 1.1.2025

`timescale 1 ns/10 ps

`include "can_defs.svh"

module can_timing (

    input logic                                   rst_n,                    // reset
    input logic                                   clk,                      // clock

    input logic                                   go_error_frame,
    input logic                                   go_overload_frame,
    input logic                                   send_ack,
    input logic                                   rx,
    input logic                                   tx,
    input logic                                   tx_next,
    input logic                                   transmitting,
    input logic                                   transmitter,
    input logic                                   rx_idle,
    input logic                                   rx_inter,
    input logic                                   go_tx,

    input logic                                   node_error_passive,

    input  wire type_reg2tim_s                    reg2tim_i,
  
    //output logic                                  frame_err_o
    output logic                                  sample_point,
    output logic                                  sampled_bit,
    output logic                                  sampled_bit_q,
    output logic                                  tx_point,
    output logic                                  hard_sync

);

// Registers to bit timing module interface 
type_reg2tim_s                          reg2tim;

logic [7:0]                             baud_div;
logic [2:0]                             resync_delay;
logic [7:0]                             baud_count_ff, baud_count_next;
logic [4:0]                             tq_counter_ff, tq_counter_next;
logic                                   tq_clk_ff, tq_clk_next;

// Signals for marking start and end of different phases in the bit time
logic                                   start_of_sync;
logic                                   start_of_tseg1;
logic                                   start_of_tseg2;
logic                                   end_of_tseg1;
logic                                   end_of_tseg2;
logic                                   tseg1_active_flag;
logic                                   tseg2_active_flag;

logic                                   reset_resync_delay;
logic                                   reset_tq_counter;  

logic                                   bit_start_point;
logic                                   bit_sample_point;
logic                                   rx_sample_curr;
logic                                   rx_sample_prev;
logic                                   tx_sample_next;

logic                                   allow_resync;
logic                                   allow_hard_sync;
logic                                   latched_resync;
logic                                   do_hard_sync;
logic                                   do_resync;
logic                                   resync_window;
logic                                   is_tseg1_tx;

// Signals for bit timing state machine
type_can_bit_phase_e                    bit_phase_ff, bit_phase_next;

/////////////////////////////////

assign reg2tim.tseg1 = reg2tim_i.tseg1;
assign reg2tim.tseg2 = reg2tim_i.tseg2;
assign reg2tim.sjw   = reg2tim_i.sjw;
assign reg2tim.baud_prescaler = reg2tim_i.baud_prescaler;

/////////////////////////////////

// Baud divisor based on prescaler	
assign baud_div = (reg2tim.baud_prescaler + 1'b1) << 1;       

// Counter to generate baud clock  
always_ff @(posedge clk) begin
  if (~rst_n) begin
    baud_count_ff <= '0;
    tq_clk_ff     <= 1'b0;
  end else begin
    baud_count_ff <= baud_count_next;
    tq_clk_ff     <= tq_clk_next;
  end
end

always_comb begin 
//  baud_count_next = baud_count_ff;
//  tq_clk_next     = 1'b0; 

  if (baud_count_ff == (baud_div - 1'b1)) begin
    baud_count_next = '0;
    tq_clk_next     = 1'b1;
  end else begin
    baud_count_next = baud_count_ff + 1'b1; 
    tq_clk_next     = 1'b0;
  end     
end

// Time quant counter 
always_ff @(posedge clk) begin
  if (~rst_n) begin
    tq_counter_ff <= 5'h0;
  end else begin 
    tq_counter_ff <= tq_counter_next;
  end
end

always_comb begin
  tq_counter_next = tq_counter_ff;

  if (reset_tq_counter) begin  
    tq_counter_next = 5'h0;
  end else if (tq_clk_ff) begin
    tq_counter_next = tq_counter_ff + 1'b1;
  end
end

/* When late edge is detected (in seg1 stage), stage seg1 is prolonged. */
assign is_tseg1_tx = (bit_phase_ff == BIT_PHASE_TSEG1) 
                     & (~transmitting | transmitting & (tx_sample_next | (tx & (~rx))));

always_ff @(posedge clk) begin
  if (~rst_n)
    resync_delay <= 3'h0;
  else if (do_resync & is_tseg1_tx) begin // when transmitting 0 with positive error delay is set to 0
    resync_delay <= (tq_counter_ff > {3'h0, reg2tim.sjw}) 
                     ? ({1'h0, reg2tim.sjw} + 1'b1) : (tq_counter_ff[2:0]);
  end else if (reset_resync_delay) // (go_sync | go_seg1)
    resync_delay <= 3'h0;
end


always_ff @(posedge clk) begin
  if (~rst_n) begin
      bit_sample_point <= 1'b0;
      rx_sample_curr <= 1'b1;
      rx_sample_prev <= 1'b1; 
  end else if (go_error_frame) begin
      bit_sample_point <= 1'b0;
      rx_sample_prev <= rx_sample_curr;
  end else if (end_of_tseg1) begin   
       bit_sample_point <= 1'b1;
       rx_sample_prev <= rx_sample_curr;
       rx_sample_curr <= rx;      
  end else
    bit_sample_point <= 1'b0;
end

// Determine bit start time to initiate bit transmission
always_ff @(posedge clk) begin
  if (~rst_n)
    bit_start_point <= 1'b0;
  else
    bit_start_point <= ((~bit_start_point) & tq_clk_ff & tseg2_active_flag 
                       & (end_of_tseg2 | do_resync | do_hard_sync));
end


assign tseg1_active_flag = (~do_hard_sync) & (bit_phase_ff == BIT_PHASE_TSEG1);
assign tseg2_active_flag = (bit_phase_ff == BIT_PHASE_TSEG2);

// End of bit-time phases
assign end_of_tseg1 = (tq_counter_ff == ({1'h0, reg2tim.tseg1} + resync_delay)) 
                      & tseg1_active_flag & tq_clk_ff;
assign end_of_tseg2 = (tq_counter_ff[2:0] == reg2tim.tseg2) & tseg2_active_flag;

// State register update
always_ff @(posedge clk) begin
    if (~rst_n) begin
        bit_phase_ff <= BIT_PHASE_TSEG1; 
    end else begin
        bit_phase_ff <= bit_phase_next;      
    end
end

// Next state and output evaluations
always_comb begin
    bit_phase_next     = bit_phase_ff;
    start_of_sync      = 1'b0; 
    start_of_tseg1     = 1'b0;
    start_of_tseg2     = 1'b0;
                                     
    case (bit_phase_ff)
        BIT_PHASE_SYNC : begin            
            if (tq_clk_ff) begin 
                bit_phase_next = BIT_PHASE_TSEG1;
                start_of_tseg1   = 1'b1;  
            end
	end
	
        BIT_PHASE_TSEG1 : begin
            if (end_of_tseg1) begin
                bit_phase_next = BIT_PHASE_TSEG2;
                start_of_tseg2 = 1'b1;                                     
            end               
        end
	
	BIT_PHASE_TSEG2 : begin   		
            if (tq_clk_ff & (do_hard_sync | ((do_resync | latched_resync) & sync_window))) begin
                bit_phase_next = BIT_PHASE_TSEG1;  
                start_of_tseg1 = 1'b1;                                 
            end else begin
                if (tq_clk_ff & end_of_tseg2 & (~do_hard_sync) & (~do_resync)) begin
                   bit_phase_next = BIT_PHASE_SYNC;
                   start_of_sync  = 1'b1;                                                                    
                end
            end             
        end

        default            : begin        end        
    endcase
end

assign reset_tq_counter   = start_of_sync | start_of_tseg1 | start_of_tseg2;
assign reset_resync_delay = start_of_sync | start_of_tseg1;

// Bit synchronization both at the start as well as during frame transmission
assign do_hard_sync  = (rx_idle | rx_inter) & (~rx) & rx_sample_curr & (allow_hard_sync);  
assign do_resync     = (~rx_idle) & (~rx_inter) & (~rx) & rx_sample_curr & (allow_resync);      
assign resync_window = ((reg2tim.tseg2 - tq_counter_ff[2:0]) < ({1'h0, reg2tim.sjw} + 1'b1));

always_ff @(posedge clk) begin
  if (~rst_n)
    latched_resync <= 1'b0;
  else if (do_resync & tseg2_active_flag & (~resync_window))
    latched_resync <= 1'b1;
  else if (start_of_tseg1)
    latched_resync <= 1'b0;
end

// Based on the frame and error type, determine the next value thta will driven on the TX line
always_ff @(posedge clk) begin
  if (~rst_n)
    tx_sample_next <= 1'b0;
  else if (go_overload_frame | (go_error_frame & (~node_error_passive)) | go_tx | send_ack)
    tx_sample_next <= 1'b0;
  else if (go_error_frame & node_error_passive)
    tx_sample_next <= 1'b1;
  else if (bit_sample_point)
    tx_sample_next <= tx_next;
end

/* Blocking synchronization (can occur only once in a bit time) */
always_ff @(posedge clk) begin
  if (~rst_n)
    allow_resync <= 1'b0;
  else if (tq_clk_ff & do_resync)
    allow_resync <= 1'b0;
  else if (start_of_tseg2)
    allow_resync <= 1'b1;
end

always_ff @(posedge clk) begin
  if (~rst_n) 
    allow_hard_sync <= 1'b1;
  else if (do_hard_sync & tq_clk_ff | (transmitting & transmitter | go_tx) & bit_start_point & (~tx_next))
    allow_hard_sync <= 1'b0;
  else if (go_rx_inter | (rx_idle | rx_inter) & bit_sample_point & rx_sample_curr)  
    allow_hard_sync <= 1'b1;
end

// Update the outputs
assign  sample_point  = bit_sample_point;
assign  sampled_bit   = rx_sample_curr;
assign  sampled_bit_q = rx_sample_prev;
assign  tx_point      = bit_start_point;
assign  hard_sync     = do_hard_sync;


endmodule
