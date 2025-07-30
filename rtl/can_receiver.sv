`timescale 1ns / 10ps
`include "can_defs.svh"

module can_receiver (
  input  logic        clk,
  input  logic        rst_n,
  input  logic        rx_point,
  input  logic        rx_bit,

  output logic [10:0] rx_id_std,
  output logic [17:0] rx_id_ext,
  output logic        rx_ide,
  output logic        rx_rtr,
  output logic [3:0]  rx_dlc,
  output logic [7:0]  rx_data [0:7],
  output logic [14:0] rx_crc,
  output logic        rx_done
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

  state_t rx_state_ff, rx_state_next;
  logic [5:0] bit_cnt_ff, bit_cnt_next;
  logic [3:0] byte_cnt_ff, byte_cnt_next;
  logic [7:0] data_byte_ff, data_byte_next;
  logic wr_rx_data_byte;
  logic rx_done_flag, rx_done_ff;

  // Frame fields
  logic [10:0] rx_id_std_ff;
  logic [17:0] rx_id_ext_ff;
  logic        rx_ide_ff;
  logic        rx_rtr_ff;
  logic [3:0]  rx_dlc_ff;
  logic [14:0] rx_crc_ff;
  logic [7:0]  rx_data_array [0:7];

  assign rx_id_std = rx_id_std_ff;
  assign rx_id_ext = rx_id_ext_ff;
  assign rx_ide    = rx_ide_ff;
  assign rx_rtr    = rx_rtr_ff;
  assign rx_dlc    = rx_dlc_ff;
  assign rx_crc    = rx_crc_ff;
  assign rx_done   = rx_done_ff;

  // State register
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
      rx_state_ff   <= STATE_IDLE;
      bit_cnt_ff    <= 0;
      byte_cnt_ff   <= 0;
      data_byte_ff  <= 0;
      rx_id_std_ff  <= 0;
      rx_id_ext_ff  <= 0;
      rx_rtr_ff     <= 0;
      rx_ide_ff     <= 0;
      rx_dlc_ff     <= 0;
      rx_crc_ff     <= 0;
    end else if (rx_point) begin
      rx_state_ff   <= rx_state_next;
      bit_cnt_ff    <= bit_cnt_next;
      byte_cnt_ff   <= byte_cnt_next;
      data_byte_ff  <= data_byte_next;

      case (rx_state_ff)
        STATE_ID_STD:    rx_id_std_ff  <= {rx_id_std_ff[9:0], rx_bit};
        STATE_ID_EXT:    rx_id_ext_ff  <= {rx_id_ext_ff[16:0], rx_bit};
        STATE_BIT_RTR_1,
        STATE_BIT_RTR_2: rx_rtr_ff     <= rx_bit;
        STATE_BIT_IDE:   rx_ide_ff     <= rx_bit;
        STATE_DLC:       rx_dlc_ff     <= {rx_dlc_ff[2:0], rx_bit};
        STATE_CRC:       rx_crc_ff     <= {rx_crc_ff[13:0], rx_bit};
        default: ;
      endcase
    end
  end

  // Data buffer
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      for (int i = 0; i < 8; i++) rx_data_array[i] <= 8'h00;
    else if (rx_point && wr_rx_data_byte)
      rx_data_array[byte_cnt_ff] <= data_byte_next;
  end

  // Output done flag
  always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n)
      rx_done_ff <= 0;
    else
      rx_done_ff <= rx_done_flag;
  end

  // FSM logic
  always_comb begin
    rx_state_next   = rx_state_ff;
    bit_cnt_next    = bit_cnt_ff;
    byte_cnt_next   = byte_cnt_ff;
    data_byte_next  = data_byte_ff;
    wr_rx_data_byte = 0;
    rx_done_flag    = 0;

    case (rx_state_ff)
      STATE_IDLE: begin
        if (!rx_bit)
          rx_state_next = STATE_ID_STD;
      end

      STATE_ID_STD: begin
        bit_cnt_next++;
        if (bit_cnt_ff == 10)
          rx_state_next = STATE_BIT_RTR_1;
      end

      STATE_BIT_RTR_1: rx_state_next = STATE_BIT_IDE;

      STATE_BIT_IDE: begin
        rx_state_next = rx_bit ? STATE_ID_EXT : STATE_BIT_R_0;
        bit_cnt_next = 0;
      end

      STATE_ID_EXT: begin
        bit_cnt_next++;
        if (bit_cnt_ff == 17)
          rx_state_next = STATE_BIT_RTR_2;
      end

      STATE_BIT_RTR_2: rx_state_next = STATE_BIT_R_1;
      STATE_BIT_R_1:   rx_state_next = STATE_BIT_R_0;
      STATE_BIT_R_0: begin
        rx_state_next = STATE_DLC;
        bit_cnt_next = 0;
      end

      STATE_DLC: begin
        bit_cnt_next++;
        if (bit_cnt_ff == 3) begin
          rx_state_next = (rx_dlc_ff == 0) ? STATE_CRC : STATE_DATA;
          byte_cnt_next = 0;
          bit_cnt_next  = 0;
        end
      end

      STATE_DATA: begin
        data_byte_next = {data_byte_ff[6:0], rx_bit};
        bit_cnt_next++;
        if (bit_cnt_ff[2:0] == 3'd7) begin
          wr_rx_data_byte = 1;
          byte_cnt_next++;
          if (byte_cnt_ff == rx_dlc_ff - 1) begin
            rx_state_next = STATE_CRC;
            bit_cnt_next = 0;
          end
        end
      end

      STATE_CRC: begin
        bit_cnt_next++;
        if (bit_cnt_ff == 14)
          rx_state_next = STATE_CRC_DELIMIT;
      end

      STATE_CRC_DELIMIT: begin
        rx_state_next = STATE_ACK;
      end

      STATE_ACK: rx_state_next = STATE_ACK_DELIMIT;

      STATE_ACK_DELIMIT: begin
        rx_state_next = STATE_EOF;
        bit_cnt_next = 0;
      end

      STATE_EOF: begin
        bit_cnt_next++;
        if (bit_cnt_ff == 6) begin
          rx_state_next = STATE_IFS;
          bit_cnt_next = 0;
        end
      end

      STATE_IFS: begin
        bit_cnt_next++;
        if (bit_cnt_ff == 2) begin
          rx_done_flag = 1;
          rx_state_next = STATE_IDLE;
        end
      end

      default: rx_state_next = STATE_IDLE;
    endcase
  end

  // Output data
  genvar i;
  generate
    for (i = 0; i < 8; i++) begin
      assign rx_data[i] = rx_data_array[i];
    end
  endgenerate

endmodule
