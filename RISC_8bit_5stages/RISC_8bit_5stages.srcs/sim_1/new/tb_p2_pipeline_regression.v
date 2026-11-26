`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 10:28:15 PM
// Design Name: 
// Module Name: tb_p2_pipeline_regression
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

module tb_p2_pipeline_regression;

    reg clk;
    reg rst_n;

    reg adc_cmp;

    wire adc_sample;
    wire [1:0] adc_ch;
    wire [7:0] adc_dac;
    wire pwm_out;
    wire irq;

    wire [7:0] debug_pc;
    wire [7:0] debug_alu_ex;
    wire [7:0] debug_wb_data;
    wire [2:0] debug_wb_rd;
    wire debug_wb_regwrite;

    integer i;
    integer error_count;

    //================================================
    // DUT
    //================================================

    risc_8bit_pipeline_top dut (
        .clk               (clk),
        .rst_n             (rst_n),

        .debug_pc          (debug_pc),
        .debug_alu_ex      (debug_alu_ex),
        .debug_wb_data     (debug_wb_data),
        .debug_wb_rd       (debug_wb_rd),
        .debug_wb_regwrite (debug_wb_regwrite),

        .adc_cmp           (adc_cmp),
        .adc_sample        (adc_sample),
        .adc_ch            (adc_ch),
        .adc_dac           (adc_dac),

        .pwm_out           (pwm_out),
        .irq               (irq)
    );

    //================================================
    // CLOCK
    //================================================

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    //================================================
    // INITIALIZATION AND P2 TEST PROGRAM
    //================================================

    initial begin

        rst_n = 0;
        adc_cmp = 0;
        error_count = 0;

        // Wait for ROM initialization
        #1;

        // Overwrite ROM for simulation only.
        // P2 original pipeline regression program.

        for (i = 0; i < 256; i = i + 1)
            dut.u_imem.rom[i] = 16'h0000;

        // 0: ADDI R1, R0, 5
        dut.u_imem.rom[0] =
            16'b0010_001_000_000101;

        // 1: ADDI R2, R0, 3
        dut.u_imem.rom[1] =
            16'b0010_010_000_000011;

        // 2: ADD R3, R1, R2
        dut.u_imem.rom[2] =
            16'b0001_011_001_010_000;

        // 3: SW R3, 4(R0)
        dut.u_imem.rom[3] =
            16'b0100_011_000_000100;

        // 4: LW R4, 4(R0)
        dut.u_imem.rom[4] =
            16'b0011_100_000_000100;

        // 5: SUB R5, R4, R2
        dut.u_imem.rom[5] =
            16'b0001_101_100_010_001;

        //================================================
        // RESET
        //================================================

        repeat (3) @(negedge clk);
        rst_n = 1;

        // Allow pipeline to finish
        repeat (25) @(posedge clk);

        #1;

        //================================================
        // DISPLAY RESULTS
        //================================================

        $display("");
        $display("==============================================");
        $display(" P2 PIPELINE REGRESSION RESULTS");
        $display("==============================================");

        $display("R1    = 0x%02h (Expected 05)",
                 dut.u_rf.regs[1]);

        $display("R2    = 0x%02h (Expected 03)",
                 dut.u_rf.regs[2]);

        $display("R3    = 0x%02h (Expected 08)",
                 dut.u_rf.regs[3]);

        $display("R4    = 0x%02h (Expected 08)",
                 dut.u_rf.regs[4]);

        $display("R5    = 0x%02h (Expected 05)",
                 dut.u_rf.regs[5]);

        $display("RAM[4] = 0x%02h (Expected 08)",
                 dut.u_dmem.ram[4]);

        //================================================
        // SELF CHECK
        //================================================

        if (dut.u_rf.regs[1] !== 8'd5) begin
            $display("[FAIL] ADDI R1");
            error_count = error_count + 1;
        end
        else
            $display("[PASS] ADDI R1");

        if (dut.u_rf.regs[2] !== 8'd3) begin
            $display("[FAIL] ADDI R2");
            error_count = error_count + 1;
        end
        else
            $display("[PASS] ADDI R2");

        if (dut.u_rf.regs[3] !== 8'd8) begin
            $display("[FAIL] ADD R3 / Forwarding");
            error_count = error_count + 1;
        end
        else
            $display("[PASS] ADD R3 / Forwarding");

        if (dut.u_rf.regs[4] !== 8'd8) begin
            $display("[FAIL] LW R4");
            error_count = error_count + 1;
        end
        else
            $display("[PASS] LW R4");

        if (dut.u_rf.regs[5] !== 8'd5) begin
            $display("[FAIL] SUB R5 / Load-use hazard");
            error_count = error_count + 1;
        end
        else
            $display("[PASS] SUB R5 / Load-use hazard");

        if (dut.u_dmem.ram[4] !== 8'd8) begin
            $display("[FAIL] SW RAM[4]");
            error_count = error_count + 1;
        end
        else
            $display("[PASS] SW RAM[4]");

        //================================================
        // FINAL STATUS
        //================================================

        $display("----------------------------------------------");

        if (error_count == 0)
            $display(" P2 PIPELINE REGRESSION: PASS");
        else begin
            $display(" P2 PIPELINE REGRESSION: FAIL");
            $display(" Failed checks = %0d", error_count);
        end

        $display("==============================================");

        $finish;

    end

endmodule

