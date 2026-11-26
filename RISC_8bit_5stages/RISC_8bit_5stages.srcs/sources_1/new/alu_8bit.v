`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 05:23:45 PM
// Design Name: 
// Module Name: alu_8bit
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

module alu_8bit (
    input  wire [7:0] a,
    input  wire [7:0] b,
    input  wire [2:0] alu_ctrl,
    output reg  [7:0] result,
    output wire       zero
);
    always @(*) begin
        case (alu_ctrl)
            3'b000: result = a + b;                        // ADD
            3'b001: result = a - b;                        // SUB
            3'b010: result = a & b;                        // AND
            3'b011: result = a | b;                        // OR
            3'b100: result = a ^ b;                        // XOR
            3'b101: result = ($signed(a) < $signed(b)) ? 8'd1 : 8'd0; // SLT (Có dấu)
            3'b110: result = a << b[2:0];                  // SLL
            3'b111: result = a >> b[2:0];                  // SRL
            default: result = 8'h00;
        endcase
    end

    assign zero = (result == 8'h00);
endmodule
