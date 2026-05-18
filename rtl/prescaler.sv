
`timescale 1ns/1ps

module prescaler #(
    parameter SCALE_WIDTH = 32
)(
    input logic clk,
    input logic rst_n,
    output logic step_tick,
    input logic enable,
    input logic [SCALE_WIDTH-1:0] scale_val
   
);
    logic [SCALE_WIDTH-1:0] counter, counter_nxt;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter <= '0;
        end else begin
            counter <= counter_nxt;
        end
    end

    always_comb begin
        counter_nxt = counter;
        if (enable) begin
            if (counter >= (scale_val - 1)) begin
                counter_nxt = '0;
            end else begin
                counter_nxt = counter + 1;
            end
        end else begin
            counter_nxt = '0;
        end
    end

    always_comb begin
        step_tick = 1'b0;
        if (enable && (counter >= (scale_val - 1))) begin
            step_tick = 1'b1;
        end
    end

endmodule
