`timescale 1ns / 1ps

interface periph_if(input logic clk);

    // Reset - driven by testbench
    logic rst_n;

    // CPU-facing bus
    logic        cs;
    logic        we;
    logic [3:0]  addr;
    logic [7:0]  wdata;

    // DUT outputs
    wire [7:0] rdata;
    wire       irq;
    wire       pwm_out;

    // ADC signals
    wire        adc_sample;
    wire [1:0]  adc_ch;
    wire [7:0]  adc_dac;

    // Comparator input - driven by testbench
    logic       adc_cmp;

endinterface