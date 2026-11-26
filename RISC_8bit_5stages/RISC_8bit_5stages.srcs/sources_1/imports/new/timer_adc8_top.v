`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2026 07:41:42 PM
// Design Name: 
// Module Name: timer_adc8_top
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////



`timescale 1ns / 1ps

module timer_adc8_top (
    input  wire       clk,
    input  wire       rst_n,

    // Bus giao tiep CPU
    input  wire       cs,
    input  wire       we,
    input  wire [3:0] addr,
    input  wire [7:0] wdata,
    output wire [7:0] rdata,

    // Tin hieu Analog
    output wire       adc_sample,
    output wire [1:0] adc_ch,
    output wire [7:0] adc_dac,
    input  wire       adc_cmp,

    // Tin hieu ngoai vi
    output wire       irq,
    output wire       pwm_out
);

    // ==================================================
    // Tin hieu cau hinh Timer
    // ==================================================
    wire        timer_en;
    wire        timer_oneshot;
    wire [7:0]  timer_presc;
    wire [7:0]  timer_load;
    wire [7:0]  timer_cmp;
    wire [7:0]  timer_count;

    wire        timer_tick;
    wire        timer_ovf_evt;
    wire        timer_cmp_evt;

    // ==================================================
    // Tin hieu cau hinh ADC
    // ==================================================
    wire        adc_en;
    wire        adc_start;
    wire [1:0]  adc_trig_sel;
    wire [1:0]  adc_channel;
    wire [7:0]  adc_smp;
    wire [7:0]  adc_div;
    wire [7:0]  adc_thr_lo;
    wire [7:0]  adc_thr_hi;

    wire        adc_busy;
    wire        adc_result_valid;
    wire [7:0]  adc_result_data;
    wire [1:0]  adc_result_ch;

    // ==================================================
    // Tin hieu FIFO
    // ==================================================
    wire [7:0] fifo_data;
    wire [1:0] fifo_ch;
    wire [3:0] fifo_level;

    wire fifo_full;
    wire fifo_empty;
    wire fifo_overflow;
    wire fifo_rd_en;

    // ==================================================
    // 1. TIMER
    // ==================================================
    timer8 u_timer (
        .clk       (clk),
        .rst_n     (rst_n),
        .en        (timer_en),
        .oneshot   (timer_oneshot),
        .presc     (timer_presc),
        .load      (timer_load),
        .cmp       (timer_cmp),
        .count     (timer_count),
        .tick      (timer_tick),
        .pwm       (pwm_out),
        .ovf_evt   (timer_ovf_evt),
        .cmp_evt   (timer_cmp_evt)
    );

    // ==================================================
    // 2. SAR ADC
    // ==================================================
    sar_adc_ctrl u_adc (
        .clk           (clk),
        .rst_n         (rst_n),
        .en            (adc_en),
        .start         (adc_start),
        .trig_sel      (adc_trig_sel),
        .timer_ovf     (timer_ovf_evt),
        .timer_cmp     (timer_cmp_evt),
        .channel       (adc_channel),
        .smp            (adc_smp),
        .div            (adc_div),
        .adc_cmp        (adc_cmp),
        .adc_sample     (adc_sample),
        .adc_ch         (adc_ch),
        .adc_dac        (adc_dac),
        .result_data    (adc_result_data),
        .result_ch      (adc_result_ch),
        .result_valid   (adc_result_valid),
        .busy           (adc_busy)
    );

    // ==================================================
    // 3. FIFO
    // ==================================================
    sync_fifo u_fifo (
        .clk       (clk),
        .rst_n     (rst_n),
        .wr_en     (adc_result_valid),
        .wr_data   (adc_result_data),
        .wr_ch     (adc_result_ch),
        .rd_en     (fifo_rd_en),
        .rd_data   (fifo_data),
        .rd_ch     (fifo_ch),
        .full      (fifo_full),
        .empty     (fifo_empty),
        .level     (fifo_level),
        .overflow  (fifo_overflow)
    );

    // ==================================================
    // 4. REGISTER MAP + IRQ
    // ==================================================
    apb_regs8 u_regs (
        .clk                (clk),
        .rst_n              (rst_n),

        .cs                 (cs),
        .we                 (we),
        .addr               (addr),
        .wdata              (wdata),
        .rdata              (rdata),

        // Timer
        .timer_en           (timer_en),
        .timer_oneshot      (timer_oneshot),
        .timer_presc        (timer_presc),
        .timer_load         (timer_load),
        .timer_cmp          (timer_cmp),
        .timer_count        (timer_count),
        .timer_ovf_evt      (timer_ovf_evt),
        .timer_cmp_evt      (timer_cmp_evt),

        // ADC
        .adc_en             (adc_en),
        .adc_start          (adc_start),
        .adc_trig_sel       (adc_trig_sel),
        .adc_channel        (adc_channel),
        .adc_smp            (adc_smp),
        .adc_div            (adc_div),
        .adc_thr_lo         (adc_thr_lo),
        .adc_thr_hi         (adc_thr_hi),
        .adc_busy           (adc_busy),
        .adc_result_valid   (adc_result_valid),
        .adc_result_data    (adc_result_data),

        // FIFO
        .fifo_data          (fifo_data),
        .fifo_ch            (fifo_ch),
        .fifo_level         (fifo_level),
        .fifo_full          (fifo_full),
        .fifo_empty         (fifo_empty),
        .fifo_overflow      (fifo_overflow),
        .fifo_rd_en         (fifo_rd_en),

        .irq                (irq)
    );

endmodule

