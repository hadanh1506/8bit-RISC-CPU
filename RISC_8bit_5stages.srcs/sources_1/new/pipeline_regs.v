`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 05:24:42 PM
// Design Name: 
// Module Name: pipeline_regs
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

// 1. Thanh ghi IF/ID
module if_id_reg (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        stall,
    input  wire        flush,
    input  wire [7:0]  pc_plus1_in,
    input  wire [15:0] inst_in,
    output reg  [7:0]  pc_plus1_out,
    output reg  [15:0] inst_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            pc_plus1_out <= 8'h00;
            inst_out     <= 16'h0000;
        end else if (!stall) begin
            pc_plus1_out <= pc_plus1_in;
            inst_out     <= inst_in;
        end
    end
endmodule

// 2. Thanh ghi ID/EX
module id_ex_reg (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       flush,
    // Control inputs
    input  wire       reg_write_in,
    input  wire       mem_to_reg_in,
    input  wire       mem_read_in,
    input  wire       mem_write_in,
    input  wire       branch_in,
    input  wire       alu_src_in,
    input  wire [2:0] alu_ctrl_in,
    // Data inputs
    input  wire [7:0] pc_plus1_in,
    input  wire [7:0] rdata1_in,
    input  wire [7:0] rdata2_in,
    input  wire [7:0] imm_ext_in,
    input  wire [2:0] rs1_in,
    input  wire [2:0] rs2_in,
    input  wire [2:0] rd_in,
    // Outputs
    output reg        reg_write_out,
    output reg        mem_to_reg_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg        branch_out,
    output reg        alu_src_out,
    output reg  [2:0] alu_ctrl_out,
    output reg  [7:0] pc_plus1_out,
    output reg  [7:0] rdata1_out,
    output reg  [7:0] rdata2_out,
    output reg  [7:0] imm_ext_out,
    output reg  [2:0] rs1_out,
    output reg  [2:0] rs2_out,
    output reg  [2:0] rd_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n || flush) begin
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            branch_out     <= 1'b0;
            alu_src_out    <= 1'b0;
            alu_ctrl_out   <= 3'b000;
            pc_plus1_out   <= 8'h00;
            rdata1_out     <= 8'h00;
            rdata2_out     <= 8'h00;
            imm_ext_out    <= 8'h00;
            rs1_out        <= 3'b000;
            rs2_out        <= 3'b000;
            rd_out         <= 3'b000;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            branch_out     <= branch_in;
            alu_src_out    <= alu_src_in;
            alu_ctrl_out   <= alu_ctrl_in;
            pc_plus1_out   <= pc_plus1_in;
            rdata1_out     <= rdata1_in;
            rdata2_out     <= rdata2_in;
            imm_ext_out    <= imm_ext_in;
            rs1_out        <= rs1_in;
            rs2_out        <= rs2_in;
            rd_out         <= rd_in;
        end
    end
endmodule

// 3. Thanh ghi EX/MEM
module ex_mem_reg (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       reg_write_in,
    input  wire       mem_to_reg_in,
    input  wire       mem_read_in,
    input  wire       mem_write_in,
    input  wire [7:0] alu_result_in,
    input  wire [7:0] write_data_in,
    input  wire [2:0] rd_in,
    output reg        reg_write_out,
    output reg        mem_to_reg_out,
    output reg        mem_read_out,
    output reg        mem_write_out,
    output reg  [7:0] alu_result_out,
    output reg  [7:0] write_data_out,
    output reg  [2:0] rd_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            mem_read_out   <= 1'b0;
            mem_write_out  <= 1'b0;
            alu_result_out <= 8'h00;
            write_data_out <= 8'h00;
            rd_out         <= 3'b000;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            mem_read_out   <= mem_read_in;
            mem_write_out  <= mem_write_in;
            alu_result_out <= alu_result_in;
            write_data_out <= write_data_in;
            rd_out         <= rd_in;
        end
    end
endmodule

// 4. Thanh ghi MEM/WB
module mem_wb_reg (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       reg_write_in,
    input  wire       mem_to_reg_in,
    input  wire [7:0] read_data_in,
    input  wire [7:0] alu_result_in,
    input  wire [2:0] rd_in,
    output reg        reg_write_out,
    output reg        mem_to_reg_out,
    output reg  [7:0] read_data_out,
    output reg  [7:0] alu_result_out,
    output reg  [2:0] rd_out
);
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            reg_write_out  <= 1'b0;
            mem_to_reg_out <= 1'b0;
            read_data_out  <= 8'h00;
            alu_result_out <= 8'h00;
            rd_out         <= 3'b000;
        end else begin
            reg_write_out  <= reg_write_in;
            mem_to_reg_out <= mem_to_reg_in;
            read_data_out  <= read_data_in;
            alu_result_out <= alu_result_in;
            rd_out         <= rd_in;
        end
    end
endmodule
