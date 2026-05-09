`timescale 1ns / 1ps

module sequencer (
    input  logic clk,
    input  logic rst_n,
    input  logic step_tick,
    input  logic dir,
    input  logic inversion,
    output logic [3:0] stepper_phases
);

    logic [1:0] phase_state; // Licznik stanów 0-3
    logic [3:0] active_coil; // Która cewka jest aktualnie zasilana

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            phase_state <= '0;
        end else if (step_tick) begin
            // Zmiana fazy w zależności od kierunku
            if (dir)
                phase_state <= phase_state + 1;
            else
                phase_state <= phase_state - 1;
        end
    end

    // Dekoder faz (sterowanie pełnokrokowe - Full Step)
    always_comb begin
        case (phase_state)
            2'b00: active_coil = 4'b0001;
            2'b01: active_coil = 4'b0010;
            2'b10: active_coil = 4'b0100;
            2'b11: active_coil = 4'b1000;
            default: active_coil = 4'b0000;
        endcase
    end

    // Wyjście z opcją inwersji
    assign stepper_phases = inversion ? ~active_coil : active_coil;

endmodule