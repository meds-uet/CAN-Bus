`timescale 1ns/1ps

module tb_can_error_detection;

    // Inputs
    logic clk;
    logic rst;
    logic rx_bit;
    logic tx_bit;
    logic tx_active;
    logic sample_point;

    logic bit_de_stuffing_ff;
    logic remove_stuff_bit;
    logic rx_bit_curr;
    logic rx_bit_prev;

    logic in_arbitration;
    logic in_ack_slot;
    logic sending_error_flag_passive;

    logic in_crc_delimiter;
    logic in_ack_delimiter;
    logic in_eof;

    logic crc_check_done;
    logic crc_rx_valid;
    logic crc_rx_match;

    // Outputs
    logic bit_error;
    logic stuff_error;
    logic crc_error;
    logic form_error;
    logic ack_error;

    // DUT
    can_error_detection dut (
        .clk(clk),
        .rst(rst),
        .rx_bit(rx_bit),
        .tx_bit(tx_bit),
        .tx_active(tx_active),
        .sample_point(sample_point),
        .bit_de_stuffing_ff(bit_de_stuffing_ff),
        .remove_stuff_bit(remove_stuff_bit),
        .rx_bit_curr(rx_bit_curr),
        .rx_bit_prev(rx_bit_prev),
        .in_arbitration(in_arbitration),
        .in_ack_slot(in_ack_slot),
        .sending_error_flag_passive(sending_error_flag_passive),
        .in_crc_delimiter(in_crc_delimiter),
        .in_ack_delimiter(in_ack_delimiter),
        .in_eof(in_eof),
        .crc_check_done(crc_check_done),
        .crc_rx_valid(crc_rx_valid),
        .crc_rx_match(crc_rx_match),
        .bit_error(bit_error),
        .stuff_error(stuff_error),
        .crc_error(crc_error),
        .form_error(form_error),
        .ack_error(ack_error)
    );

    // Clock generation
    always #5 clk = ~clk;

    initial begin
        // Initialize all
        clk = 0;
        rst = 0;
        rx_bit = 1;
        tx_bit = 1;
        tx_active = 0;
        sample_point = 0;

        bit_de_stuffing_ff = 0;
        remove_stuff_bit = 0;
        rx_bit_curr = 1;
        rx_bit_prev = 1;

        in_arbitration = 0;
        in_ack_slot = 0;
        sending_error_flag_passive = 0;

        in_crc_delimiter = 0;
        in_ack_delimiter = 0;
        in_eof = 0;

        crc_check_done = 0;
        crc_rx_valid = 0;
        crc_rx_match = 1;

        // Reset pulse
        #10 rst = 1;

        // Test BIT ERROR
        #10;
        sample_point = 1;
        tx_active = 1;
        tx_bit = 1;
        rx_bit = 0;
        #5;
        $display("Test 1 - Bit Error: bit_error = %b", bit_error);
        #10;
        sample_point = 0;
        tx_active=0;

        // Test STUFF ERROR
        #10;
        bit_de_stuffing_ff = 1;
        remove_stuff_bit = 1;
        sample_point = 1;
        rx_bit_curr = 1;
        rx_bit_prev = 1;
        #5;
         $display("Test 2 - Stuff Error: stuff_error = %b", stuff_error);
        #10;
        sample_point = 0;

        // Test CRC ERROR
        #10;
        crc_check_done = 1;
        crc_rx_valid = 1;
        crc_rx_match = 0;
        #5;
        $display("Test 3 - CRC Error: crc_error = %b", crc_error);
        #10;
        crc_check_done = 0;

        // Test ACK ERROR
        #10;
        tx_active = 1;
        in_ack_slot = 1;
        rx_bit = 1;
        sample_point = 1;
        #5;
        $display("Test 4 - ACK Error: ack_error = %b", ack_error);
        #10;
        sample_point = 0;
        in_ack_slot = 0;

        
        // Test FORM ERROR (ACK delimiter)
        #10;
        sample_point = 1;
        in_ack_delimiter = 1;
        rx_bit = 0;
        #10;
        $display("Test 5 - Form Error (ACK delimiter): form_error = %b", form_error);
        #10;
        sample_point = 0;
        in_ack_delimiter = 0;

        $display("Simulation done");
        #20 $finish;
    end

endmodule
