`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 05:25:39 PM
// Design Name: 
// Module Name: hazard_unit
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

module hazard_unit (
    input  wire [2:0] rs1_id,
    input  wire [2:0] rs2_id,
    input  wire       mem_read_ex,
    input  wire [2:0] rd_ex,
    input  wire       branch_taken_ex,
    input  wire       jump_id,
    output wire       stall_if_id,
    output wire       flush_if_id,
    output wire       flush_id_ex
);
    // Load-Use Hazard: Lệnh ở EX là LW và thanh ghi đích trùng với thanh ghi nguồn ở ID
    wire load_use_hazard;
    assign load_use_hazard = mem_read_ex && (rd_ex != 3'b000) &&
                             ((rd_ex == rs1_id) || (rd_ex == rs2_id));

    assign stall_if_id = load_use_hazard;
    assign flush_if_id = branch_taken_ex || jump_id;
    assign flush_id_ex = load_use_hazard || branch_taken_ex;
endmodule
