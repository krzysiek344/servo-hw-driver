
`timescale 1ns / 1ps

module top_servo_drv_tb;

    localparam int SIM_POS_RANGE    = 32;
    localparam int SIM_SCALE_WIDTH  = 32;
    localparam int SIM_DELAY_CYCLES = 5;

    logic clk;
    logic rst_n;

    logic [3:0] stepper_phases;
    logic callib_done;
    logic [SIM_POS_RANGE-1:0] current_pos;

    logic enable;
    logic callib;
    logic go_to;
    logic [SIM_POS_RANGE-1:0] target_pos;
    logic [SIM_SCALE_WIDTH-1:0] scale_val;
    logic inversion;
    logic sensor_raw;

    top_servo_drv #(
        .POS_RANGE(SIM_POS_RANGE),
        .SCALE_WIDTH(SIM_SCALE_WIDTH),
        .DELAY_CYCLES(SIM_DELAY_CYCLES)
    ) dut (
        .clk            (clk),
        .rst_n          (rst_n),
        .stepper_phases (stepper_phases),
        .callib_done    (callib_done),
        .current_pos    (current_pos),
        .enable         (enable),
        .callib         (callib),
        .go_to          (go_to),
        .target_pos     (target_pos),
        .scale_val      (scale_val),
        .inversion      (inversion),
        .sensor_raw     (sensor_raw)
    );

    initial begin
        clk = 1'b0;
        forever #5ns clk = ~clk;
    end

    initial begin
        // Inicjalizacja
        rst_n      = 1'b0;
        enable     = 1'b0;
        callib     = 1'b0;
        go_to      = 1'b0;
        target_pos = '0;
        scale_val  = 32'd2; // Przeskalowane na 32 bity
        inversion  = 1'b0;
        sensor_raw = 1'b0;

        #20ns;
        rst_n = 1'b1;
        #20ns;
        enable = 1'b1;
        #20ns;

        // TEST 1: Kalibracja
        $display("[%0t] Start kalibracji...", $time);
        callib = 1'b1;

        #100ns;
        sensor_raw = 1'b1;

        wait(callib_done == 1'b1);
        $display("[%0t] Kalibracja zakonczona. Pozycja wyzerowana.", $time);
        sensor_raw = 1'b0;

        #20ns;
        callib = 1'b0;
        #50ns;

        // TEST 2: Ruch
        $display("[%0t] Zadanie ruchu do pozycji 15...", $time);
        target_pos = 32'd15;
        go_to = 1'b1;
        #10ns;
        go_to = 1'b0;

        wait(current_pos == 32'd15);
        $display("[%0t] Osiagnieto pozycje 15.", $time);
        #100ns;

        // TEST 3: Powrot
        $display("[%0t] Zadanie ruchu do pozycji 5...", $time);
        target_pos = 32'd5;
        go_to = 1'b1;
        #10ns;
        go_to = 1'b0;

        wait(current_pos == 32'd5);
        $display("[%0t] Osiagnieto pozycje 5.", $time);
        #100ns;

        $display("[%0t] Koniec symulacji.", $time);
        $finish;
    end

endmodule