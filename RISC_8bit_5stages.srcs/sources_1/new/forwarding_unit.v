`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 05:25:07 PM
// Design Name: 
// Module Name: forwarding_unit
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

module forwarding_unit (
    input  wire [2:0] rs1_ex,
    input  wire [2:0] rs2_ex,
    input  wire       reg_write_mem,
    input  wire [2:0] rd_mem,
    input  wire       reg_write_wb,
    input  wire [2:0] rd_wb,
    output reg  [1:0] forward_a, // 00: ID/EX, 10: EX/MEM, 01: MEM/WB
    output reg  [1:0] forward_b
);
    always @(*) begin
        // Forwarding cho Toán hạng A (Rs1)
        if (reg_write_mem && (rd_mem != 3'b000) && (rd_mem == rs1_ex))
            forward_a = 2'b10; // Ưu tiên dữ liệu mới nhất ở tầng MEM
        else if (reg_write_wb && (rd_wb != 3'b000) && (rd_wb == rs1_ex))
            forward_a = 2'b01; // Dữ liệu ở tầng WB
        else
            forward_a = 2'b00;

        // Forwarding cho Toán hạng B (Rs2)
        if (reg_write_mem && (rd_mem != 3'b000) && (rd_mem == rs2_ex))
            forward_b = 2'b10;
        else if (reg_write_wb && (rd_wb != 3'b000) && (rd_wb == rs2_ex))
            forward_b = 2'b01;
        else
            forward_b = 2'b00;
    end
endmodule
