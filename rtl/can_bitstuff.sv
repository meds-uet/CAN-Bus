`include "can_defs.svh"

module can_bitstuff (
    input  logic       clk,
    input  logic       rst_n,
    input  logic       bit_in,
    input  logic       sample_point,
    input  logic       insert_mode,        // 1 = stuffing, 0 = de-stuffing
    output logic       bit_out,
    output logic       insert_or_remove    // 1 = stuff/remove performed, 0 = pass-through
);

    logic [2:0] same_count;
    logic       prev_bit;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            same_count <= 3'd1;
            prev_bit   <= 1'b1;
        end else if (sample_point) begin
            if (bit_in == prev_bit)
                same_count <= same_count + 1'b1;
            else
                same_count <= 3'd1;
            prev_bit <= bit_in;
        end
    end

    assign insert_or_remove = (same_count == 3'd5) ? 1'b1 : 1'b0;

    always_comb begin
        if (insert_mode) begin
            // Transmitter stuffing: insert opposite bit after 5 same bits
            if (insert_or_remove)
                bit_out = ~prev_bit;
            else
                bit_out = bit_in;
        end else begin
            // Receiver de-stuffing: skip 6th bit if same
            bit_out = bit_in;  // Receiver logic handles skipping externally
        end
    end

endmodule
