`include "timescale.v"
`include "can_defs.svh"

module can_bsp
( 
  clk,
  rst,

  sample_point,
  sampled_bit,
  sampled_bit_q,
  tx_point,
  hard_sync,

  addr,
  data_in,
  data_out,
  fifo_selected,
  


  /* Mode register */
  reset_mode,
  listen_only_mode,
  acceptance_filter_mode,
  self_test_mode,

  /* Command register */
  release_buffer,
  tx_request,
  abort_tx,
  self_rx_request,
  single_shot_transmission,
  tx_state,
  tx_state_q,
  overload_request,
  overload_frame,

  /* Arbitration Lost Capture Register */
  read_arbitration_lost_capture_reg,

  /* Error Code Capture Register */
  read_error_code_capture_reg,
  error_capture_code,

  /* Error Warning Limit register */
  error_warning_limit,

  /* Rx Error Counter register */
  we_rx_err_cnt,

  /* Tx Error Counter register */
  we_tx_err_cnt,

  /* Clock Divider register */
  extended_mode,

  rx_idle,
  transmitting,
  transmitter,
  go_rx_inter,
  not_first_bit_of_inter,
  rx_inter,
  set_reset_mode,
  node_bus_off,
  error_status,
  rx_err_cnt,
  tx_err_cnt,
  transmit_status,
  receive_status,
  tx_successful,
  need_to_tx,
  overrun,
  info_empty,
  set_bus_error_irq,
  set_arbitration_lost_irq,
  arbitration_lost_capture,
  node_error_passive,
  node_error_active,
  rx_message_counter,

  /* This section is for BASIC and EXTENDED mode */
  /* Acceptance code register */
  acceptance_code_0,

  /* Acceptance mask register */
  acceptance_mask_0,
  /* End: This section is for BASIC and EXTENDED mode */
  
  /* This section is for EXTENDED mode */
  /* Acceptance code register */
  acceptance_code_1,
  acceptance_code_2,
  acceptance_code_3,

  /* Acceptance mask register */
  acceptance_mask_1,
  acceptance_mask_2,
  acceptance_mask_3,
  /* End: This section is for EXTENDED mode */
  
  /* Tx data registers. Holding identifier (basic mode), tx frame information (extended mode) and data */
  tx_data_0,
  tx_data_1,
  tx_data_2,
  tx_data_3,
  tx_data_4,
  tx_data_5,
  tx_data_6,
  tx_data_7,
  tx_data_8,
  tx_data_9,
  tx_data_10,
  tx_data_11,
  tx_data_12,
  /* End: Tx data registers */
  
  /* Tx signal */
  tx,
  tx_next,
  bus_off_on,

  go_overload_frame,
  go_error_frame,
  go_tx,
  send_ack

  /* Bist */
`ifdef CAN_BIST
  ,
  mbist_si_i,
  mbist_so_o,
  mbist_ctrl_i
`endif
);

parameter Tp = 1;

input         clk;
input         rst;
input         sample_point;
input         sampled_bit;
input         sampled_bit_q;
input         tx_point;
input         hard_sync;
input   [7:0] addr;
input   [7:0] data_in;
output  [7:0] data_out;
input         fifo_selected;

input         reset_mode;
input         listen_only_mode;
input         acceptance_filter_mode;
input         extended_mode;
input         self_test_mode;

/* Command register */
input         release_buffer;
input         tx_request;
input         abort_tx;
input         self_rx_request;
input         single_shot_transmission;
output        tx_state;
output        tx_state_q;
input         overload_request;     // When receiver is busy, it needs to send overload frame. Only 2 overload frames are allowed to
output        overload_frame;       // be send in a row. This is not implemented, yet,  because host can not send an overload request.

/* Arbitration Lost Capture Register */
input         read_arbitration_lost_capture_reg;

/* Error Code Capture Register */
input         read_error_code_capture_reg;
output  [7:0] error_capture_code;

/* Error Warning Limit register */
input   [7:0] error_warning_limit;

/* Rx Error Counter register */
input         we_rx_err_cnt;

/* Tx Error Counter register */
input         we_tx_err_cnt;

