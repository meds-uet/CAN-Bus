// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0

// Description: can_tx_priority — Buffers multiple CAN transmit requests, 
// always transmitting the lowest CAN ID (highest priority) first,
// with preemption support for new higher-priority messages and automatic buffer reordering.

// Author: Ayesha Qadir
// Date: 15 July, 2025

`include "can_defs.svh"

module can_tx_priority #(
  parameter int N = 8
)(
  input  logic clk,
  input  logic rst,

  // Write control
  input  logic        we,         // Write enable
  input  logic [10:0] req_id,
  input  logic [3:0]  req_dlc,
  input  logic [7:0]  req_data [0:7],

  // Read control (transmission done)
  input  logic        re,         // Read enable

  // Output: currently transmitting message
  output logic        start_tx,
  output logic [10:0] tx_id,
  output logic [3:0]  tx_dlc,
  output logic [7:0]  tx_data [8],

  // Status
  output logic        full,
  output logic        empty
);

  tx_req_t tx_reqs [N];  // Buffer
  tx_req_t tx_reg;       // Currently transmitting frame
  int count;            // Buffer entry count
  int pos_1,pos_2;
  tx_req_t new_req;


  always_comb begin
   new_req.valid = we;  // only valid when we is asserted
  new_req.id    = req_id;
  new_req.dlc   = req_dlc;
  for (int j = 0; j < 8; j++) begin
    new_req.data[j] = req_data[j];
  end
end



  always_ff @(posedge clk or posedge rst) begin
    if (rst) begin
      tx_reg.valid <= 0;
      count        <= 0;
      for (int i = 0; i < N; i++) begin
        tx_reqs[i].valid <= 0;
      end
    end else begin
      // WRITE OPERATION 
      
      if (we && count < N) begin
      
        if (!tx_reg.valid) begin
          // If TX is idle, put directly into tx_reg
          tx_reg <= new_req;
        end
        else if (new_req.id < tx_reg.id) begin
          // Preemption: shift buffer up and insert old tx_reg
          
          pos_1 <= 0;
          while (pos_1 < count && tx_reqs[pos_1].id <= tx_reg.id) begin
            pos_1 <= pos_1+1;
          end
          for (int i = count; i > pos_1; i--) begin
            tx_reqs[i] <= tx_reqs[i-1];
          end
          tx_reqs[pos_1] <= tx_reg;
          count        <= count + 1;

          // Replace tx_reg with new high-priority request
          tx_reg <= new_req;
        end
        else begin
          // Normal insert into buffer (sorted by ID)
          pos_2 <= 0;
          while (pos_2 < count && tx_reqs[pos_2].id <= new_req.id) begin
            pos_2 <= pos_2+1;
          end
          for (int i = count; i > pos_2; i--) begin
            tx_reqs[i] <= tx_reqs[i-1];
          end
          tx_reqs[pos_2] <= new_req;
          count        <= count + 1;
        end
      end

      // READ OPERATION 
      if (re) begin
        if (count > 0) begin
          // Move first buffer entry into tx_reg
          tx_reg <= tx_reqs[0];
          // Shift buffer up
          for (int i = 0; i < count-1; i++) begin
            tx_reqs[i] <= tx_reqs[i+1];
          end
          tx_reqs[count-1].valid <= 0;
          count                  <= count - 1;
        end else begin
          // No more data
          tx_reg.valid <= 0;
        end
      end
    end
  end

  // Status flags
  always_comb begin
    full  = (count == N);
    empty = (!tx_reg.valid && count == 0);
  end

  // Output from tx_reg
  always_comb begin
    if (tx_reg.valid) begin
      start_tx = 1;
      tx_id    = tx_reg.id;
      tx_dlc   = tx_reg.dlc;
      for (int j = 0; j < 8; j++) begin
        tx_data[j] = tx_reg.data[j];
      end
    end else begin
      start_tx = 0;
      tx_id    = '0;
      tx_dlc   = '0;
      for (int j = 0; j < 8; j++) begin
        tx_data[j] = '0;
      end
    end
  end

endmodule
