`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 05:23:24 PM
// Design Name: 
// Module Name: reg_file
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

module reg_file (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [2:0] rs1_addr,
    input  wire [2:0] rs2_addr,
    input  wire       reg_write_wb,
    input  wire [2:0] rd_addr_wb,
    input  wire [7:0] write_data_wb,
    output wire [7:0] read_data1,
    output wire [7:0] read_data2
);
    reg [7:0] regs [0:7];
    integer i;

    // Ghi đồng bộ ở sườn lên clock (R0 luôn bằng 0)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < 8; i = i + 1)
                regs[i] <= 8'h00;
        end else if (reg_write_wb && (rd_addr_wb != 3'b000)) begin
            regs[rd_addr_wb] <= write_data_wb;
        end
    end

    // Đọc tổ hợp kèm Internal Forwarding
    assign read_data1 = (rs1_addr == 3'b000) ? 8'h00 :
                        ((reg_write_wb && (rd_addr_wb == rs1_addr)) ? write_data_wb : regs[rs1_addr]);

    assign read_data2 = (rs2_addr == 3'b000) ? 8'h00 :
                        ((reg_write_wb && (rd_addr_wb == rs2_addr)) ? write_data_wb : regs[rs2_addr]);
endmodule
