`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 10/17/2026 05:28:39 PM
// Design Name: 8-bit 5-Stage Pipelined RISC Processor
// Module Name: tb_risc_8bit
// Project Name: RISC_8bit_5stages
// Target Devices: 
// Tool Versions: Vivado 2026.1
// Description: Self-checking testbench for 8-bit 5-stage pipelined RISC CPU
// 
// Dependencies: risc_8bit_pipeline_top.v
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module tb_risc_8bit;

    // 1. Declare signals connected to the Top module (UUT)
    reg        clk;
    reg        rst_n;
    wire [7:0] debug_pc;
    wire [7:0] debug_alu_ex;
    wire [7:0] debug_wb_data;
    wire [2:0] debug_wb_rd;
    wire       debug_wb_regwrite;

    // Clock cycle counter for easy waveform tracking
    integer cycle_count;

    // 2. Instantiate the Unit Under Test (UUT)
    risc_8bit_pipeline_top uut (
        .clk               (clk),
        .rst_n             (rst_n),
        .debug_pc          (debug_pc),
        .debug_alu_ex      (debug_alu_ex),
        .debug_wb_data     (debug_wb_data),
        .debug_wb_rd       (debug_wb_rd),
        .debug_wb_regwrite (debug_wb_regwrite)
    );

    // 3. Generate 100MHz Clock (Period T = 10ns: 5ns low, 5ns high)
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // 4. Reset Sequence and Automated Self-Checking
    initial begin
        rst_n       = 1'b0;
        cycle_count = 0;

        // Hold Reset for 15ns (across the first rising clock edge at 5ns)
        #15;
        rst_n = 1'b1;

        $display("==========================================================================================================");
        $display(" STARTING 8-BIT 5-STAGE PIPELINED RISC SIMULATION");
        $display("==========================================================================================================");
        $display("Cyc | PC_IF | Inst_ID | ALU_EX | FwdA FwdB | Stall | WB_En Rd_WB Data_WB || R1  R2  R3  R4  R5  | RAM[4]");
        $display("----+-------+---------+--------+-----------+-------+---------------------++---------------------+-------");

        // Run simulation for 14 clock cycles (140ns)
        #140;

        $display("==========================================================================================================");
        $display(" AUTOMATED SELF-CHECK RESULTS AFTER EXECUTION:");
        $display("   - R1 (Expected = 5) : %0d", uut.u_rf.regs[1]);
        $display("   - R2 (Expected = 3) : %0d", uut.u_rf.regs[2]);
        $display("   - R3 (Expected = 8) : %0d", uut.u_rf.regs[3]);
        $display("   - R4 (Expected = 8) : %0d", uut.u_rf.regs[4]);
        $display("   - R5 (Expected = 5) : %0d", uut.u_rf.regs[5]);
        $display("   - RAM[4] (Expected = 8): %0d", uut.u_dmem.ram[4]);

        if (uut.u_rf.regs[1] == 8'd5 &&
            uut.u_rf.regs[2] == 8'd3 &&
            uut.u_rf.regs[3] == 8'd8 &&
            uut.u_rf.regs[4] == 8'd8 &&
            uut.u_rf.regs[5] == 8'd5 &&
            uut.u_dmem.ram[4] == 8'd8) begin
            $display(" >>> RESULT: PASS! 5-Stage Pipeline, Forwarding, and Load-Use Hazard operate 100%% CORRECTLY! <<<");
        end else begin
            $display(" >>> RESULT: FAIL! Data mismatch detected, please inspect the Waveform. <<<");
        end
        $display("==========================================================================================================");

        $finish;
    end

    // 5. Monitor and print Pipeline status on every falling clock edge
    // (Sampling at negedge clk ensures all pipeline registers have settled after posedge clk)
    always @(negedge clk) begin
        if (rst_n) begin
            cycle_count = cycle_count + 1;
            $display(" %2d |  0x%02h |  0x%04h |  0x%02h  |  %b   %b  |   %b   |   %b    R%0d    0x%02h   || %2d  %2d  %2d  %2d  %2d  |   %2d",
                     cycle_count,
                     debug_pc,
                     uut.inst_id,
                     debug_alu_ex,
                     uut.forward_a,
                     uut.forward_b,
                     uut.stall_if_id,
                     debug_wb_regwrite,
                     debug_wb_rd,
                     debug_wb_data,
                     uut.u_rf.regs[1],
                     uut.u_rf.regs[2],
                     uut.u_rf.regs[3],
                     uut.u_rf.regs[4],
                     uut.u_rf.regs[5],
                     uut.u_dmem.ram[4]);
        end
    end

endmodule