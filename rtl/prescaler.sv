
`timescale 1ns/1ps

module prescaler (
    input logic clk,
    input logic rst_n,
    input logic enable,
    input logi [31:0] scale_val,
    output logic step_tick
);
    logic [31:0] counter;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            counter   <= '0;
            step_tick <= 1'b0;
        end else begin
            step_tick <= 1'b0; // Domyślnie impuls jest zgaszony

            if (enable) begin
                if (counter >= scale_val - 1) begin
                    counter   <= '0;
                    step_tick <= 1'b1; // Strzał (impuls) na jeden cykl zegara
                end else begin
                    counter <= counter + 1;
                end
            end else begin
                counter <= '0; // Zerowanie, gdy silnik stoi
            end
        end
    end
endmodule