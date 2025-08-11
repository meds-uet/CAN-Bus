// Copyright 2023 University of Engineering and Technology Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0
//
// Description: CAN Protocol Definitions and Types
//
// Author: Muhammad Tahir, UET Lahore
// Date: 1.1.2025

`ifndef CAN_DEFS
`define CAN_DEFS

// Extended CAN frame (used for optional extended functionality)
typedef struct packed {
    logic [28:0] id;           // Extended CAN ID (29-bit)
    logic        srtr;         // Substitute Remote Transmission Request (SRTR) bit
    logic        ide;          // Identifier Extension (IDE) bit (1 = Extended, 0 = Standard)
    logic        r0;           // Reserved bit
    logic        r1;           // Reserved bit
    logic [3:0]  dlc;          // Data Length Code (0-8 bytes)
    logic [63:0] data;         // Flattened 8-byte data field (packed)
    logic [15:0] crc;          // CRC field
    logic        ack;          // Acknowledge bit
    logic        eof;          // End of Frame bit
} can_ext_frame_t;

// Frame classification
typedef enum logic [2:0] {
    CAN_DATA_FRAME         = 3'b000,
    CAN_REMOTE_FRAME       = 3'b001,
    CAN_EXT_DATA_FRAME     = 3'b010,
    CAN_EXT_REMOTE_FRAME   = 3'b011,
    CAN_ERROR_FRAME        = 3'b100,
    CAN_OVERLOAD_FRAME     = 3'b101,
    CAN_UNKNOWN_FRAME      = 3'b111
} can_frame_type_t;

// Receive FSM states (not used in your current FSM but included if needed)
typedef enum logic [3:0] {
    CAN_IDLE          = 4'b0000,
    CAN_ARBITRATION   = 4'b0001,
    CAN_CONTROL       = 4'b0010,
    CAN_DATA          = 4'b0011,
    CAN_CRC           = 4'b0100,
    CAN_ACK           = 4'b0101,
    CAN_EOF           = 4'b0110,
    CAN_INTERMISSION  = 4'b0111,
    CAN_ERROR         = 4'b1000,
    CAN_OVERLOAD      = 4'b1001
} can_rx_state_t;

// Bit timing phase types
typedef enum logic [1:0] {
    BIT_PHASE_SYNC   = 2'b00,
    BIT_PHASE_TSEG1  = 2'b01,
    BIT_PHASE_TSEG2  = 2'b10
} type_can_bit_phase_e;

// CAN Timing register structure
typedef struct packed {
    logic [5:0] baud_prescaler;
    logic [3:0] tseg1;
    logic [2:0] tseg2;
    logic [1:0] sjw;
} type_reg2tim_s;

// Internal CAN frame (used for TX/RX FSM logic in can_bsp.sv)
typedef struct packed {
    logic [10:0] id_std;       // Standard ID (11-bit)
    logic [17:0] id_ext;       // Extended ID (18-bit)
    logic        rtr1;         // Remote Transmission Request (standard)
    logic        rtr2;         // Remote Transmission Request (extended)
    logic        ide;          // Identifier Extension bit
    logic [3:0]  dlc;          // Data Length Code
    logic [63:0] data;         // Flattened 8-byte data
    logic [14:0] crc;          // CRC field (15 bits for standard CAN)
} can_frame_s;

// TX/RX FSM states used in datapath
typedef enum logic [4:0] {
    STATE_IDLE,
    STATE_ID_STD,
    STATE_BIT_RTR_1,
    STATE_BIT_IDE,
    STATE_ID_EXT,
    STATE_BIT_RTR_2,
    STATE_BIT_R_1,
    STATE_BIT_R_0,
    STATE_DLC,
    STATE_DATA,
    STATE_CRC,
    STATE_CRC_DELIMIT,
    STATE_ACK,
    STATE_ACK_DELIMIT,
    STATE_EOF,
    STATE_IFS
} type_can_frame_states_e;

  // Structure for a transmission request
  typedef struct {
    logic [10:0] id;           // CAN ID
    logic [3:0]  dlc;          // Data Length Code
    logic [7:0]  data [8];     // Data bytes
    logic        valid;        // Valid bit: 1 means occupied, 0 means free
  } tx_req_t;

`endif // CAN_DEFS
