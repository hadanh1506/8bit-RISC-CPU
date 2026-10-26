`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 05:24:17 PM
// Design Name: 
// Module Name: data_mem
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

module data_mem (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       mem_read,
    input  wire       mem_write,
    input  wire [7:0] addr,
    input  wire [7:0] write_data,
    output wire [7:0] read_data
);
    reg [7:0] ram [0:255];
    integer i;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 256; i = i + 1)
                ram[i] <= 8'h00;
        end else if (mem_write) begin
            ram[addr] <= write_data;
        end
    end

    assign read_data = mem_read ? ram[addr] : 8'h00;
endmodule