output        rx_idle;
output        transmitting;
output        transmitter;
output        go_rx_inter;
output        not_first_bit_of_inter;
output        rx_inter;
output        set_reset_mode;
output        node_bus_off;
output        error_status;
output  [8:0] rx_err_cnt;
output  [8:0] tx_err_cnt;
output        transmit_status;
output        receive_status;
output        tx_successful;
output        need_to_tx;
output        overrun;
output        info_empty;
output        set_bus_error_irq;
output        set_arbitration_lost_irq;
output  [4:0] arbitration_lost_capture;
output        node_error_passive;
output        node_error_active;
output  [6:0] rx_message_counter;


/* This section is for BASIC and EXTENDED mode */
/* Acceptance code register */
input   [7:0] acceptance_code_0;

/* Acceptance mask register */
input   [7:0] acceptance_mask_0;

/* End: This section is for BASIC and EXTENDED mode */


/* This section is for EXTENDED mode */
/* Acceptance code register */
input   [7:0] acceptance_code_1;
input   [7:0] acceptance_code_2;
input   [7:0] acceptance_code_3;

/* Acceptance mask register */
input   [7:0] acceptance_mask_1;
input   [7:0] acceptance_mask_2;
input   [7:0] acceptance_mask_3;
/* End: This section is for EXTENDED mode */

/* Tx data registers. Holding identifier (basic mode), tx frame information (extended mode) and data */
input   [7:0] tx_data_0;
input   [7:0] tx_data_1;
input   [7:0] tx_data_2;
input   [7:0] tx_data_3;
input   [7:0] tx_data_4;
input   [7:0] tx_data_5;
input   [7:0] tx_data_6;
input   [7:0] tx_data_7;
input   [7:0] tx_data_8;
input   [7:0] tx_data_9;
input   [7:0] tx_data_10;
input   [7:0] tx_data_11;
input   [7:0] tx_data_12;
/* End: Tx data registers */

/* Tx signal */
output        tx;
output        tx_next;
output        bus_off_on;

output        go_overload_frame;
output        go_error_frame;
output        go_tx;
output        send_ack;

