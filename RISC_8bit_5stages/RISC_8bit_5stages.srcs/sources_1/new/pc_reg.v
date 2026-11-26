`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 05:22:11 PM
// Design Name: 
// Module Name: pc_reg
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

module pc_reg (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       stall,     // 1: Giữ nguyên PC (Load-Use Hazard)
    input  wire [7:0] next_pc,
    output reg  [7:0] pc_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            pc_out <= 8'h00;
        else if (!stall)
            pc_out <= next_pc;
    end
endmodule
