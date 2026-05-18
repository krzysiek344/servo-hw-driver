`timescale 1ns / 1ps

module sequencer #(
    parameter COILS_NUM = 4
)(
    input  logic clk,
    input  logic rst_n,
    output logic [COILS_NUM-1:0] stepper_phases,
    input  logic step_tick,
    input  logic dir,
    input  logic inversion
  
);
    localparam PHASE_WIDTH = ($clog2(COILS_NUM) > 0) ? $clog2(COILS_NUM) : 1;

    logic [PHASE_WIDTH-1:0] phase_state, phase_state_nxt; // Licznik stanów 
    logic [COILS_NUM-1:0] active_coil; // Która cewka jest aktualnie zasilana

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            phase_state <= '0;
        end else begin
           phase_state <= phase_state_nxt;
        end
    end

    always_comb begin
        phase_state_nxt = phase_state;
        if (step_tick) begin
            if (dir) begin
                if (phase_state >= (COILS_NUM - 1)) begin
                    phase_state_nxt = '0;
                end else begin
                    phase_state_nxt = phase_state + 1;
                end
            end else begin
                if (phase_state == '0) begin
                    phase_state_nxt = COILS_NUM - 1;
                end else begin
                    phase_state_nxt = phase_state - 1;
                end
            end
        end
    end

    always_comb begin
        active_coil = '0;
        active_coil[phase_state] = 1'b1;
    end

    /* Output assignment */
    assign stepper_phases = inversion ? ~active_coil : active_coil;

endmodule