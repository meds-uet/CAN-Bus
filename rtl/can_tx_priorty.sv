//Copyright 2025 Maktab-e-Digital Systems Lahore.
//Liscensed under the Apache Liscense, Version 2.0, see LISCENSE file for details.
//SPDX-Liscense-Identifier: Apache-2.0

//Description:This module buffers multiple CAN transmit requests and
// always selects the one with the lowest CAN ID (highest priority) for transmission.

//Author: Ayesha Qadir
//Date: 15 July,2025

`include "can_defs.svh"
module can_tx_priority #(parameter N = 4) (

  input  logic clk,              // Clock signal
  input  logic rst,              // Asynchronous reset

  // New transmission request
  input  logic        tx_request,        // Assert this to send a new message
  input  logic [10:0] req_id,            // CAN ID of the message
  input  logic [3:0]  req_dlc,           // Data Length Code (how many bytes)
  input  logic [7:0]  req_data [8],      // Data bytes (max 8 bytes)
  input  logic        tx_done,           // Asserted when message has been transmitted

  // Output: next message to transmit
  output logic        start_tx,          // Signal to start transmission
  output logic [10:0] tx_id,             // ID of message to transmit
  output logic [3:0]  tx_dlc,            // Data Length Code
  output logic [7:0]  tx_data [8]        // Data bytes to send
);

  localparam int CLOG2_N = 
  (N <= 2) ? 1 :
  (N <= 4) ? 2 :
  (N <= 8) ? 3 :
  (N <= 16) ? 4 :
  (N <= 32) ? 5 :
  (N <= 64) ? 6 :
  (N <= 128) ? 7 :
  (N <= 256) ? 8 : 9;

  tx_req_t tx_reqs [N];
  logic [CLOG2_N:0] i_sel;


// --- Insert new TX request or clear completed one ---
  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      // On reset, clear all request slots
      for (int i = 0; i < N; i++) begin
        tx_reqs[i].valid <= 0;
      end
    end else begin
      // Insert a new request if tx_request is high
      if (tx_request) begin
        for (int i = 0; i < N; i++) begin
          if (!tx_reqs[i].valid) begin
            tx_reqs[i].valid <= 1;
            tx_reqs[i].id    <= req_id;
            tx_reqs[i].dlc   <= req_dlc;
            for (int j = 0; j < 8; j++) begin
              tx_reqs[i].data[j] <= req_data[j];
            end
            break; // Stop after inserting one request
          end
        end
      end

      // Clear the selected request when transmission is done
      if (tx_done && tx_reqs[i_sel].valid) begin
        tx_reqs[i_sel].valid <= 0;
      end
    end
  end

  // --- Select the request with the lowest ID (highest priority) ---
  always_comb begin
    i_sel = 0; // Default to index 0
    for (int i = 1; i < N; i++) begin
      // Choose the request with the lowest ID among valid entries
      if (tx_reqs[i].valid &&
         (!tx_reqs[i_sel].valid || tx_reqs[i].id < tx_reqs[i_sel].id)) begin
        i_sel = i;
      end
    end
  end

  // --- Output the selected request ---
always_comb begin
  if (tx_reqs[i_sel].valid) begin
    tx_id    = tx_reqs[i_sel].id;
    tx_dlc   = tx_reqs[i_sel].dlc;
    start_tx = 1;
    for (int j = 0; j < 8; j++) begin
      tx_data[j] = tx_reqs[i_sel].data[j];
    end
  end else begin
    tx_id    = '0;
    tx_dlc   = '0;
    start_tx = 0;
    for (int j = 0; j < 8; j++) begin
      tx_data[j] = '0;
    end
  end
end


endmodule
