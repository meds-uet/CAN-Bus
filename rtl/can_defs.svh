// Copyright 2023 University of Engineering and Technology Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description:  
//
// Author: Muhammad Tahir, UET Lahore
// Date: 1.1.2025


`ifndef CAN_DEFS
`define CAN_DEFS


typedef struct packed {
    logic [28:0] id;           // Extended CAN ID (29-bit)
    logic        srtr;         // Substitute Remote Transmission Request (SRTR) bit
    logic        ide;          // Identifier Extension (IDE) bit (1 = Extended, 0 = Standard)
    logic        r0;           // Reserved bit
    logic        r1;           // Reserved bit
    logic [3:0]  dlc;          // Data Length Code (DLC) (0-8 bytes)
    logic [63:0] data;         // Data field (up to 8 bytes)
    logic [15:0] crc;          // Cyclic Redundancy Check (CRC) field
    logic        ack;          // Acknowledge bit
    logic        eof;          // End of Frame (EOF) bit
} can_ext_frame_t;


typedef enum logic [3:0] {
    CAN_IDLE          = 4'b0000, // Waiting for a start of frame
    CAN_ARBITRATION   = 4'b0001, // Receiving identifier and arbitration bits
    CAN_CONTROL       = 4'b0010, // Receiving control field (DLC, IDE, RTR, etc.)
    CAN_DATA          = 4'b0011, // Receiving data field (if applicable)
    CAN_CRC           = 4'b0100, // Receiving CRC field
    CAN_ACK           = 4'b0101, // Waiting for ACK slot
    CAN_EOF           = 4'b0110, // Receiving End of Frame (EOF)
    CAN_INTERMISSION  = 4'b0111, // Waiting in intermission state before next frame
    CAN_ERROR         = 4'b1000, // Handling an error frame
    CAN_OVERLOAD      = 4'b1001  // Handling an overload condition
} can_rx_state_t;


typedef enum logic [2:0] {
    CAN_DATA_FRAME      = 3'b000,  // Standard Data Frame
    CAN_REMOTE_FRAME    = 3'b001,  // Standard Remote Frame
    CAN_EXT_DATA_FRAME  = 3'b010,  // Extended Data Frame
    CAN_EXT_REMOTE_FRAME = 3'b011, // Extended Remote Frame
    CAN_ERROR_FRAME     = 3'b100,  // Error Frame
    CAN_OVERLOAD_FRAME  = 3'b101,  // Overload Frame
    CAN_UNKNOWN_FRAME   = 3'b111   // Undefined or Unknown Frame Type
} can_frame_type_t;

// Definitions for different privilege modes 
typedef enum logic[1:0] {
    BIT_PHASE_SYNC  = 2'b00,
    BIT_PHASE_TSEG1 = 2'b01,
    BIT_PHASE_TSEG2 = 2'b10
} type_can_bit_phase_e;

typedef struct packed {
    logic [5:0]                 baud_prescaler;
    logic [3:0]                 tseg1;
    logic [2:0]                 tseg2;
    logic [1:0]                 sjw;
} type_reg2tim_s;

 // Structure for a transmission request
  typedef struct {
    logic [10:0] id;           // CAN ID
    logic [3:0]  dlc;          // Data Length Code
    logic [7:0]  data [8];     // Data bytes
    logic        valid;        // Valid bit: 1 means occupied, 0 means free
  } tx_req_t;


`endif // CAN_DEFS