/* Bist */
`ifdef CAN_BIST
input         mbist_si_i;
output        mbist_so_o;
input [`CAN_MBIST_CTRL_WIDTH - 1:0] mbist_ctrl_i;       // bist chain shift control
`endif

//////////////////////////////////////////////////
logic                                   rst_n; 
logic [3:0]                             dlc;

// Rx related defines
can_frame_s                             rx_frame_ff, rx_frame_next;
type_can_frame_states_e                 rx_state_ff, rx_state_next;
logic [5:0]                             rx_bit_cnt_ff, rx_bit_cnt_next; 
logic                                   bit_de_stuffing_ff, bit_de_stuffing_next;
logic [2:0]                             bit_de_stuff_counter_ff, bit_de_stuff_counter_next;
logic                                   rx_bit_prev, rx_bit_curr;
logic [5:0]                             rx_data_bit_count;
logic                                   rx_remote_req;
logic                                   rx_done_flag, rx_done;
logic                                   remove_stuff_bit;

// Tx related defines
can_frame_s                             tx_frame;
type_can_frame_states_e                 tx_state_ff, tx_state_next;
//logic [5:0]                             bit_cnt_ff, bit_cnt_next; 
logic [5:0]                             tx_bit_cnt_ff, tx_bit_cnt_next;
logic                                   start_tx;
logic                                   message_tx_active, any_tx_active, mode_tx;
logic                                   tx_frame_tx_bit;
logic                                   tx_done;
logic                                   bit_stuffing_ff, bit_stuffing_next;
logic [2:0]                             bit_stuff_counter_ff, bit_stuff_counter_next;
logic                                   insert_stuff_bit;
logic                                   tx_bit_prev, tx_bit_curr, tx_bit_next;


logic [5:0]                             tx_data_bit_count;
logic                                   arbitration_lost_ff, arbitration_lost_next;
logic                                   arbitration_active;
logic                                   tx_remote_req;

logic                                   bit_sample_point, bit_start_point;

logic [3:0]                             byte_cnt_ff, byte_cnt_next;
logic [7:0]                             rx_data_array [0:7];
logic [7:0]                             data_byte_ff, data_byte_next;  
logic                                   wr_rx_data_byte;                                


// Signal assignements
assign rst_n = !rst;
assign rx_bit_curr = sampled_bit;
assign rx_bit_prev = sampled_bit_q;
assign bit_sample_point = sample_point;
assign bit_start_point = tx_point;

// Transmission related signals
logic [3:0]                             tx_byte_cnt_ff, tx_byte_cnt_next;
logic [7:0]                             tx_data_array [0:7];
logic [7:0]                             tx_data_byte_ff, tx_data_byte_next;  
logic                                   rd_tx_data_byte; 
logic                                   can_tx_bit; 

// Get the frame contents
assign tx_frame.id_std = {tx_data_0, tx_data_1[7:5]};
assign tx_frame.rtr1 = tx_data_1[4]; 
assign tx_frame.ide  = 1'b0;
assign tx_frame.dlc  = tx_data_1[3:0];
//assign tx_frame.data = {tx_data_2, tx_data_3, tx_data_4, tx_data_5, tx_data_6, tx_data_7, tx_data_8, tx_data_9};
assign tx_frame.crc  = calculated_crc;

assign tx_remote_req = (~(tx_frame.ide) & tx_frame.rtr1) | (tx_frame.ide & tx_frame.rtr2) | (~(|tx_frame.dlc));
assign tx_data_bit_count = tx_frame.dlc[3] ? 6'h3f : ((tx_frame.dlc[2:0] <<3) - 1'b1);
assign tx_res_bit_count  = 6'h3f - tx_data_bit_count;

assign tx_data_array[0:7] = {tx_data_2, tx_data_3, tx_data_4, tx_data_5, tx_data_6, tx_data_7, tx_data_8, tx_data_9};

// Perform bit stuffing during trasmission
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    bit_stuffing_ff <= 1'b0;
  else 
    bit_stuffing_ff <= bit_stuffing_next;
end

// Counter for bit stuffing 
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
      bit_stuff_counter_ff <= 3'h1;
   else
      bit_stuff_counter_ff <= bit_stuff_counter_next;
end

always_comb begin
   bit_stuff_counter_next = bit_stuff_counter_ff;
 //  insert_stuff_bit = 1'b0;

   if (reset_mode)
      bit_stuff_counter_next = 3'h1;
   else if (bit_sample_point & bit_stuffing_ff) begin
       if (bit_stuff_counter_ff == 3'h5) begin
           bit_stuff_counter_next = 3'h1;
         //  insert_stuff_bit = 1'b1;
       end else if (tx_bit_curr == tx_bit_prev)
           bit_stuff_counter_next = bit_stuff_counter_ff + 1'b1;
       else
           bit_stuff_counter_next = 3'h1;
   end 
end

assign insert_stuff_bit = bit_stuff_counter_ff == 3'h5;

// Previous, current and next bits transmitted / to be transmitted 
always_comb begin
   if (insert_stuff_bit)
      tx_bit_next = ~tx_bit_prev; 
   else 
      tx_bit_next = tx_frame_tx_bit; 
end

always_ff @(posedge clk or negedge rst_n) begin
   if (!rst_n)
      tx_bit_curr <= 1'b1;
   else if (reset_mode)
      tx_bit_curr <= 1'b1;
   else if (bit_start_point)
      tx_bit_curr <= tx_bit_next;
end


always_ff @(posedge clk or negedge rst_n) begin
   if (!rst_n)
      tx_bit_prev <= 1'b0;
   else if (reset_mode)
      tx_bit_prev <= 1'b0;
   else if (bit_start_point)
      tx_bit_prev <= tx_bit_curr;
end

// Check for Arbitration lost
always_ff @(posedge clk or negedge rst_n) begin
   if (!rst_n)
      arbitration_lost_ff <= 1'b0;
   else 
      arbitration_lost_ff <= arbitration_lost_next;
end

always_comb begin
   arbitration_lost_next = arbitration_lost_ff;
   if (go_rx_idle | error_frame_ended)
      arbitration_lost_next = 1'b0;
   else if (bit_sample_point & arbitration_active & tx_bit_curr & ~rx_bit_curr)
      arbitration_lost_next = 1'b1;
end

// Track an ongoing data/remote frame transmission
always @ (posedge clk or posedge rst)
begin
  if (!rst_n)
    message_tx_active <= 1'b0;
  else if (reset_mode | go_rx_inter | error_frame | arbitration_lost_ff)
    message_tx_active <= 1'b0;
  else if (go_tx)
    message_tx_active <= 1'b1;
end

// Track any type of ongoing transmission
always @ (posedge clk or posedge rst)
begin
  if (!rst_n)
    any_tx_active <= 1'b0;
  else if (go_error_frame | go_overload_frame | go_tx | send_ack)
    any_tx_active <= 1'b1;
  else if (reset_mode | go_rx_idle | (go_rx_id1 & (~message_tx_active)) | (arbitration_lost_ff & message_tx_active))
    any_tx_active <= 1'b0;
end

// Mode of transmission
always @ (posedge clk or posedge rst)
begin
  if (!rst_n)
    mode_tx <= 1'b0;
  else if (go_tx)
    mode_tx <= 1'b1;
  else if (reset_mode | go_rx_idle | suspend & go_rx_id1)
    mode_tx <= 1'b0;
end

// Initiate frame transmission
always_ff @(posedge clk or negedge rst_n) begin
   if (!rst_n) 
      start_tx  <= 0;
   else if (go_tx) 
       start_tx  <= 1;
   else if (bit_sample_point)
       start_tx  <= 0;
end

// Tx data array
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_byte_cnt_ff <= '0;
        tx_data_byte_ff <= '0;
    end else if(bit_sample_point) begin // & (rx_bit_cnt_ff[2:0] == 3'd7)
        if (rd_tx_data_byte) begin
            tx_data_byte_ff <= tx_data_array[tx_byte_cnt_next];
            tx_byte_cnt_ff  <= tx_byte_cnt_next;
        end else begin
            tx_data_byte_ff <= tx_data_byte_next;
        end
    end
end

// Tx FSM
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        tx_state_ff <= STATE_IDLE;
        tx_bit_cnt_ff <= '0;
    end else if (arbitration_lost_next) begin
        tx_state_ff <= STATE_IDLE;
        tx_bit_cnt_ff <= '0;
    end else if (bit_sample_point & insert_stuff_bit) begin
       tx_state_ff <= tx_state_ff;
       tx_bit_cnt_ff <= tx_bit_cnt_ff;  
    end else if (bit_sample_point & (~insert_stuff_bit)) begin
       tx_state_ff <= tx_state_next;
       tx_bit_cnt_ff <= tx_bit_cnt_next;   
    end
end


always_comb begin
        tx_bit_cnt_next = 6'b0;
        tx_byte_cnt_next = tx_byte_cnt_ff;
        tx_data_byte_next = tx_data_byte_ff;
        tx_state_next = tx_state_ff;
        tx_frame_tx_bit = 1'b1;
        tx_done = 1'b0;
        arbitration_active = 1'b0;
        bit_stuffing_next = bit_stuffing_ff;
        rd_tx_data_byte = 1'b0;

        case (tx_state_ff)
            STATE_IDLE: begin
                bit_stuffing_next = 1'b0;
                if (start_tx) begin
                    tx_frame_tx_bit = 1'b0; // Start of Frame
                    tx_state_next = STATE_ID_STD;
                    tx_bit_cnt_next  = 10;
                    arbitration_active = 1'b1;
                    bit_stuffing_next = 1'b1;
                end
            end
            
             STATE_ID_STD: begin
                   arbitration_active = 1;
                   tx_frame_tx_bit = tx_frame.id_std[tx_bit_cnt_ff];
                   if (tx_bit_cnt_ff == 0) begin
                       tx_state_next = STATE_BIT_RTR_1;
                    //   bit_cnt_next  = '0;
                   end else begin
                       tx_bit_cnt_next = tx_bit_cnt_ff - 1;
                   end
             end

             STATE_BIT_RTR_1: begin
                arbitration_active = 1;
                tx_frame_tx_bit = tx_frame.rtr1; 
                tx_state_next = STATE_BIT_IDE;
             end 
             STATE_BIT_IDE: begin
                arbitration_active = 1;
                tx_frame_tx_bit = tx_frame.ide; 
                if (tx_frame.ide == 1) begin
                    tx_state_next = STATE_ID_EXT;
                    tx_bit_cnt_next  = 17;
                end else
                    tx_state_next = STATE_BIT_R_0;
            end 
            STATE_ID_EXT: begin
                    arbitration_active = 1;
                    tx_frame_tx_bit = tx_frame.id_ext[tx_bit_cnt_ff];
                    if (tx_bit_cnt_ff == '0) begin
                        tx_state_next = STATE_BIT_RTR_2;
                       // tx_bit_cnt_next  = '0;
                    end else begin
                        tx_bit_cnt_next = tx_bit_cnt_ff - 1;
                    end
                
            end
             STATE_BIT_RTR_2: begin
                arbitration_active = 1;
                tx_frame_tx_bit = tx_frame.rtr2; 
                tx_state_next = STATE_BIT_R_1;
            end 
             STATE_BIT_R_1: begin
                tx_frame_tx_bit = 1'b0; 
                tx_state_next = STATE_BIT_R_0;
            end 
             STATE_BIT_R_0: begin
                tx_frame_tx_bit = 1'b0; 
                tx_state_next = STATE_DLC;
                tx_bit_cnt_next  = 3;
            end 
            
            STATE_DLC: begin
                tx_frame_tx_bit = tx_frame.dlc[tx_bit_cnt_ff];
                if (tx_bit_cnt_ff == '0) begin
                    if (tx_remote_req) begin  
                        tx_state_next = STATE_CRC;
                    end else begin
                        tx_state_next = STATE_DATA;
                        tx_bit_cnt_next = '0;
                        rd_tx_data_byte = 1'b1;
                    end
               end else
                    tx_bit_cnt_next = tx_bit_cnt_ff - 1;
            end
            
            STATE_DATA: begin
         /*       tx_frame_tx_bit = tx_frame.data[tx_bit_cnt_ff];
                if (tx_bit_cnt_ff == tx_res_bit_count) begin
                    tx_state_next = STATE_CRC;
                    tx_bit_cnt_next  = 14;
                end else
                    tx_bit_cnt_next = tx_bit_cnt_ff - 1; */
                tx_data_byte_next = {tx_data_byte_ff[6:0], 1'b0};
                tx_frame_tx_bit = tx_data_byte_ff[7];
                tx_bit_cnt_next = tx_bit_cnt_ff + 1;                   
                    
                if (tx_bit_cnt_ff[2:0] == 3'd7) begin
                    tx_byte_cnt_next = tx_byte_cnt_ff + 1'b1;
                    rd_tx_data_byte    = 1'b1;
                    
                    if (tx_bit_cnt_ff == ((tx_frame.dlc << 3) - 1'b1)) begin
                        tx_state_next = STATE_CRC; 
                        tx_byte_cnt_next = '0;                   
                        tx_bit_cnt_next  = 14;
                    end
                end                
            end
            
            STATE_CRC: begin
                tx_frame_tx_bit = tx_frame.crc[tx_bit_cnt_ff];
                if (tx_bit_cnt_ff == '0) begin
                    tx_state_next = STATE_CRC_DELIMIT;
                 //   tx_bit_cnt_next  = '0;
                end else
                    tx_bit_cnt_next = tx_bit_cnt_ff - 1;
            end
            
            STATE_CRC_DELIMIT: begin
                tx_frame_tx_bit = 1'b1;
                tx_state_next = STATE_ACK;
                bit_stuffing_next = 1'b0;
            end
            
            STATE_ACK: begin
                tx_frame_tx_bit = 1'b1; // Receiver drives ACK, so transmitter remains recessive
                tx_state_next = STATE_ACK_DELIMIT;
            end
            
            STATE_ACK_DELIMIT: begin
                tx_frame_tx_bit = 1'b1;
                tx_state_next = STATE_EOF;
                tx_bit_cnt_next  = 6;
            end
            
            STATE_EOF: begin
                tx_frame_tx_bit = 1'b1;
                if (tx_bit_cnt_ff == '0) begin
                    tx_state_next = STATE_IFS;
                    tx_bit_cnt_next  = 2;
                end else begin
                    tx_bit_cnt_next = tx_bit_cnt_ff - 1;
                end
            end
            
            STATE_IFS: begin
                tx_frame_tx_bit = 1'b1;
                if (tx_bit_cnt_ff == '0) begin
                    tx_done = 1'b1;
                    tx_state_next = STATE_IDLE;
                  //  tx_bit_cnt_next  = '0;
                end else begin
                    tx_bit_cnt_next = tx_bit_cnt_ff - 1;
                end
            end
            
            default: tx_state_next = STATE_IDLE;
        endcase
//     end
end

////////////////// Rx related signals /////////////////////////////

assign rx_remote_req = ((~rx_frame_ff.ide) & rx_frame_ff.rtr1) 
                     | (rx_frame_ff.ide & rx_frame_ff.rtr2);

// Perform bit de-stuffing during reception
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
    bit_de_stuffing_ff <= 1'b0;
  else 
    bit_de_stuffing_ff <= bit_de_stuffing_next;
end

// Counter for bit stuffing 
always_ff @(posedge clk or negedge rst_n) begin
  if (!rst_n)
      bit_de_stuff_counter_ff <= 3'h1;
   else
      bit_de_stuff_counter_ff <= bit_de_stuff_counter_next;
end

always_comb begin
   bit_de_stuff_counter_next = bit_de_stuff_counter_ff;
 //  insert_stuff_bit = 1'b0;

   if (reset_mode)
      bit_de_stuff_counter_next = 3'h1;
   else if (bit_start_point & bit_de_stuffing_ff) begin
       if (bit_de_stuff_counter_ff == 3'h5) begin
           bit_de_stuff_counter_next = 3'h1;
       end else if (rx_bit_curr == rx_bit_prev)
           bit_de_stuff_counter_next = bit_de_stuff_counter_ff + 1'b1;
       else
           bit_de_stuff_counter_next = 3'h1;
   end 
end

assign remove_stuff_bit = bit_de_stuff_counter_ff == 3'h5;

// RX data array
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        byte_cnt_ff <= '0;
    end else if(bit_start_point & wr_rx_data_byte) begin // & (rx_bit_cnt_ff[2:0] == 3'd7)
        rx_data_array[byte_cnt_ff] <= data_byte_next;
        byte_cnt_ff    <= byte_cnt_next;
    end
end


// RX state machine
always_ff @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        rx_state_ff    <= STATE_IDLE;
        rx_bit_cnt_ff  <= '0;
        byte_cnt_ff    <= '0;
        rx_frame_ff    <= '0;
        data_byte_ff   <= '0;
    end else if (bit_start_point & remove_stuff_bit) begin
        rx_state_ff    <= rx_state_ff;
        rx_bit_cnt_ff  <= rx_bit_cnt_ff;
        byte_cnt_ff    <= byte_cnt_ff;
        rx_frame_ff    <= rx_frame_ff; 
        data_byte_ff   <= data_byte_ff;
    end else if (bit_start_point & ~remove_stuff_bit) begin
        rx_state_ff    <= rx_state_next;
        rx_bit_cnt_ff  <= rx_bit_cnt_next; 
        byte_cnt_ff    <= byte_cnt_next;
        rx_frame_ff    <= rx_frame_next; 
        data_byte_ff   <= data_byte_next;  
    end
end


always_comb begin
        rx_bit_cnt_next = 6'b0;
        wr_rx_data_byte = 1'b0;
        rx_state_next = rx_state_ff;
        rx_frame_next = rx_frame_ff;
        bit_de_stuffing_next = bit_de_stuffing_ff;
        byte_cnt_next = byte_cnt_ff;
        data_byte_next = data_byte_ff;
        rx_done_flag = 1'b0;

        case (rx_state_ff)
            STATE_IDLE: begin
                bit_de_stuffing_next = 1'b0;
                if (~rx_bit_curr) begin                    
                    rx_state_next = STATE_ID_STD;                                       
                    bit_de_stuffing_next = 1'b1;
                end
            end
            
             STATE_ID_STD: begin                   
                   rx_frame_next.id_std = {rx_frame_ff.id_std[9:0], rx_bit_curr};
                   if (rx_bit_cnt_ff == 10) begin
                       rx_state_next = STATE_BIT_RTR_1;
                    //   rx_bit_cnt_next  = '0;
                   end else begin
                       rx_bit_cnt_next = rx_bit_cnt_ff + 1;
                   end
             end

             STATE_BIT_RTR_1: begin               
                rx_frame_next.rtr1 = rx_bit_curr; 
                rx_state_next = STATE_BIT_IDE;
             end 

             STATE_BIT_IDE: begin                
                rx_frame_next.ide = rx_bit_curr; 
                if (rx_frame_next.ide == 1) begin
                    rx_state_next = STATE_ID_EXT;
                 //   rx_bit_cnt_next  = 11;
                end else
                    rx_state_next = STATE_BIT_R_0;
            end 
            STATE_ID_EXT: begin                                       
                    rx_frame_next.id_ext = {rx_frame_ff.id_ext[16:0], rx_bit_curr};
                    if (rx_bit_cnt_ff == 17) begin
                        rx_state_next = STATE_BIT_RTR_2;
                       // bit_cnt_next  = '0;
                    end else begin
                        rx_bit_cnt_next = rx_bit_cnt_ff + 1;
                    end
                
            end
             STATE_BIT_RTR_2: begin                
                rx_frame_next.rtr2 = rx_bit_curr; 
                rx_state_next = STATE_BIT_R_1;
            end 
             STATE_BIT_R_1: begin
             // ???   can_tx = 1'b0; 
                rx_state_next = STATE_BIT_R_0;
            end 
             STATE_BIT_R_0: begin
             // ???   can_tx = 1'b0; 
                rx_state_next = STATE_DLC;
               // rx_bit_cnt_next  = 3;
            end 
            
            STATE_DLC: begin
                rx_frame_next.dlc = {rx_frame_ff.dlc[2:0], rx_bit_curr};
                if (rx_bit_cnt_ff == 3) begin
                    if (rx_remote_req) begin  
                        rx_state_next = STATE_CRC;
                    end else begin
                        rx_state_next = STATE_DATA;
                        byte_cnt_next = '0;
                     //   rx_bit_cnt_next = 63;
                    end
               end else
                    rx_bit_cnt_next = rx_bit_cnt_ff + 1;
            end
            
            STATE_DATA: begin
              //  rx_frame_next.data[rx_bit_cnt_ff] = rx_bit_curr;
              //  rx_frame_next.data = {rx_frame_ff.data[62:0], rx_bit_curr};
                data_byte_next     = {data_byte_ff[6:0], rx_bit_curr};
                rx_bit_cnt_next = rx_bit_cnt_ff + 1;                   
                    
                if (rx_bit_cnt_ff[2:0] == 3'd7) begin
                    byte_cnt_next = byte_cnt_ff + 1'b1;
                    wr_rx_data_byte    = 1'b1;
                    
                    if (rx_bit_cnt_ff == ((rx_frame_ff.dlc << 3) - 1'b1)) begin
                        rx_state_next = STATE_CRC;                    
                        byte_cnt_next = '0;
                    end
                end                
            end
            
            STATE_CRC: begin
             //   rx_frame_next.crc[rx_bit_cnt_ff] = rx_bit_curr;
                rx_frame_next.crc = {rx_frame_ff.crc[13:0], rx_bit_curr};
                if (rx_bit_cnt_ff == 14) begin
                    rx_state_next = STATE_CRC_DELIMIT;
                end else
                    rx_bit_cnt_next = rx_bit_cnt_ff + 1;
            end
            
            STATE_CRC_DELIMIT: begin
                rx_state_next = STATE_ACK;
                bit_de_stuffing_next = 1'b0;
            end
            
            STATE_ACK: begin
                rx_state_next = STATE_ACK_DELIMIT;
            end
            
            STATE_ACK_DELIMIT: begin
                rx_state_next = STATE_EOF;
            end
            
            STATE_EOF: begin
                if (rx_bit_cnt_ff == 6) begin
                    rx_state_next = STATE_IFS;
                    rx_bit_cnt_next  = '0;
                end else begin
                    rx_bit_cnt_next = rx_bit_cnt_ff + 1;
                end
            end
            
            STATE_IFS: begin
                if (rx_bit_cnt_ff == 2) begin
                    rx_done_flag = 1'b1;
                    rx_state_next = STATE_IDLE;
                end else begin
                    rx_bit_cnt_next = rx_bit_cnt_ff + 1;
                end
            end
            
            default: rx_state_next = STATE_IDLE;
        endcase
//     end
end

///////////////////////// Error handling ///////////////////////////////

logic                                   bit_error;
logic                                   form_error;
logic                                   stuff_error;
logic                                   crc_error;
logic                                   ack_error;

logic [8:0]                             tx_error_counter_next, tx_error_counter_ff;
logic [8:0]                             rx_error_counter_next, rx_error_counter_ff;

// Evaluate different error conditions

// Stuff error condition 
assign stuff_error = bit_sample_point & bit_de_stuffing_ff & remove_stuff_bit & (rx_bit_curr == rx_bit_prev);

// Ack error condition
assign ack_error = (rx_state_ff == STATE_ACK) & bit_sample_point & rx_bit_curr & message_tx_active;

assign rx_done = rx_done_flag & bit_start_point; // | bus_free & (~node_bus_off);


endmodule
