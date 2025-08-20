`include "can_defs.svh"
`timescale 1ns / 10ps

module can_transmitter (
  input  logic         clk,
  input  logic         rst_n,
  input  logic         sample_point,
  input  logic         start_tx,
  input  logic         tx_remote_req,
  input  logic [10:0]  tx_id_std,
  input  logic [17:0]  tx_id_ext,
  input  logic         tx_ide,
  input  logic         tx_rtr1,
  input  logic         tx_rtr2,
  input  logic [3:0]   tx_dlc,
  input  logic [14:0]  tx_crc,
  input  logic [7:0]   tx_data [0:7],
  output logic         tx_bit,
  output logic         tx_done,
  output logic         rd_tx_data_byte,
  output logic         arbitration_active
);

  can_frame_t tx_frame_local;

  assign tx_frame_local.id_std = tx_id_std;
  assign tx_frame_local.id_ext = tx_id_ext;
  assign tx_frame_local.ide    = tx_ide;
  assign tx_frame_local.rtr1   = tx_rtr1;
  assign tx_frame_local.rtr2   = tx_rtr2;
  assign tx_frame_local.dlc    = tx_dlc;
  assign tx_frame_local.crc    = tx_crc;

  always_comb begin
    for (int i = 0; i < 8; i++) begin
      tx_frame_local.data[i] = tx_data[i];
    end
  end

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
  } state_t;

  state_t tx_state_ff, tx_state_next;

  logic [5:0] tx_bit_cnt_ff, tx_bit_cnt_next;
  logic [3:0] tx_byte_cnt_ff, tx_byte_cnt_next;
  logic [7:0] tx_data_byte_ff, tx_data_byte_next;
  logic       bit_stuffing_ff, bit_stuffing_next;
  logic       tx_frame_tx_bit;

  // Sequential block
  always_ff @(posedge clk or negedge rst_n) begin
    if (rst_n) begin
      tx_state_ff       <= STATE_IDLE;
      tx_bit_cnt_ff     <= 6'd0;
      tx_byte_cnt_ff    <= 4'd0;
      tx_data_byte_ff   <= 8'd0;
      bit_stuffing_ff   <= 1'b0;
    end else if (sample_point) begin
      tx_state_ff       <= tx_state_next;
      tx_bit_cnt_ff     <= tx_bit_cnt_next;
      tx_byte_cnt_ff    <= tx_byte_cnt_next;
      tx_data_byte_ff   <= tx_data_byte_next;
      bit_stuffing_ff   <= bit_stuffing_next;
    end
  end

  // FSM logic
  always_comb begin
    tx_bit_cnt_next      = tx_bit_cnt_ff;
    tx_byte_cnt_next     = tx_byte_cnt_ff;
    tx_data_byte_next    = tx_data_byte_ff;
    tx_state_next        = tx_state_ff;
    tx_frame_tx_bit      = 1'b1;
    tx_done              = 1'b0;
    arbitration_active   = 1'b0;
    bit_stuffing_next    = bit_stuffing_ff;
    rd_tx_data_byte      = 1'b0;

    case (tx_state_ff)
      STATE_IDLE: begin
        bit_stuffing_next = 1'b0;
        if (start_tx) begin
          tx_frame_tx_bit = 1'b0;
          tx_state_next = STATE_ID_STD;
          tx_bit_cnt_next = 10;
          arbitration_active = 1'b0;
          bit_stuffing_next = 1'b1;
        end
      end

      STATE_ID_STD: begin
        arbitration_active = 1;
        tx_frame_tx_bit = tx_frame_local.id_std[tx_bit_cnt_ff];
        if (tx_bit_cnt_ff == 0)
          tx_state_next = STATE_BIT_RTR_1;
        else
          tx_bit_cnt_next = tx_bit_cnt_ff - 1;
      end

      STATE_BIT_RTR_1: begin
        arbitration_active = 1;
        tx_frame_tx_bit = tx_frame_local.rtr1;
        tx_state_next = STATE_BIT_IDE;
      end

      STATE_BIT_IDE: begin
        arbitration_active = 1;
        tx_frame_tx_bit = tx_frame_local.ide;
        if (tx_frame_local.ide) begin
          tx_state_next = STATE_ID_EXT;
          tx_bit_cnt_next = 17;
        end else begin
          arbitration_active = 0;
          tx_state_next = STATE_BIT_R_0;
        end
      end

      STATE_ID_EXT: begin
        arbitration_active = 1;
        tx_frame_tx_bit = tx_frame_local.id_ext[tx_bit_cnt_ff];
        if (tx_bit_cnt_ff == 0)
          tx_state_next = STATE_BIT_RTR_2;
        else
          tx_bit_cnt_next = tx_bit_cnt_ff - 1;
      end

      STATE_BIT_RTR_2: begin
        arbitration_active = 1;
        tx_frame_tx_bit = tx_frame_local.rtr2;
        arbitration_active = 0;
        tx_state_next = STATE_BIT_R_1;
      end

      STATE_BIT_R_1: begin
        tx_frame_tx_bit = 1'b0;
        tx_state_next = STATE_BIT_R_0;
      end

      STATE_BIT_R_0: begin
        tx_frame_tx_bit = 1'b0;
        tx_state_next = STATE_DLC;
        tx_bit_cnt_next = 3;
      end
      STATE_DLC: begin
        tx_frame_tx_bit = tx_frame_local.dlc[tx_bit_cnt_ff];
        if (tx_bit_cnt_ff == 0) begin
          if (tx_remote_req)
            tx_state_next = STATE_CRC;
          else begin
            tx_state_next = STATE_DATA;
            rd_tx_data_byte = 1'b1;  // request first byte
            tx_byte_cnt_next = 0;
            tx_bit_cnt_next = 7;     // 7 downto 0
            tx_data_byte_next = tx_frame_local.data[0];
          end
        end else
          tx_bit_cnt_next = tx_bit_cnt_ff - 1;
      end
      STATE_DATA: begin
        // Send current bit of the current byte
        tx_frame_tx_bit = tx_data_byte_ff[tx_bit_cnt_ff]; // MSB first

        if (tx_bit_cnt_ff == 0) begin
          if (tx_byte_cnt_ff == tx_frame_local.dlc - 1) begin
            // Finished all bytes
            tx_state_next    = STATE_CRC;
            tx_bit_cnt_next  = 14;
            tx_byte_cnt_next = 0;
          end else begin
            // Load next byte
            tx_byte_cnt_next  = tx_byte_cnt_ff + 1;
            tx_data_byte_next = tx_frame_local.data[tx_byte_cnt_ff + 1];
            tx_bit_cnt_next   = 7;
            rd_tx_data_byte   = 1'b1;
          end
        end else begin
          tx_bit_cnt_next = tx_bit_cnt_ff - 1;
        end
      end
      STATE_CRC: begin
        tx_frame_tx_bit = tx_frame_local.crc[tx_bit_cnt_ff];
        if (tx_bit_cnt_ff == 0)
          tx_state_next = STATE_CRC_DELIMIT;
        else
          tx_bit_cnt_next = tx_bit_cnt_ff - 1;
      end

      STATE_CRC_DELIMIT: begin
        tx_frame_tx_bit = 1'b1;
        tx_state_next = STATE_ACK;
        bit_stuffing_next = 1'b0;
      end

      STATE_ACK: begin
        tx_frame_tx_bit = 1'b1;
        tx_state_next = STATE_ACK_DELIMIT;
      end

      STATE_ACK_DELIMIT: begin
        tx_frame_tx_bit = 1'b1;
        tx_state_next = STATE_EOF;
        tx_bit_cnt_next = 6;
      end

      STATE_EOF: begin
        tx_frame_tx_bit = 1'b1;
        if (tx_bit_cnt_ff == 0) begin
          tx_state_next = STATE_IFS;
          tx_bit_cnt_next = 2;
        end else begin
          tx_bit_cnt_next = tx_bit_cnt_ff - 1;
        end
      end

      STATE_IFS: begin
        tx_frame_tx_bit = 1'b1;
        if (tx_bit_cnt_ff == 0) begin
          tx_done = 1'b1;
          tx_state_next = STATE_IDLE;
        end else begin
          tx_bit_cnt_next = tx_bit_cnt_ff - 1;
        end
      end

      default: begin
        tx_state_next = STATE_IDLE;
      end
    endcase
  end

  // Output logic
  always_ff @(posedge clk or negedge rst_n) begin
    if (rst_n)
      tx_bit <= 1'b1;
    else if (sample_point)
      tx_bit <= tx_frame_tx_bit;
  end

endmodule
