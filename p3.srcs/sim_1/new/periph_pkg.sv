`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 08:59:08 AM
// Design Name: 
// Module Name: periph_pkg
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


package periph_pkg;

    // Timer registers
    localparam logic [3:0] REG_TMR_CTRL  = 4'h0;
    localparam logic [3:0] REG_TMR_PRESC = 4'h1;
    localparam logic [3:0] REG_TMR_LOAD  = 4'h2;
    localparam logic [3:0] REG_TMR_CMP   = 4'h3;
    localparam logic [3:0] REG_TMR_CNT   = 4'h4;

    // ADC registers
    localparam logic [3:0] REG_ADC_CTRL   = 4'h5;
    localparam logic [3:0] REG_ADC_SMP    = 4'h6;
    localparam logic [3:0] REG_ADC_DIV    = 4'h7;
    localparam logic [3:0] REG_ADC_THR_LO = 4'h8;
    localparam logic [3:0] REG_ADC_THR_HI = 4'h9;
    localparam logic [3:0] REG_ADC_DATA   = 4'hA;
    localparam logic [3:0] REG_ADC_RCH    = 4'hB;
    localparam logic [3:0] REG_ADC_STAT   = 4'hC;

    // IRQ registers
    localparam logic [3:0] REG_IRQ_EN   = 4'hD;
    localparam logic [3:0] REG_IRQ_STAT = 4'hE;

    // Peripheral ID
    localparam logic [3:0] REG_ID = 4'hF;

    localparam logic [7:0] PERIPH_ID = 8'hA8;

endpackage
