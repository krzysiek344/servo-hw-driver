`timescale 1ns / 1ps

module top_basys3 (
    input  wire clk,
    input  wire btnC,     
    input  wire btnU,    
    input  wire btnD,     
    input  wire btnR,    
    input  wire [0:0] sw, 

    output wire [15:0] led, 
    output wire [3:0] JA   
);

    logic rst_n;
    logic [31:0] current_pos_w;
    logic [3:0]  stepper_phases_w;
    logic        callib_done_w;

    assign rst_n = ~btnC;

    assign JA = stepper_phases_w;

    // LED 3:0   - Podgląd na żywo wędrującej jedynki (fazy silnika)
    // LED 6:4   - Nieużywane (wymuszone 0)
    // LED 14:7  - Podgląd 8 najmłodszych bitów aktualnej pozycji (licznik krokowy)
    // LED 15    - Flaga zakończenia kalibracji
    assign led[3:0]   = stepper_phases_w;
    assign led[6:4]   = 3'b000;
    assign led[14:7]  = current_pos_w[7:0];
    assign led[15]    = callib_done_w;

    top_servo_drv #(
        .POS_RANGE(32),
        .SCALE_WIDTH(32),
        .DELAY_CYCLES(1000000) 
    ) u_top_servo_drv (
        .clk            (clk),
        .rst_n          (rst_n),
        .stepper_phases (stepper_phases_w),
        .callib_done    (callib_done_w),
        .current_pos    (current_pos_w),
        
        .enable         (sw[0]),
        .callib         (btnU),
        .go_to          (btnD),
        .target_pos     (32'd50),       
        .scale_val      (32'd4_000_000), 
        .inversion      (1'b0),          
        .sensor_raw     (btnR)
    );

endmodule