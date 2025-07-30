`timescale 1ns / 1ps
`include "can_defs.svh"

module tb_can_receiver;

  // Inputs
  logic clk, rst_n;
  logic rx_point;
  logic rx_bit;

  // Outputs
  logic [10:0] rx_id_std;
  logic [17:0] rx_id_ext;
  logic        rx_ide;
  logic        rx_rtr;
  logic [3:0]  rx_dlc;
  logic [7:0]  rx_data [0:7];
  logic [14:0] rx_crc;
  logic        rx_done;

  // DUT
  can_receiver uut (
    .clk(clk),
    .rst_n(rst_n),
    .rx_point(rx_point),
    .rx_bit(rx_bit),
    .rx_id_std(rx_id_std),
    .rx_id_ext(rx_id_ext),
    .rx_ide(rx_ide),
    .rx_rtr(rx_rtr),
    .rx_dlc(rx_dlc),
    .rx_data(rx_data),
    .rx_crc(rx_crc),
    .rx_done(rx_done)
  );

  // Clock
  always #5 clk = ~clk;

  // Example Frame
  bit [54:0] frame = {
    1'b0,                     // SOF
    11'b00100100011,         // ID = 0x123
    1'b0,                    // RTR
    1'b0,                    // IDE
    1'b0,                    // r0
    4'b0001,                 // DLC = 1
    8'b10101011,             // Data = 0xAB
    15'b001001000110100,     // CRC dummy
    1'b1,                    // CRC delimiter
    1'b1,                    // ACK slot
    1'b1,                    // ACK delimiter
    7'b1111111,              // EOF
    3'b111                   // IFS
  };

  initial begin
    $display("=== Starting CAN Receiver Testbench ===");

    // Initialize
    clk = 0;
    rst_n = 0;
    rx_point = 0;
    rx_bit = 1;

    // Reset
    #20; rst_n = 1;
    #20;

    // Send frame bits
    for (int i = 0; i < $bits(frame); i++) begin
      rx_bit = frame[$bits(frame)-1 - i];
      rx_point = 1;
      #10;
      rx_point = 0;
      #10;
    end

    //  Wait for rx_done and then wait one clk edge to get output
    @(posedge rx_done);
    @(posedge clk); // Wait one more clock to ensure data is updated

    $display("\n=== Frame Received ===");
    $display("  rx_id_std  = 0x%03h", rx_id_std);
    $display("  rx_rtr     = %0b",    rx_rtr);
    $display("  rx_ide     = %0b",    rx_ide);
    $display("  rx_dlc     = %0d",    rx_dlc);
    $display("  rx_data[0] = 0x%02h", rx_data[0]);
    $display("  rx_crc     = 0x%04h", rx_crc);
    $display("=========================");

    $finish;
  end

endmodule
