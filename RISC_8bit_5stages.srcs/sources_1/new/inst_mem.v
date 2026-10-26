`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 05:22:42 PM
// Design Name: 
// Module Name: inst_mem
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

module inst_mem (
    input  wire [7:0]  addr,
    output wire [15:0] inst
);
    reg [15:0] rom [0:255];
    integer i;

    initial begin
        for (i = 0; i < 256; i = i + 1)
            rom[i] = 16'h0000; // Mặc định là NOP

        // --- CHƯƠNG TRÌNH TEST MẪU ---
        // Định dạng I-Type: Opcode(4) _ Rd(3) _ Rs1(3) _ Imm6(6)
        // Định dạng R-Type: Opcode(4) _ Rd(3) _ Rs1(3) _ Rs2(3) _ Funct(3)
        
        // 0: ADDI R1, R0, 5   (R1 = 0 + 5 = 5)
        rom[0] = 16'b0010_001_000_000101;
        // 1: ADDI R2, R0, 3   (R2 = 0 + 3 = 3)
        rom[1] = 16'b0010_010_000_000011;
        // 2: ADD  R3, R1, R2  (R3 = R1 + R2 = 8) -> Test Forwarding từ MEM/WB (R1) và EX/MEM (R2)
        rom[2] = 16'b0001_011_001_010_000;
        // 3: SW   R3, 4(R0)   (Mem[4] = R3 = 8)  -> Test Forwarding cho Store
        rom[3] = 16'b0100_011_000_000100;
        // 4: LW   R4, 4(R0)   (R4 = Mem[4] = 8)
        rom[4] = 16'b0011_100_000_000100;
        // 5: SUB  R5, R4, R2  (R5 = R4 - R2 = 5) -> Test Load-Use Hazard (Stall 1 chu kỳ vì đợi R4)
        rom[5] = 16'b0001_101_100_010_001;
    end

    assign inst = rom[addr];
endmodule
