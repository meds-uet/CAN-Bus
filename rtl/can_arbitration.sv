// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0

// Description:  Detects arbitration loss in CAN protocol when transmitter sends dominant 
//but receives recessive during the arbitration phase.

// Author: Dr Tahir
// Date: 21 July, 2025


`include "can_defs.svh"

module can_arbitration (
    input  logic clk,
    input  logic rst_n,
    input  logic tx_bit,
    input  logic rx_bit,
    input  logic sample_point,
    input  logic arbitration_active,
    output logic arbitration_lost
);

    logic lost_ff;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            lost_ff <= 1'b0;
        else if (arbitration_active && sample_point && (tx_bit == 1'b1) && (rx_bit == 1'b0))
            lost_ff <= 1'b1;
        else if (!arbitration_active)
            lost_ff <= 1'b0;
    end

    assign arbitration_lost = lost_ff;

endmodule
