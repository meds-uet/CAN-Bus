module can_error_detection (
    input  logic clk,
    input  logic rst,
    // Basic sampled data
    input  logic rx_bit,          // Sampled bit from CAN bus
    input  logic tx_bit,          // Bit that we tried to send
    input  logic tx_active,       // Are we transmitting?
    input  logic sample_point,    // From bit timing logic

    // For stuff error detection
    input  logic bit_de_stuffing_ff,
    input  logic remove_stuff_bit,
    input  logic rx_bit_curr,
    input  logic rx_bit_prev,

    // For bit error exceptions
    input  logic in_arbitration,   // Are we in arbitration field?
    input  logic in_ack_slot,      // Are we in ACK slot?
    input  logic sending_error_flag_passive,  // For passive error flag

    // For form error
   
    input logic in_crc_delimiter, // High when in CRC delimiter bit
    input logic in_ack_delimiter, // High when in ACK delimiter bit
    input logic in_eof,

    // For CRC error
    input  logic crc_check_done,
    input  logic crc_rx_valid,
    input  logic crc_rx_match,

    output logic bit_error,
    output logic stuff_error,
    output logic crc_error,
    output logic form_error,
    output logic ack_error
);

// --- STUFF ERROR ---
    // Triggered at sample_point when 6th same bit is seen in a stuffing field
    assign stuff_error = sample_point & bit_de_stuffing_ff & remove_stuff_bit & (rx_bit_curr == rx_bit_prev);
// BIT ERROR
    assign bit_error = sample_point & tx_active & 
     (tx_bit != rx_bit) &  ~((tx_bit == 1'b1) &&(rx_bit == 1'b0) && (in_arbitration ||in_ack_slot ||sending_error_flag_passive));
// ACK ERROR
    assign ack_error = sample_point & tx_active & in_ack_slot & (rx_bit == 1'b1);  // recessive received

// FORM ERROR: happens when fixed-format fields contain illegal bits

always_ff @(posedge clk or negedge rst) begin
    if (!rst) begin
        form_error <= 1'b0;
    end else if (sample_point) begin
        if (
            (in_crc_delimiter  && (rx_bit != 1'b1)) ||   // CRC delimiter must be recessive
            (in_ack_delimiter  && (rx_bit != 1'b1)) ||   // ACK delimiter must be recessive
            (in_eof            && (rx_bit != 1'b1))      // EOF field must be all recessive
        ) begin
            form_error <= 1'b1;
        end else begin
            form_error <= 1'b0;
        end
    end else begin
        form_error <= 1'b0;
    end
end
// CRC ERROR
assign crc_error = crc_check_done & crc_rx_valid & ~crc_rx_match;

endmodule

