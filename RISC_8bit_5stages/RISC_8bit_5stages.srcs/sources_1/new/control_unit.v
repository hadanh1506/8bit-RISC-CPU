`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 05:23:03 PM
// Design Name: 
// Module Name: control_unit
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

module control_unit (
    input  wire [3:0] opcode,
    input  wire [2:0] funct,
    output reg        reg_write,
    output reg        mem_to_reg,
    output reg        mem_read,
    output reg        mem_write,
    output reg        branch,
    output reg        jump,
    output reg        alu_src,    // 0: Thanh ghi Rs2, 1: Hằng số Immediate
    output reg  [2:0] alu_ctrl
);
    always @(*) begin
        // Giá trị mặc định (NOP) tránh tạo Latch
        reg_write  = 1'b0;
        mem_to_reg = 1'b0;
        mem_read   = 1'b0;
        mem_write  = 1'b0;
        branch     = 1'b0;
        jump       = 1'b0;
        alu_src    = 1'b0;
        alu_ctrl   = 3'b000; // Mặc định là ADD

        case (opcode)
            4'b0001: begin // R-Type
                reg_write = 1'b1;
                alu_src   = 1'b0;
                alu_ctrl  = funct; // Funct chọn trực tiếp phép toán ALU
            end
            4'b0010: begin // ADDI
                reg_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = 3'b000; // ADD
            end
            4'b0011: begin // LW
                reg_write  = 1'b1;
                mem_to_reg = 1'b1;
                mem_read   = 1'b1;
                alu_src    = 1'b1;
                alu_ctrl   = 3'b000; // ADD tính địa chỉ
            end
            4'b0100: begin // SW
                mem_write = 1'b1;
                alu_src   = 1'b1;
                alu_ctrl  = 3'b000; // ADD tính địa chỉ
            end
            4'b0101: begin // BEQ
                branch   = 1'b1;
                alu_src  = 1'b0;
                alu_ctrl = 3'b001; // SUB để kiểm tra cờ Zero
            end
            4'b0110: begin // JMP
                jump = 1'b1;
            end
            default: ; // NOP
        endcase
    end
endmodule
