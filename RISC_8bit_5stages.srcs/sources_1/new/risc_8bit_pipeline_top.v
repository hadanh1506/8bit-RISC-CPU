`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 05:26:11 PM
// Design Name: 
// Module Name: risc_8bit_pipeline_top
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

module risc_8bit_pipeline_top (
    input  wire       clk,
    input  wire       rst_n,
    // Các cổng quan sát phục vụ Debug & giữ logic khi Synthesis
    output wire [7:0] debug_pc,
    output wire [7:0] debug_alu_ex,
    output wire [7:0] debug_wb_data,
    output wire [2:0] debug_wb_rd,
    output wire       debug_wb_regwrite
);

    // --- Dây tín hiệu Tầng IF ---
    wire [7:0]  pc_current, pc_next, pc_plus1_if;
    wire [15:0] inst_if;
    wire        stall_if_id, flush_if_id, flush_id_ex;
    wire        branch_taken_ex;
    wire [7:0]  branch_target_ex, jump_target_id;

    // --- Dây tín hiệu Tầng ID ---
    wire [7:0]  pc_plus1_id;
    wire [15:0] inst_id;
    wire [3:0]  opcode_id = inst_id[15:12];
    wire [2:0]  rd_id     = inst_id[11:9];
    wire [2:0]  rs1_id    = inst_id[8:6];
    // Với SW (0100) và BEQ (0101), thanh ghi nguồn thứ 2 nằm ở vị trí [11:9] (rd_id)
    wire [2:0]  rs2_id    = (opcode_id == 4'b0100 || opcode_id == 4'b0101) ? inst_id[11:9] : inst_id[5:3];
    wire [2:0]  funct_id  = inst_id[2:0];
    wire [7:0]  imm_ext_id = {{2{inst_id[5]}}, inst_id[5:0]}; // Sign-extend 6-bit lên 8-bit
    
    wire        reg_write_id, mem_to_reg_id, mem_read_id, mem_write_id, branch_id, jump_id, alu_src_id;
    wire [2:0]  alu_ctrl_id;
    wire [7:0]  rdata1_id, rdata2_id;

    // --- Dây tín hiệu Tầng EX ---
    wire        reg_write_ex, mem_to_reg_ex, mem_read_ex, mem_write_ex, branch_ex, alu_src_ex;
    wire [2:0]  alu_ctrl_ex;
    wire [7:0]  pc_plus1_ex, rdata1_ex, rdata2_ex, imm_ext_ex;
    wire [2:0]  rs1_ex, rs2_ex, rd_ex;
    wire [1:0]  forward_a, forward_b;
    wire [7:0]  alu_in_a, alu_in_b_temp, alu_in_b, alu_result_ex;
    wire        alu_zero_ex;

    // --- Dây tín hiệu Tầng MEM ---
    wire        reg_write_mem, mem_to_reg_mem, mem_read_mem, mem_write_mem;
    wire [7:0]  alu_result_mem, write_data_mem, mem_read_data_mem;
    wire [2:0]  rd_mem;

    // --- Dây tín hiệu Tầng WB ---
    wire        reg_write_wb, mem_to_reg_wb;
    wire [7:0]  mem_read_data_wb, alu_result_wb, wb_data;
    wire [2:0]  rd_wb;

    // =========================================================================
    // TẦNG 1: INSTRUCTION FETCH (IF)
    // =========================================================================
    assign pc_plus1_if    = pc_current + 8'd1;
    assign jump_target_id = inst_id[7:0];
    assign pc_next        = branch_taken_ex ? branch_target_ex :
                            jump_id         ? jump_target_id   : pc_plus1_if;

    pc_reg u_pc (
        .clk     (clk),
        .rst_n   (rst_n),
        .stall   (stall_if_id),
        .next_pc (pc_next),
        .pc_out  (pc_current)
    );

    inst_mem u_imem (
        .addr (pc_current),
        .inst (inst_if)
    );

    if_id_reg u_if_id (
        .clk          (clk),
        .rst_n        (rst_n),
        .stall        (stall_if_id),
        .flush        (flush_if_id),
        .pc_plus1_in  (pc_plus1_if),
        .inst_in      (inst_if),
        .pc_plus1_out (pc_plus1_id),
        .inst_out     (inst_id)
    );

    // =========================================================================
    // TẦNG 2: INSTRUCTION DECODE (ID)
    // =========================================================================
    control_unit u_ctrl (
        .opcode     (opcode_id),
        .funct      (funct_id),
        .reg_write  (reg_write_id),
        .mem_to_reg (mem_to_reg_id),
        .mem_read   (mem_read_id),
        .mem_write  (mem_write_id),
        .branch     (branch_id),
        .jump       (jump_id),
        .alu_src    (alu_src_id),
        .alu_ctrl   (alu_ctrl_id)
    );

    reg_file u_rf (
        .clk           (clk),
        .rst_n         (rst_n),
        .rs1_addr      (rs1_id),
        .rs2_addr      (rs2_id),
        .reg_write_wb  (reg_write_wb),
        .rd_addr_wb    (rd_wb),
        .write_data_wb (wb_data),
        .read_data1    (rdata1_id),
        .read_data2    (rdata2_id)
    );

    id_ex_reg u_id_ex (
        .clk            (clk),
        .rst_n          (rst_n),
        .flush          (flush_id_ex),
        .reg_write_in   (reg_write_id),
        .mem_to_reg_in  (mem_to_reg_id),
        .mem_read_in    (mem_read_id),
        .mem_write_in   (mem_write_id),
        .branch_in      (branch_id),
        .alu_src_in     (alu_src_id),
        .alu_ctrl_in    (alu_ctrl_id),
        .pc_plus1_in    (pc_plus1_id),
        .rdata1_in      (rdata1_id),
        .rdata2_in      (rdata2_id),
        .imm_ext_in     (imm_ext_id),
        .rs1_in         (rs1_id),
        .rs2_in         (rs2_id),
        .rd_in          (rd_id),
        .reg_write_out  (reg_write_ex),
        .mem_to_reg_out (mem_to_reg_ex),
        .mem_read_out   (mem_read_ex),
        .mem_write_out  (mem_write_ex),
        .branch_out     (branch_ex),
        .alu_src_out    (alu_src_ex),
        .alu_ctrl_out   (alu_ctrl_ex),
        .pc_plus1_out   (pc_plus1_ex),
        .rdata1_out     (rdata1_ex),
        .rdata2_out     (rdata2_ex),
        .imm_ext_out    (imm_ext_ex),
        .rs1_out        (rs1_ex),
        .rs2_out        (rs2_ex),
        .rd_out         (rd_ex)
    );

    // =========================================================================
    // TẦNG 3: EXECUTE (EX)
    // =========================================================================
    forwarding_unit u_fwd (
        .rs1_ex        (rs1_ex),
        .rs2_ex        (rs2_ex),
        .reg_write_mem (reg_write_mem),
        .rd_mem        (rd_mem),
        .reg_write_wb  (reg_write_wb),
        .rd_wb         (rd_wb),
        .forward_a     (forward_a),
        .forward_b     (forward_b)
    );

    // Mux Forwarding A
    assign alu_in_a = (forward_a == 2'b10) ? alu_result_mem :
                      (forward_a == 2'b01) ? wb_data        : rdata1_ex;

    // Mux Forwarding B
    assign alu_in_b_temp = (forward_b == 2'b10) ? alu_result_mem :
                           (forward_b == 2'b01) ? wb_data        : rdata2_ex;

    // Mux chọn giữa thanh ghi (đã Forward) và hằng số Immediate
    assign alu_in_b = alu_src_ex ? imm_ext_ex : alu_in_b_temp;

    alu_8bit u_alu (
        .a        (alu_in_a),
        .b        (alu_in_b),
        .alu_ctrl (alu_ctrl_ex),
        .result   (alu_result_ex),
        .zero     (alu_zero_ex)
    );

    assign branch_target_ex = pc_plus1_ex + imm_ext_ex;
    assign branch_taken_ex  = branch_ex && alu_zero_ex;

    hazard_unit u_hazard (
        .rs1_id          (rs1_id),
        .rs2_id          (rs2_id),
        .mem_read_ex     (mem_read_ex),
        .rd_ex           (rd_ex),
        .branch_taken_ex (branch_taken_ex),
        .jump_id         (jump_id),
        .stall_if_id     (stall_if_id),
        .flush_if_id     (flush_if_id),
        .flush_id_ex     (flush_id_ex)
    );

    ex_mem_reg u_ex_mem (
        .clk            (clk),
        .rst_n          (rst_n),
        .reg_write_in   (reg_write_ex),
        .mem_to_reg_in  (mem_to_reg_ex),
        .mem_read_in    (mem_read_ex),
        .mem_write_in   (mem_write_ex),
        .alu_result_in  (alu_result_ex),
        .write_data_in  (alu_in_b_temp), // Dữ liệu ghi vào RAM khi chạy lệnh SW
        .rd_in          (rd_ex),
        .reg_write_out  (reg_write_mem),
        .mem_to_reg_out (mem_to_reg_mem),
        .mem_read_out   (mem_read_mem),
        .mem_write_out  (mem_write_mem),
        .alu_result_out (alu_result_mem),
        .write_data_out (write_data_mem),
        .rd_out         (rd_mem)
    );

    // =========================================================================
    // TẦNG 4: MEMORY ACCESS (MEM)
    // =========================================================================
    data_mem u_dmem (
        .clk        (clk),
        .rst_n      (rst_n),
        .mem_read   (mem_read_mem),
        .mem_write  (mem_write_mem),
        .addr       (alu_result_mem),
        .write_data (write_data_mem),
        .read_data  (mem_read_data_mem)
    );

    mem_wb_reg u_mem_wb (
        .clk            (clk),
        .rst_n          (rst_n),
        .reg_write_in   (reg_write_mem),
        .mem_to_reg_in  (mem_to_reg_mem),
        .read_data_in   (mem_read_data_mem),
        .alu_result_in  (alu_result_mem),
        .rd_in          (rd_mem),
        .reg_write_out  (reg_write_wb),
        .mem_to_reg_out (mem_to_reg_wb),
        .read_data_out  (mem_read_data_wb),
        .alu_result_out (alu_result_wb),
        .rd_out         (rd_wb)
    );

    // =========================================================================
    // TẦNG 5: WRITE BACK (WB)
    // =========================================================================
    assign wb_data = mem_to_reg_wb ? mem_read_data_wb : alu_result_wb;

    // Gán ra các chân Debug Output
    assign debug_pc          = pc_current;
    assign debug_alu_ex      = alu_result_ex;
    assign debug_wb_data     = wb_data;
    assign debug_wb_rd       = rd_wb;
    assign debug_wb_regwrite = reg_write_wb;

endmodule
