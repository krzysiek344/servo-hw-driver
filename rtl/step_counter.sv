`timescale 1ns / 1ps

module step_counter #(
    parameter int POS_RANGE = 32
)(
    input  logic clk,
    input  logic rst_n,
    input  logic step_tick,
    input  logic dir,
    input  logic set_zero, // z poziomu FSM mozesz wyzerowac licznik przez ta zmienna 
    output logic signed [31:0] current_pos
);

    logic signed [31:0] current_pos_nxt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            current_pos <= 32'sd0;
        end else begin
            current_pos <= current_pos_nxt;
        end
    end

    always_comb begin
        current_pos_nxt = current_pos;

        if (set_zero) begin
            current_pos_nxt = 32'sd0;
        end else if (step_tick) begin
            if (dir) begin
                current_pos_nxt = current_pos + 32'sd1;
            end else begin
                current_pos_nxt = current_pos - 32'sd1;
            end
        end
    end
endmodule