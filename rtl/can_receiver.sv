// Copyright 2025 Maktab-e-Digital Systems Lahore.
// Licensed under the Apache License, Version 2.0, see LICENSE file for details.
// SPDX-License-Identifier: Apache-2.0

// Description:  Implements a CAN 2.0A/B receiver FSM that de-stuffs bits and 
//reconstructs  frame (ID, DLC, data, RTR, IDE).

// Author: Dr Tahir
// Date: 21 July, 2025



`timescale 1ns/10ps
`include "can_defs.svh"

module can_receiver (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        sampled_bit,
  input  logic        sampled_bit_q,
  input  logic        sample_point,
  input  logic        rx_point,

  output logic [10:0] rx_id_std,
  output logic        rx_rtr1,
  output logic        rx_ide,
  output logic [3:0]  rx_dlc,
  output logic [14:0] rx_crc,
  output logic [7:0]  rx_data [0:7],
  output logic        rx_done
);

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

  type_can_frame_states_e rx_state_ff, rx_state_next;
  logic [5:0]  rx_bit_cnt_ff, rx_bit_cnt_next;
  logic [2:0]  bit_de_stuff_counter_ff, bit_de_stuff_counter_next;
  logic        bit_de_stuffing_ff, bit_de_stuffing_next;
  logic        rx_bit_prev, rx_bit_curr;
  logic        remove_stuff_bit;

  logic [10:0] id_std_ff;
  logic        rtr1_ff, ide_ff;
  logic [17:0] id_ext_ff;
  logic        rtr2_ff;
  logic [3:0]  dlc_ff;
  logic [7:0]  rx_data_array [0:7];
  logic [14:0] crc_ff;
  logic [7:0]  data_byte_ff, data_byte_next;
  logic [3:0]  byte_cnt_ff, byte_cnt_next;
  logic        wr_rx_data_byte;
  logic        rx_done_flag;
  logic        rx_done_ff;
  logic        rx_remote_req;

  assign rx_bit_curr = sampled_bit;
  assign rx_bit_prev = sampled_bit_q;
  assign rx_remote_req = ((~ide_ff) & rtr1_ff) | (ide_ff & rtr2_ff);
  assign rx_done = rx_done_ff;

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      bit_de_stuffing_ff <= 1'b0;
    else
      bit_de_stuffing_ff <= bit_de_stuffing_next;
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      bit_de_stuff_counter_ff <= 3'h1;
    else
      bit_de_stuff_counter_ff <= bit_de_stuff_counter_next;
  end

  always_comb begin
    bit_de_stuff_counter_next = bit_de_stuff_counter_ff;
    if (rx_state_ff == STATE_IDLE)
      bit_de_stuff_counter_next = 3'h1;
    else if (rx_point && bit_de_stuffing_ff) begin
      if (bit_de_stuff_counter_ff == 3'h5)
        bit_de_stuff_counter_next = 3'h1;
      else if (rx_bit_curr == rx_bit_prev)
        bit_de_stuff_counter_next = bit_de_stuff_counter_ff + 1;
      else
        bit_de_stuff_counter_next = 3'h1;
    end
  end

  assign remove_stuff_bit = (bit_de_stuff_counter_ff == 3'h5) && (rx_state_ff != STATE_CRC);

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state_ff   <= STATE_IDLE;
      rx_bit_cnt_ff <= 0;
      byte_cnt_ff   <= 0;
      id_std_ff     <= 0;
      rtr1_ff       <= 0;
      ide_ff        <= 0;
      id_ext_ff     <= 0;
      rtr2_ff       <= 0;
      dlc_ff        <= 0;
      crc_ff        <= 0;
      data_byte_ff  <= 0;
    end else if (rx_point && ~remove_stuff_bit) begin
      rx_state_ff   <= rx_state_next;
      rx_bit_cnt_ff <= rx_bit_cnt_next;
      byte_cnt_ff   <= byte_cnt_next;
      data_byte_ff  <= data_byte_next;
      case (rx_state_ff)
        STATE_ID_STD:     id_std_ff  <= {id_std_ff[9:0], rx_bit_curr};
        STATE_BIT_RTR_1:  rtr1_ff    <= rx_bit_curr;
        STATE_BIT_IDE:    ide_ff     <= rx_bit_curr;
        STATE_ID_EXT:     id_ext_ff  <= {id_ext_ff[16:0], rx_bit_curr};
        STATE_BIT_RTR_2:  rtr2_ff    <= rx_bit_curr;
        STATE_DLC:        dlc_ff     <= {dlc_ff[2:0], rx_bit_curr};
        STATE_CRC:        crc_ff     <= {crc_ff[13:0], rx_bit_curr};
        default: ;
      endcase
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      for (int i = 0; i < 8; i++) rx_data_array[i] <= 8'h00;
    end else if (rx_point && wr_rx_data_byte) begin
      rx_data_array[byte_cnt_ff] <= data_byte_next;
    end
  end

  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      rx_done_ff <= 0;
    else
      rx_done_ff <= rx_done_flag;
  end

  always_comb begin
    rx_state_next = rx_state_ff;
    rx_bit_cnt_next = rx_bit_cnt_ff;
    byte_cnt_next = byte_cnt_ff;
    data_byte_next = data_byte_ff;
    wr_rx_data_byte = 0;
    bit_de_stuffing_next = bit_de_stuffing_ff;
    rx_done_flag = 0;

    case (rx_state_ff)
      STATE_IDLE: begin
        bit_de_stuffing_next = 0;
        if (~rx_bit_curr) begin
          rx_state_next = STATE_ID_STD;
          rx_bit_cnt_next = 0;
          bit_de_stuffing_next = 1;
        end
      end

      STATE_ID_STD: begin
        rx_bit_cnt_next = rx_bit_cnt_ff + 1;
        if (rx_bit_cnt_ff == 10)
          rx_state_next = STATE_BIT_RTR_1;
      end

      STATE_BIT_RTR_1: begin
        rx_state_next = STATE_BIT_IDE;
        rx_bit_cnt_next = 0;
      end

      STATE_BIT_IDE: begin
        rx_state_next = rx_bit_curr ? STATE_ID_EXT : STATE_BIT_R_0;
        rx_bit_cnt_next = 0;
      end

      STATE_ID_EXT: begin
        rx_bit_cnt_next = rx_bit_cnt_ff + 1;
        if (rx_bit_cnt_ff == 17)
          rx_state_next = STATE_BIT_RTR_2;
      end

      STATE_BIT_RTR_2: begin
        rx_state_next = STATE_BIT_R_1;
        rx_bit_cnt_next = 0;
      end

      STATE_BIT_R_1: begin
        rx_state_next = STATE_BIT_R_0;
      end

      STATE_BIT_R_0: begin
        rx_state_next = STATE_DLC;
        rx_bit_cnt_next = 0;
      end

      STATE_DLC: begin
        rx_bit_cnt_next = rx_bit_cnt_ff + 1;
        if (rx_bit_cnt_ff == 3) begin
          rx_state_next = rx_remote_req ? STATE_CRC : STATE_DATA;
          rx_bit_cnt_next = 0;
        end
      end

      STATE_DATA: begin
        data_byte_next = {data_byte_ff[6:0], rx_bit_curr};
        rx_bit_cnt_next = rx_bit_cnt_ff + 1;
        if (rx_bit_cnt_ff[2:0] == 3'd7) begin
          wr_rx_data_byte = 1;
          byte_cnt_next = byte_cnt_ff + 1;
          if (byte_cnt_ff == (dlc_ff - 1)) begin
            rx_state_next = STATE_CRC;
            byte_cnt_next = 0;
            rx_bit_cnt_next = 0;
          end
        end
      end

      STATE_CRC: begin
        rx_bit_cnt_next = rx_bit_cnt_ff + 1;
        if (rx_bit_cnt_ff == 14)
          rx_state_next = STATE_CRC_DELIMIT;
      end

      STATE_CRC_DELIMIT: begin
        rx_state_next = STATE_ACK;
        bit_de_stuffing_next = 0;
        rx_bit_cnt_next = 0;
      end

      STATE_ACK: begin
        rx_state_next = STATE_ACK_DELIMIT;
      end

      STATE_ACK_DELIMIT: begin
        rx_state_next = STATE_EOF;
        rx_bit_cnt_next = 0;
      end

      STATE_EOF: begin
        rx_bit_cnt_next = rx_bit_cnt_ff + 1;
        if (rx_bit_cnt_ff == 6) begin
          rx_state_next = STATE_IFS;
          rx_bit_cnt_next = 0;
        end
      end

      STATE_IFS: begin
        rx_bit_cnt_next = rx_bit_cnt_ff + 1;
        if (rx_bit_cnt_ff == 2) begin
          rx_state_next = STATE_IDLE;
          rx_done_flag = 1;
        end
      end

      default: rx_state_next = STATE_IDLE;
    endcase
  end

  assign rx_id_std = id_std_ff;
  assign rx_rtr1   = rtr1_ff;
  assign rx_ide    = ide_ff;
  assign rx_dlc    = dlc_ff;
  assign rx_crc    = crc_ff;

  genvar i;
  generate
    for (i = 0; i < 8; i++) begin
      assign rx_data[i] = rx_data_array[i];
    end
  endgenerate

endmodule
