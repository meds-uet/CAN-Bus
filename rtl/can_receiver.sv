`timescale 1ns/1ps
module can_receiver(
    input  logic        clk,
    input  logic        rst_n,
    input  logic        rx_bit_curr,
    input  logic        sample_point,
    input  logic        remove_stuff_bit, // external destuff detect
    output logic [7:0]  rx_data_array [7:0],
    output logic        rx_done_flag,
    output logic [10:0] rx_id_std,
    output logic [17:0] rx_id_ext,
    output logic        rx_ide,
    output logic [3:0]  rx_dlc,
    output logic        rx_remote_req
);

    typedef struct packed {
        logic [10:0] id_std;
        logic [17:0] id_ext;
        logic        ide;
        logic        rtr1;
        logic        rtr2;
        logic [3:0]  dlc;
        logic [14:0] crc;
    } can_frame_t;

    typedef enum logic [3:0] {
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
    } rx_state_t;

    rx_state_t rx_state_ff, rx_state_next;

    logic [5:0] rx_bit_cnt_ff, rx_bit_cnt_next;
    logic [2:0] byte_cnt_ff,  byte_cnt_next;
    logic [7:0] data_byte_ff, data_byte_next;
    logic       wr_rx_data_byte;

    can_frame_t rx_frame_ff, rx_frame_next;

    logic bit_de_stuffing_ff, bit_de_stuffing_next;

    assign rx_id_std    = rx_frame_ff.id_std;
    assign rx_id_ext    = rx_frame_ff.id_ext;
    assign rx_ide       = rx_frame_ff.ide;
    assign rx_dlc       = rx_frame_ff.dlc;
    assign rx_remote_req = ((~rx_frame_ff.ide) & rx_frame_ff.rtr1) |
                           ( rx_frame_ff.ide & rx_frame_ff.rtr2);

    // Sequential logic
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_state_ff        <= STATE_IDLE;
            rx_bit_cnt_ff      <= '0;
            byte_cnt_ff        <= '0;
            rx_frame_ff        <= '0;
            data_byte_ff       <= '0;
            bit_de_stuffing_ff <= 1'b0;
        end else if (sample_point & remove_stuff_bit) begin
            // Hold state, skip this bit
            rx_state_ff        <= rx_state_ff;
            rx_bit_cnt_ff      <= rx_bit_cnt_ff;
            byte_cnt_ff        <= byte_cnt_ff;
            rx_frame_ff        <= rx_frame_ff; 
            data_byte_ff       <= data_byte_ff;
            bit_de_stuffing_ff <= bit_de_stuffing_ff;
        end else if (sample_point& ~remove_stuff_bit) begin
            rx_state_ff        <= rx_state_next;
            rx_bit_cnt_ff      <= rx_bit_cnt_next; 
            byte_cnt_ff        <= byte_cnt_next;
            rx_frame_ff        <= rx_frame_next; 
            data_byte_ff       <= data_byte_next;
            bit_de_stuffing_ff <= bit_de_stuffing_next;

            if (wr_rx_data_byte)
                rx_data_array[byte_cnt_ff] <= data_byte_next;
        end
    end

    // Combinational logic
    always_comb begin
        rx_bit_cnt_next       = rx_bit_cnt_ff;
        wr_rx_data_byte       = 1'b0;
        rx_state_next         = rx_state_ff;
        rx_frame_next         = rx_frame_ff;
        bit_de_stuffing_next  = bit_de_stuffing_ff;
        byte_cnt_next         = byte_cnt_ff;
        data_byte_next        = data_byte_ff;
        rx_done_flag          = 1'b0;

        case (rx_state_ff)
            STATE_IDLE: begin
                bit_de_stuffing_next = 1'b0;
                if (~rx_bit_curr) begin                    
                    rx_state_next        = STATE_ID_STD;                                       
                    bit_de_stuffing_next = 1'b1;
                    rx_bit_cnt_next      = 0;
                end
            end
            
            STATE_ID_STD: begin                   
                rx_frame_next.id_std = {rx_frame_ff.id_std[9:0], rx_bit_curr};
                if (rx_bit_cnt_ff == 10) begin
                    rx_state_next   = STATE_BIT_RTR_1;
                    rx_bit_cnt_next = 0;
                end else begin
                    rx_bit_cnt_next = rx_bit_cnt_ff + 1;
                end
            end

            STATE_BIT_RTR_1: begin               
                rx_frame_next.rtr1 = rx_bit_curr; 
                rx_state_next      = STATE_BIT_IDE;
            end 

            STATE_BIT_IDE: begin                
                rx_frame_next.ide = rx_bit_curr; 
                if (rx_bit_curr == 1) begin
                    rx_state_next   = STATE_ID_EXT;
                    rx_bit_cnt_next = 0;
                end else begin
                    rx_state_next   = STATE_BIT_R_0;
                end
            end 

            STATE_ID_EXT: begin                                       
                rx_frame_next.id_ext = {rx_frame_ff.id_ext[16:0], rx_bit_curr};
                if (rx_bit_cnt_ff == 17) begin
                    rx_state_next   = STATE_BIT_RTR_2;
                    rx_bit_cnt_next = 0;
                end else begin
                    rx_bit_cnt_next = rx_bit_cnt_ff + 1;
                end
            end

            STATE_BIT_RTR_2: begin                
                rx_frame_next.rtr2 = rx_bit_curr; 
                rx_state_next      = STATE_BIT_R_1;
            end 

            STATE_BIT_R_1: rx_state_next = STATE_BIT_R_0; 
            STATE_BIT_R_0: begin
                rx_state_next   = STATE_DLC;
                rx_bit_cnt_next = 0;
            end 
            
            STATE_DLC: begin
                rx_frame_next.dlc = {rx_frame_ff.dlc[2:0], rx_bit_curr};
                if (rx_bit_cnt_ff == 3) begin
                    if (rx_remote_req) begin  
                        rx_state_next   = STATE_CRC;
                        rx_bit_cnt_next = 0;
                    end else begin
                        rx_state_next   = STATE_DATA;
                        byte_cnt_next   = 0;
                        rx_bit_cnt_next = 0;
                    end
                end else
                    rx_bit_cnt_next = rx_bit_cnt_ff + 1;
            end
            
            STATE_DATA: begin
                data_byte_next   = {data_byte_ff[6:0], rx_bit_curr};
                rx_bit_cnt_next  = rx_bit_cnt_ff + 1;                   
                    
                if (rx_bit_cnt_ff[2:0] == 3'd7) begin
                    wr_rx_data_byte = 1'b1;
                    byte_cnt_next   = byte_cnt_ff + 1'b1;
                    
                    if (byte_cnt_ff + 1 == rx_frame_ff.dlc) begin
                        rx_state_next   = STATE_CRC;                    
                        byte_cnt_next   = 0;
                        rx_bit_cnt_next = 0;
                    end
                end                
            end
            
            STATE_CRC: begin
                rx_frame_next.crc = {rx_frame_ff.crc[13:0], rx_bit_curr};
                if (rx_bit_cnt_ff == 14) begin
                    rx_state_next   = STATE_CRC_DELIMIT;
                    rx_bit_cnt_next = 0;
                end else
                    rx_bit_cnt_next = rx_bit_cnt_ff + 1;
            end
            
            STATE_CRC_DELIMIT: begin
                rx_state_next        = STATE_ACK;
                bit_de_stuffing_next = 1'b0;
            end
            
            STATE_ACK:         rx_state_next = STATE_ACK_DELIMIT;
            STATE_ACK_DELIMIT: rx_state_next = STATE_EOF;
            
            STATE_EOF: begin
                if (rx_bit_cnt_ff == 6) begin
                    rx_state_next   = STATE_IFS;
                    rx_bit_cnt_next = 0;
                end else begin
                    rx_bit_cnt_next = rx_bit_cnt_ff + 1;
                end
            end
            
            STATE_IFS: begin
                if (rx_bit_cnt_ff == 2) begin
                    rx_done_flag    = 1'b1;
                    rx_state_next   = STATE_IDLE;
                end else begin
                    rx_bit_cnt_next = rx_bit_cnt_ff + 1;
                end
            end
            
            default: rx_state_next = STATE_IDLE;
        endcase
    end

endmodule
