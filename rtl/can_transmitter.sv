`timescale 1ns / 10ps
`include "can_defs.svh"

module can_transmitter (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        tx_enable,
  input  logic        tx_point,
  input  logic        initiate,
  input  logic [10:0] tx_id_std,
  input  logic [17:0] tx_id_ext,
  input  logic        tx_ide,
  input  logic        tx_rtr,
  input  logic [3:0]  tx_dlc,
  input  logic [7:0]  tx_data [0:7],
  input  logic [14:0] tx_crc,
  output logic        tx_bit,
  output logic        tx_done
);

  typedef enum logic [4:0] {
    STATE_IDLE,
    STATE_SOF,
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
  } state_t;

  state_t tx_state_ff, tx_state_next;
  logic [5:0]  bit_cnt_ff, bit_cnt_next;
  logic [3:0]  byte_cnt_ff, byte_cnt_next;
  logic        current_bit, tx_done_ff;

  assign tx_done = tx_done_ff;

  // === FSM + Counters ===
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || initiate) begin
      tx_state_ff <= STATE_IDLE;
      bit_cnt_ff  <= 0;
      byte_cnt_ff <= 0;
    end else if (tx_point) begin
      tx_state_ff <= tx_state_next;
      bit_cnt_ff  <= bit_cnt_next;
      byte_cnt_ff <= byte_cnt_next;
    end
  end

  // === FSM logic and bit generation ===
  always_comb begin
    tx_state_next  = tx_state_ff;
    bit_cnt_next   = bit_cnt_ff;
    byte_cnt_next  = byte_cnt_ff;
    current_bit    = 1'b1;
    tx_done_ff     = 1'b0;

    case (tx_state_ff)
      STATE_IDLE: begin
        if (tx_enable)
          tx_state_next = STATE_SOF;
      end

      STATE_SOF: begin
        current_bit = 1'b0;
        tx_state_next = STATE_ID_STD;
        bit_cnt_next = 0;
      end

      STATE_ID_STD: begin
        current_bit = tx_id_std[10 - bit_cnt_ff];
        bit_cnt_next = bit_cnt_ff + 1;
        if (bit_cnt_ff == 10)
          tx_state_next = STATE_BIT_RTR_1;
      end

      STATE_BIT_RTR_1: begin
        current_bit = tx_rtr;
        tx_state_next = STATE_BIT_IDE;
      end

      STATE_BIT_IDE: begin
        current_bit = tx_ide;
        tx_state_next = tx_ide ? STATE_ID_EXT : STATE_BIT_R_0;
        bit_cnt_next = 0;
      end

      STATE_ID_EXT: begin
        current_bit = tx_id_ext[17 - bit_cnt_ff];
        bit_cnt_next = bit_cnt_ff + 1;
        if (bit_cnt_ff == 17)
          tx_state_next = STATE_BIT_RTR_2;
      end

      STATE_BIT_RTR_2: begin
        current_bit = tx_rtr;
        tx_state_next = STATE_BIT_R_1;
      end

      STATE_BIT_R_1: begin
        current_bit = 1'b0;
        tx_state_next = STATE_BIT_R_0;
      end

      STATE_BIT_R_0: begin
        current_bit = 1'b0;
        tx_state_next = STATE_DLC;
        bit_cnt_next = 0;
      end

      STATE_DLC: begin
        current_bit = tx_dlc[3 - bit_cnt_ff];
        bit_cnt_next = bit_cnt_ff + 1;
        if (bit_cnt_ff == 3) begin
          tx_state_next = (tx_dlc == 0) ? STATE_CRC : STATE_DATA;
          if (tx_dlc > 0)
            byte_cnt_next = 0;
        end
      end

      STATE_DATA: begin
        current_bit = tx_data[byte_cnt_ff][7 - bit_cnt_ff[2:0]];
        bit_cnt_next = bit_cnt_ff + 1;
        if (bit_cnt_ff[2:0] == 3'd7) begin
          if (byte_cnt_ff == tx_dlc - 1)
            tx_state_next = STATE_CRC;
          else
            byte_cnt_next = byte_cnt_ff + 1;
        end
      end

      STATE_CRC: begin
        current_bit = tx_crc[14 - bit_cnt_ff];
        bit_cnt_next = bit_cnt_ff + 1;
        if (bit_cnt_ff == 14)
          tx_state_next = STATE_CRC_DELIMIT;
      end

      STATE_CRC_DELIMIT: begin
        current_bit = 1'b1;
        tx_state_next = STATE_ACK;
      end

      STATE_ACK: begin
        current_bit = 1'b1;
        tx_state_next = STATE_ACK_DELIMIT;
      end

      STATE_ACK_DELIMIT: begin
        current_bit = 1'b1;
        tx_state_next = STATE_EOF;
        bit_cnt_next = 0;
      end

      STATE_EOF: begin
        current_bit = 1'b1;
        bit_cnt_next = bit_cnt_ff + 1;
        if (bit_cnt_ff == 6)
          tx_state_next = STATE_IFS;
      end

      STATE_IFS: begin
        current_bit = 1'b1;
        bit_cnt_next = bit_cnt_ff + 1;
        if (bit_cnt_ff == 2) begin
          tx_state_next = STATE_IDLE;
          tx_done_ff = 1;
        end
      end

      default: tx_state_next = STATE_IDLE;
    endcase
  end

  // === Output ===
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n || initiate)
      tx_bit <= 1'b1;
    else if (tx_point)
      tx_bit <= current_bit;
  end

endmodule
