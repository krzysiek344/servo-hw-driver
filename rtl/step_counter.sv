timescale 1ns / 1ps

module step_counter (
    input  logic clk,
    input  logic rst_n,
    input  logic step_tick,
    input  logic dir,
    input  logic set_zero, // z poziomu FSM mozesz wyzerowac licznik przez ta zmienna 
    output logic signed [31:0] current_pos
);

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            current_pos <= '0;
        end else if (set_zero) begin
            current_pos <= '0;
        end else if (step_tick) begin
            if (dir)
                current_pos <= current_pos + 1;
            else
                current_pos <= current_pos - 1;
        end
    end

endmodule