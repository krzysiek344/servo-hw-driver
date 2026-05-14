
`timescale 1ns/1ps

module prescaler #(
    parameter int SCALE_WIDTH = 32
)(
    input logic clk,
    input logic rst_n,
    input logic enable,
    input logic [SCALE_WIDTH-1:0] scale_val,
);
    logic [SCALE_WIDTH-1:0] counter, counter_nxt;
    logic step_tick_nxt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
            step_tick <= 1'b0;
        end else begin
            counter <= counter_nxt;
            step_tick <= step_tick_nxt;
        end
    end

    always_comb begin
        counter_nxt = counter;
        step_tick_nxt = 1'b0;

        if (enable) begin
            if (counter >= scale_val - 1) begin
                counter_nxt = '0;
                step_tick_nxt = 1'b1;
            end else begin
                counter_nxt = counter + 1;
            end
        end else begin
            counter_nxt = '0;
        end
    end
endmodule