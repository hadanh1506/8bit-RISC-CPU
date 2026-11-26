`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2026 07:46:19 PM
// Design Name: 
// Module Name: timer_adc8_cpu_if
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

module timer_adc8_cpu_if (
    input  wire       clk,
    input  wire       rst_n,

    // Giao tiep voi CPU
    input  wire       cs,
    input  wire       we,
    input  wire [3:0] addr,
    input  wire [7:0] wdata,
    output wire [7:0] rdata,

    // Tin hieu ADC analog
    output wire       adc_sample,
    output wire [1:0] adc_ch,
    output wire [7:0] adc_dac,
    input  wire       adc_cmp,

    // Tin hieu ngoai vi
    output wire       irq,
    output wire       pwm_out
);

    // Ket noi toan bo Peripheral
    timer_adc8_top u_timer_adc (
        .clk        (clk),
        .rst_n      (rst_n),

        // CPU bus
        .cs         (cs),
        .we         (we),
        .addr       (addr),
        .wdata      (wdata),
        .rdata      (rdata),

        // ADC analog
        .adc_sample (adc_sample),
        .adc_ch     (adc_ch),
        .adc_dac    (adc_dac),
        .adc_cmp    (adc_cmp),

        // External signals
        .irq        (irq),
        .pwm_out    (pwm_out)
    );

endmodule

