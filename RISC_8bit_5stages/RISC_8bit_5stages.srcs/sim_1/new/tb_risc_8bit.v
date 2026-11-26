`timescale 1ns / 1ps

module tb_risc_8bit;

    // ============================================================
    // 1. CLOCK AND RESET
    // ============================================================
    reg clk;
    reg rst_n;

    integer cycle_count;
    integer error_count;
    integer pass_count;

    // ============================================================
    // 2. CPU DEBUG SIGNALS
    // ============================================================
    wire [7:0] debug_pc;
    wire [7:0] debug_alu_ex;
    wire [7:0] debug_wb_data;
    wire [2:0] debug_wb_rd;
    wire       debug_wb_regwrite;

    // ============================================================
    // 3. P3 ADC / TIMER SIGNALS
    // ============================================================
    reg        adc_cmp;
    reg  [7:0] analog_vin;

    wire       adc_sample;
    wire [1:0] adc_ch;
    wire [7:0] adc_dac;
    wire       pwm_out;
    wire       irq;

    // ============================================================
    // 4. ACTIVITY COUNTERS AND CAPTURE ARRAYS
    // ============================================================
    reg pwm_high_seen;
    reg pwm_low_seen;
    reg irq_seen;
    reg adc_sample_seen;
    reg adc_sample_prev;

    integer p3_write_count;
    integer p3_read_count;
    integer adc_ctrl_write_count;
    integer adc_sample_pulse_count;
    integer rch_read_count;
    integer adc_data_read_count;
    integer adc_stat_read_count;

    reg [7:0] observed_adc_ctrl [0:3];
    reg [1:0] observed_sample_ch [0:3];
    reg [7:0] observed_rch [0:3];
    reg [7:0] observed_fifo_data [0:3];
    reg [7:0] observed_adc_stat [0:1];

    integer i;

    // ============================================================
    // 5. UUT: P2 CPU + P3 PERIPHERAL
    // ============================================================
    risc_8bit_pipeline_top uut (
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

    // ============================================================
    // 6. CLOCK GENERATOR: 10 ns PERIOD FOR SIMULATION
    // ============================================================
    initial begin
        clk = 1'b0;
        forever #5 clk = ~clk;
    end

    // ============================================================
    // 7. ANALOG INPUT MODEL
    // CH0=31, CH1=86, CH2=155, CH3=232
    // Comparator convention: CMP=1 when Vin >= DAC.
    // ============================================================
    always @(*) begin
        case (adc_ch)
            2'd0: analog_vin = 8'd31;
            2'd1: analog_vin = 8'd86;
            2'd2: analog_vin = 8'd155;
            2'd3: analog_vin = 8'd232;
            default: analog_vin = 8'd31;
        endcase
    end

    always @(*) begin
        adc_cmp = (analog_vin >= adc_dac);
    end

    // ============================================================
    // 8. RESET AND COUNTER INITIALIZATION
    // ============================================================
    initial begin
        rst_n                  = 1'b0;
        cycle_count            = 0;
        error_count            = 0;
        pass_count             = 0;

        pwm_high_seen          = 1'b0;
        pwm_low_seen           = 1'b0;
        irq_seen               = 1'b0;
        adc_sample_seen        = 1'b0;
        adc_sample_prev        = 1'b0;

        p3_write_count         = 0;
        p3_read_count          = 0;
        adc_ctrl_write_count   = 0;
        adc_sample_pulse_count = 0;
        rch_read_count         = 0;
        adc_data_read_count    = 0;
        adc_stat_read_count    = 0;

        for (i = 0; i < 4; i = i + 1) begin
            observed_adc_ctrl[i]  = 8'hXX;
            observed_sample_ch[i] = 2'bxx;
            observed_rch[i]       = 8'hXX;
            observed_fifo_data[i] = 8'hXX;
        end

        for (i = 0; i < 2; i = i + 1)
            observed_adc_stat[i] = 8'hXX;

        // Hold reset for three complete clock cycles.
        repeat (3) @(negedge clk);
        rst_n = 1'b1;

        $display("");
        $display("==============================================================");
        $display(" START P2 + P3 FOUR-CHANNEL ADC / FIFO INTEGRATION TEST");
        $display("==============================================================");
        $display("CPU simulation clock period = 10 ns");
        $display("P3 address region = 0xF0 - 0xFF");
        $display("ADC expected: CH0=1F CH1=56 CH2=9B CH3=E8");
        $display("==============================================================");
        $display("");

        // Program ends at instruction address 82.
        // Allow pipeline drain and sufficient time for Timer/PWM/IRQ.
        repeat (150) @(posedge clk);
        #1;

        // ========================================================
        // 9. FINAL RESULTS
        // ========================================================
        $display("");
        $display("==============================================================");
        $display(" P2 + P3 FOUR-CHANNEL INTEGRATION RESULTS");
        $display("==============================================================");

        $display("CPU REGISTER RESULTS:");
        $display("R1 = 0x%02h (Peripheral base, expected F0)", uut.u_rf.regs[1]);
        $display("R2 = 0x%02h (Timer count readback)", uut.u_rf.regs[2]);
        $display("R3 = 0x%02h (ADC CH0, expected 1F)", uut.u_rf.regs[3]);
        $display("R4 = 0x%02h (ADC CH1, expected 56)", uut.u_rf.regs[4]);
        $display("R5 = 0x%02h (ADC CH2, expected 9B)", uut.u_rf.regs[5]);
        $display("R6 = 0x%02h (ADC CH3, expected E8)", uut.u_rf.regs[6]);
        $display("R7 = 0x%02h (Peripheral ID, expected A8)", uut.u_rf.regs[7]);

        $display("");
        $display("ADC_CTRL WRITES:");
        for (i = 0; i < 4; i = i + 1)
            $display("  CTRL[%0d] = 0x%02h", i, observed_adc_ctrl[i]);

        $display("");
        $display("ADC SAMPLE CHANNELS:");
        for (i = 0; i < 4; i = i + 1)
            $display("  SAMPLE[%0d] channel = %0d", i, observed_sample_ch[i]);

        $display("");
        $display("FIFO READBACK:");
        for (i = 0; i < 4; i = i + 1)
            $display("  FIFO[%0d]: RCH=0x%02h DATA=0x%02h",
                     i, observed_rch[i], observed_fifo_data[i]);

        for (i = 0; i < 2; i = i + 1)
            $display("  ADC_STAT[%0d] = 0x%02h", i, observed_adc_stat[i]);

        $display("");
        $display("ACTIVITY COUNTS:");
        $display("P3 writes             = %0d", p3_write_count);
        $display("P3 reads              = %0d", p3_read_count);
        $display("ADC_CTRL writes       = %0d", adc_ctrl_write_count);
        $display("ADC sample pulses     = %0d", adc_sample_pulse_count);
        $display("ADC_RCH reads         = %0d", rch_read_count);
        $display("ADC_DATA reads        = %0d", adc_data_read_count);
        $display("ADC_STAT reads        = %0d", adc_stat_read_count);
        $display("PWM HIGH observed     = %b", pwm_high_seen);
        $display("PWM LOW observed      = %b", pwm_low_seen);
        $display("IRQ observed          = %b", irq_seen);

        // ========================================================
        // 10. SELF-CHECKING
        // ========================================================
        $display("");
        $display("SELF-CHECK:");

        // CPU register results
        if (uut.u_rf.regs[1] === 8'hF0) begin
            $display("[PASS] R1 peripheral base = F0");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] R1 expected F0, got %02h", uut.u_rf.regs[1]);
            error_count = error_count + 1;
        end

        if (uut.u_rf.regs[3] === 8'h1F) begin
            $display("[PASS] CPU read ADC CH0 = 1F");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] CPU ADC CH0 expected 1F, got %02h", uut.u_rf.regs[3]);
            error_count = error_count + 1;
        end

        if (uut.u_rf.regs[4] === 8'h56) begin
            $display("[PASS] CPU read ADC CH1 = 56");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] CPU ADC CH1 expected 56, got %02h", uut.u_rf.regs[4]);
            error_count = error_count + 1;
        end

        if (uut.u_rf.regs[5] === 8'h9B) begin
            $display("[PASS] CPU read ADC CH2 = 9B");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] CPU ADC CH2 expected 9B, got %02h", uut.u_rf.regs[5]);
            error_count = error_count + 1;
        end

        if (uut.u_rf.regs[6] === 8'hE8) begin
            $display("[PASS] CPU read ADC CH3 = E8");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] CPU ADC CH3 expected E8, got %02h", uut.u_rf.regs[6]);
            error_count = error_count + 1;
        end

        if (uut.u_rf.regs[7] === 8'hA8) begin
            $display("[PASS] Peripheral ID = A8");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Peripheral ID expected A8, got %02h", uut.u_rf.regs[7]);
            error_count = error_count + 1;
        end

        // Four ADC_CTRL writes with expected software-trigger values.
        if (adc_ctrl_write_count == 4) begin
            $display("[PASS] Four ADC_CTRL writes observed");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Expected 4 ADC_CTRL writes, got %0d", adc_ctrl_write_count);
            error_count = error_count + 1;
        end

        if (observed_adc_ctrl[0] === 8'h03) begin
            $display("[PASS] ADC_CTRL CH0 command = 03");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] ADC_CTRL CH0 expected 03, got %02h", observed_adc_ctrl[0]);
            error_count = error_count + 1;
        end

        if (observed_adc_ctrl[1] === 8'h13) begin
            $display("[PASS] ADC_CTRL CH1 command = 13");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] ADC_CTRL CH1 expected 13, got %02h", observed_adc_ctrl[1]);
            error_count = error_count + 1;
        end

        if (observed_adc_ctrl[2] === 8'h23) begin
            $display("[PASS] ADC_CTRL CH2 command = 23");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] ADC_CTRL CH2 expected 23, got %02h", observed_adc_ctrl[2]);
            error_count = error_count + 1;
        end

        if (observed_adc_ctrl[3] === 8'h33) begin
            $display("[PASS] ADC_CTRL CH3 command = 33");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] ADC_CTRL CH3 expected 33, got %02h", observed_adc_ctrl[3]);
            error_count = error_count + 1;
        end

        // Verify that four separate sample windows occurred on CH0..CH3.
        if (adc_sample_pulse_count == 4) begin
            $display("[PASS] Four ADC sample pulses observed");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Expected 4 ADC sample pulses, got %0d", adc_sample_pulse_count);
            error_count = error_count + 1;
        end

        if (observed_sample_ch[0] === 2'd0 &&
            observed_sample_ch[1] === 2'd1 &&
            observed_sample_ch[2] === 2'd2 &&
            observed_sample_ch[3] === 2'd3) begin
            $display("[PASS] ADC sampled channels in order CH0, CH1, CH2, CH3");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] ADC sample channel sequence incorrect");
            error_count = error_count + 1;
        end

        // Verify FIFO metadata (valid bit + channel number).
        if (rch_read_count == 4) begin
            $display("[PASS] Four ADC_RCH reads observed");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Expected 4 ADC_RCH reads, got %0d", rch_read_count);
            error_count = error_count + 1;
        end

        if (observed_rch[0] === 8'h80 &&
            observed_rch[1] === 8'h81 &&
            observed_rch[2] === 8'h82 &&
            observed_rch[3] === 8'h83) begin
            $display("[PASS] FIFO channel metadata order = CH0, CH1, CH2, CH3");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] FIFO channel metadata mismatch");
            error_count = error_count + 1;
        end

        // Verify FIFO ADC_DATA read order.
        if (adc_data_read_count == 4) begin
            $display("[PASS] Four ADC_DATA reads observed");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Expected 4 ADC_DATA reads, got %0d", adc_data_read_count);
            error_count = error_count + 1;
        end

        if (observed_fifo_data[0] === 8'h1F &&
            observed_fifo_data[1] === 8'h56 &&
            observed_fifo_data[2] === 8'h9B &&
            observed_fifo_data[3] === 8'hE8) begin
            $display("[PASS] FIFO data order = 1F, 56, 9B, E8");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] FIFO data order mismatch");
            error_count = error_count + 1;
        end

        // Verify FIFO level before and after four pops.
        if (adc_stat_read_count == 2) begin
            $display("[PASS] Two ADC_STAT reads observed");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Expected 2 ADC_STAT reads, got %0d", adc_stat_read_count);
            error_count = error_count + 1;
        end

        if (observed_adc_stat[0] === 8'h04) begin
            $display("[PASS] FIFO status before reads: level=4, not empty");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Expected initial ADC_STAT 04, got %02h", observed_adc_stat[0]);
            error_count = error_count + 1;
        end

        if (observed_adc_stat[1] === 8'h10) begin
            $display("[PASS] FIFO status after reads: level=0, empty=1");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Expected final ADC_STAT 10, got %02h", observed_adc_stat[1]);
            error_count = error_count + 1;
        end

        // Verify peripheral bus activity and timer-related outputs.
        if (p3_write_count >= 9) begin
            $display("[PASS] P3 write transactions observed (%0d)", p3_write_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Expected at least 9 P3 writes, got %0d", p3_write_count);
            error_count = error_count + 1;
        end

        if (p3_read_count >= 12) begin
            $display("[PASS] P3 read transactions observed (%0d)", p3_read_count);
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Expected at least 12 P3 reads, got %0d", p3_read_count);
            error_count = error_count + 1;
        end

        if (pwm_high_seen && pwm_low_seen) begin
            $display("[PASS] PWM HIGH and LOW phases observed");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] PWM phases not fully observed");
            error_count = error_count + 1;
        end

        if (irq_seen) begin
            $display("[PASS] Peripheral IRQ observed");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Peripheral IRQ was not observed");
            error_count = error_count + 1;
        end

        // Timer count is expected to match the previous integration
        // timing scenario, whose readback was 0x04.
        if (uut.u_rf.regs[2] === 8'h04) begin
            $display("[PASS] Timer count readback = 04");
            pass_count = pass_count + 1;
        end else begin
            $display("[FAIL] Timer count expected 04, got %02h", uut.u_rf.regs[2]);
            error_count = error_count + 1;
        end

        // ========================================================
        // 11. FINAL STATUS
        // ========================================================
        $display("");
        $display("==============================================================");
        $display(" CHECKS PASSED = %0d", pass_count);
        $display(" CHECKS FAILED = %0d", error_count);

        if (error_count == 0) begin
            $display(" P2 + P3 FOUR-CHANNEL ADC / FIFO TEST: PASS");
            $display(" All extended integration checks passed.");
        end else begin
            $display(" P2 + P3 FOUR-CHANNEL ADC / FIFO TEST: FAIL");
            $display(" Total failed checks = %0d", error_count);
        end

        $display("==============================================================");
        $display("");
        $finish;
    end

    // ============================================================
    // 12. MONITOR CPU / P3 TRANSACTIONS AND ADC SAMPLE WINDOWS
    // ============================================================
    always @(negedge clk) begin
        if (rst_n)
            cycle_count = cycle_count + 1;
    end

    always @(posedge clk) begin
        if (rst_n) begin
            // Observe PWM and IRQ outputs.
            if (pwm_out === 1'b1)
                pwm_high_seen = 1'b1;

            if (pwm_out === 1'b0)
                pwm_low_seen = 1'b1;

            if (irq === 1'b1)
                irq_seen = 1'b1;

            // Detect each rising edge of adc_sample and record selected channel.
            if (adc_sample === 1'b1) begin
                adc_sample_seen = 1'b1;

                if (adc_sample_prev === 1'b0) begin
                    if (adc_sample_pulse_count < 4)
                        observed_sample_ch[adc_sample_pulse_count] = adc_ch;

                    adc_sample_pulse_count = adc_sample_pulse_count + 1;
                end
            end

            adc_sample_prev = adc_sample;

            // Observe CPU accesses to the P3 memory-mapped region.
            if (uut.p3_cs === 1'b1) begin
                if (uut.p3_we === 1'b1) begin
                    p3_write_count = p3_write_count + 1;

                    $display("[CPU_P3_WRITE] t=%0t ADDR=%02h REG=%h DATA=%02h",
                             $time,
                             uut.alu_result_mem,
                             uut.alu_result_mem[3:0],
                             uut.write_data_mem);

                    // Capture ADC_CTRL writes only.
                    if (uut.alu_result_mem[3:0] == 4'h5) begin
                        if (adc_ctrl_write_count < 4)
                            observed_adc_ctrl[adc_ctrl_write_count] = uut.write_data_mem;

                        adc_ctrl_write_count = adc_ctrl_write_count + 1;
                    end
                end else begin
                    p3_read_count = p3_read_count + 1;

                    $display("[CPU_P3_READ] t=%0t ADDR=%02h REG=%h DATA=%02h",
                             $time,
                             uut.alu_result_mem,
                             uut.alu_result_mem[3:0],
                             uut.mem_read_data_mem);

                    case (uut.alu_result_mem[3:0])
                        4'hA: begin
                            if (adc_data_read_count < 4)
                                observed_fifo_data[adc_data_read_count] = uut.mem_read_data_mem;

                            adc_data_read_count = adc_data_read_count + 1;
                        end

                        4'hB: begin
                            if (rch_read_count < 4)
                                observed_rch[rch_read_count] = uut.mem_read_data_mem;

                            rch_read_count = rch_read_count + 1;
                        end

                        4'hC: begin
                            if (adc_stat_read_count < 2)
                                observed_adc_stat[adc_stat_read_count] = uut.mem_read_data_mem;

                            adc_stat_read_count = adc_stat_read_count + 1;
                        end

                        default: ;
                    endcase
                end
            end
        end
    end

endmodule