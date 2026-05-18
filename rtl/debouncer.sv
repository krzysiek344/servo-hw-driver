`timescale 1ns / 1ps

module debouncer #(
    parameter DELAY_CYCLES = 1000000 // Delay (10 ms dla 100 MHz)
) (
    input  logic clk,
    input  logic rst_n,
    output logic cleared_signal,
    input  logic signal_in
   
);
    localparam CNT_WIDTH = ($clog2(DELAY_CYCLES) >0) ? $clog2(DELAY_CYCLES) : 1;// 

    logic [CNT_WIDTH-1:0] debounce_cnt, debounce_cnt_nxt; // delay counter
    logic cleared_signal_nxt;
    logic sync_0, sync_1;      // Synchronizatory (zabezpieczenie przed matastabilnością)

    // Synchronizacja sygnału 
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sync_0 <= 1'b0;
            sync_1 <= 1'b0;
        end else begin
            sync_0 <= signal_in;
            sync_1 <= sync_0;
        end
    end

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            debounce_cnt   <= '0;
            cleared_signal <= 1'b0;
        end else begin
            debounce_cnt   <= debounce_cnt_nxt;
            cleared_signal <= cleared_signal_nxt;
        end
    end

    always_comb begin
        debounce_cnt_nxt   = debounce_cnt;
        cleared_signal_nxt = cleared_signal;

        if (sync_1 != cleared_signal) begin
            if (debounce_cnt >= (DELAY_CYCLES - 1)) begin
                cleared_signal_nxt = sync_1;
                debounce_cnt_nxt   = '0;
            end else begin
                debounce_cnt_nxt = debounce_cnt + 1;
            end
        end else begin
            debounce_cnt_nxt = '0;
        end
    end

endmodule