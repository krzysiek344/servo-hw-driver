`timescale 1ns / 1ps

module top_servo_drv #(
    parameter POS_RANGE     = 32, 
    parameter SCALE_WIDTH   = 32,
    parameter DELAY_CYCLES  = 1000000,
    parameter COILS_NUM     = 4
) (
    input  logic clk,
    input  logic rst_n,

    output logic [COILS_NUM-1:0] stepper_phases,
    output logic callib_done,
    output logic [POS_RANGE-1:0] current_pos,

    input  logic enable,
    input  logic callib,
    input  logic go_to,
    input  logic [POS_RANGE-1:0] target_pos,
    input  logic [SCALE_WIDTH-1:0] scale_val,
    input  logic inversion,
    input  logic sensor_raw
);

    logic sensor_clean_w;
    logic set_zero_w;
    logic dir_w;
    logic prescaler_enable_w;
    logic step_tick_w;

    master_fsm #(
        .POS_RANGE(POS_RANGE)
    ) u_master_fsm (
        .clk              (clk),
        .rst_n            (rst_n),
        .set_zero         (set_zero_w),
        .dir              (dir_w),
        .callib_done      (callib_done),
        .prescaler_enable (prescaler_enable_w),
        .enable           (enable),
        .callib           (callib),
        .go_to            (go_to),
        .sensor_clean     (sensor_clean_w),
        .target_position  (target_pos),
        .current_position (current_pos)
    );

    prescaler #(
        .SCALE_WIDTH(SCALE_WIDTH)
    )u_prescaler(
        .clk       (clk),
        .rst_n     (rst_n),
        .step_tick (step_tick_w),
        .enable    (prescaler_enable_w),
        .scale_val (scale_val)
    );

    debouncer #(
        .DELAY_CYCLES(DELAY_CYCLES)
    ) u_debouncer (
        .clk            (clk),
        .rst_n          (rst_n),
        .cleared_signal (sensor_clean_w),
        .signal_in      (sensor_raw)
    );

    sequencer #(
        .COILS_NUM(COILS_NUM)
    )u_sequencer (
        .clk            (clk),
        .rst_n          (rst_n),
        .stepper_phases (stepper_phases),
        .step_tick      (step_tick_w),
        .dir            (dir_w),
        .inversion      (inversion)
    );

    step_counter #(
        .POS_RANGE(POS_RANGE)
    )u_step_counter (
        .clk         (clk),
        .rst_n       (rst_n),
        .current_pos (current_pos),
        .step_tick   (step_tick_w),
        .dir         (dir_w),
        .set_zero    (set_zero_w)
    );

endmodule
