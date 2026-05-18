`timescale 1ns / 1ps

module sequencer (
    input  logic clk,
    input  logic rst_n,
    input  logic step_tick,
    input  logic dir,
    input  logic inversion,
    output logic [3:0] stepper_phases
);

    logic [1:0] phase_state, phase_state_nxt; // Licznik stanów 0-3
    logic [3:0] active_coil; // Która cewka jest aktualnie zasilana

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_state <= 2'b0;
        end else begin
           phase_state <= phase_state_nxt;
        end
    end

    always_comb begin
        phase_state_nxt = phase_state;
        if (step_tick) begin
            if (dir) begin
                phase_state_nxt = phase_state + 2'd1;
            end else begin
                phase_state_nxt = phase_state - 2'd1;
            end
        end
    end

    always_comb begin
        active_coil = 4'b0000;
        case (phase_state)
            2'b00: begin active_coil = 4'b0001; end
            2'b01: begin active_coil = 4'b0010; end
            2'b10: begin active_coil = 4'b0100; end
            2'b11: begin active_coil = 4'b1000; end
            default: begin active_coil = 4'b0000; end
        endcase
    end

    /* Output assignment */
    assign stepper_phases = inversion ? ~active_coil : active_coil;

endmodule