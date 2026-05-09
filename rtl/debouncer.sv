`timescale 1ns / 1ps

module debouncer #(
    parameter DELAY_CYCLES = 1000000 // Delay (10 ms dla 100 MHz)
) (
    input  logic clk,
    input  logic rst_n,
    input  logic signal_in,
    output logic cleared_signal
);

    logic [19:0] debounce_cnt; // delay counter
    logic sync_0, sync_1;      // Synchronizatory (zabezpieczenie przed matastabilnością)

    // Synchronizacja sygnału 
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= signal_in;
            sync_1 <= sync_0;
        end
    end

    // Właściwa logika filtrowania drgań
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            debounce_cnt   <= '0;
            cleared_signal <= 1'b0;
        end else begin
            if (sync_1 != cleared_signal) begin
                // Sygnał się zmienił - zaczynamy odliczanie
                if (debounce_cnt >= DELAY_CYCLES - 1) begin
                    // Sygnał ustabilizowany wystarczająco długo - przyjmujemy nową wartość
                    cleared_signal <= sync_1;
                    debounce_cnt   <= '0;
                end else begin
                    debounce_cnt <= debounce_cnt + 1;
                end
            end else begin
                // Sygnał bez zmian - zerujemy licznik
                debounce_cnt <= '0;
            end
        end
    end

endmodule