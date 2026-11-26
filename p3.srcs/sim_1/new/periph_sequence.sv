`timescale 1ns / 1ps

package periph_sequence_pkg;

    import uvm_pkg::*;
    import periph_txn_pkg::*;

    `include "uvm_macros.svh"

    // One-run directed regression for the standalone P3 peripheral.
    // Address is the low nibble of the peripheral register page F0-FF.
    class periph_sequence extends uvm_sequence #(periph_txn);

        `uvm_object_utils(periph_sequence)

        virtual periph_if vif;

        int unsigned checks_passed;
        int unsigned checks_failed;

        function new(string name = "periph_sequence");
            super.new(name);
            checks_passed = 0;
            checks_failed = 0;
        endfunction

        task automatic write_reg(input logic [3:0] address,
                                 input logic [7:0] data);
            periph_txn req;
            req = periph_txn::type_id::create($sformatf("wr_%0h", address));
            start_item(req);
            req.op    = periph_txn::WRITE;
            req.addr  = address;
            req.wdata = data;
            req.rdata = '0;
            finish_item(req);
        endtask

        task automatic read_reg(input logic [3:0] address,
                                output logic [7:0] data);
            periph_txn req;
            req = periph_txn::type_id::create($sformatf("rd_%0h", address));
            start_item(req);
            req.op    = periph_txn::READ;
            req.addr  = address;
            req.wdata = '0;
            req.rdata = '0;
            finish_item(req);
            // The driver writes req.rdata before item_done().
            data = req.rdata;
        endtask

        task automatic wait_clks(input int unsigned count);
            repeat (count) @(posedge vif.clk);
        endtask

        task automatic check8(input string group_name,
                              input string check_name,
                              input logic [7:0] actual,
                              input logic [7:0] expected);
            if (actual !== expected) begin
                checks_failed++;
                `uvm_error("P3_CHECK",
                    $sformatf("[%s] %s: expected=0x%02h actual=0x%02h",
                              group_name, check_name, expected, actual))
            end
            else begin
                checks_passed++;
                `uvm_info("P3_CHECK",
                    $sformatf("[%s] PASS: %s = 0x%02h",
                              group_name, check_name, actual), UVM_LOW)
            end
        endtask

        task automatic check_mask(input string group_name,
                                  input string check_name,
                                  input logic [7:0] actual,
                                  input logic [7:0] mask,
                                  input logic [7:0] expected_masked);
            logic [7:0] actual_masked;
            actual_masked = actual & mask;
            if (actual_masked !== expected_masked) begin
                checks_failed++;
                `uvm_error("P3_CHECK",
                    $sformatf("[%s] %s: mask=0x%02h expected=0x%02h actual=0x%02h",
                              group_name, check_name, mask,
                              expected_masked, actual_masked))
            end
            else begin
                checks_passed++;
                `uvm_info("P3_CHECK",
                    $sformatf("[%s] PASS: %s masked value=0x%02h",
                              group_name, check_name, actual_masked), UVM_LOW)
            end
        endtask

        task automatic check_condition(input string group_name,
                                       input string check_name,
                                       input bit condition);
            if (!condition) begin
                checks_failed++;
                `uvm_error("P3_CHECK",
                    $sformatf("[%s] FAIL: %s", group_name, check_name))
            end
            else begin
                checks_passed++;
                `uvm_info("P3_CHECK",
                    $sformatf("[%s] PASS: %s", group_name, check_name), UVM_LOW)
            end
        endtask

        task automatic sample_pwm(input int unsigned samples,
                                  output int unsigned high_samples,
                                  output int unsigned low_samples);
            high_samples = 0;
            low_samples  = 0;
            repeat (samples) begin
                @(posedge vif.clk);
                #1ps; // Sample after nonblocking timer updates.
                if (vif.pwm_out === 1'b1)
                    high_samples++;
                else if (vif.pwm_out === 1'b0)
                    low_samples++;
            end
        endtask

        task body();
            logic [7:0] data;
            logic [7:0] status;
            logic [7:0] rch;
            int unsigned pwm_high;
            int unsigned pwm_low;
            int i;

            // tb_top sets this same virtual interface for all UVM components.
            if (!uvm_config_db#(virtual periph_if)::get(
                    m_sequencer, "", "vif", vif)) begin
                `uvm_fatal("SEQ_VIF", "periph_sequence cannot get virtual periph_if")
            end

            wait (vif.rst_n === 1'b1);
            wait_clks(2);

            `uvm_info("P3_REGRESSION", "START: standalone P3 regression", UVM_LOW)

            // -------------------------------------------------------------
            // TEST 1: Register read/write, read-only behavior, and ID.
            // -------------------------------------------------------------
            `uvm_info("P3_REGRESSION", "TEST 1: Register access", UVM_LOW)

            write_reg(4'h0, 8'h00); // TMR_CTRL disabled
            write_reg(4'h1, 8'h03); // TMR_PRESC
            write_reg(4'h2, 8'h0F); // TMR_LOAD
            write_reg(4'h3, 8'h03); // TMR_CMP
            write_reg(4'h5, 8'h11); // ADC_EN + channel 1, no START pulse
            write_reg(4'h6, 8'h00); // ADC_SMP
            write_reg(4'h7, 8'h00); // ADC_DIV
            write_reg(4'h8, 8'h00); // ADC_THR_LO
            write_reg(4'h9, 8'hFF); // ADC_THR_HI
            write_reg(4'hD, 8'h00); // IRQ_EN

            read_reg(4'h0, data); check8("REG", "TMR_CTRL", data, 8'h00);
            read_reg(4'h1, data); check8("REG", "TMR_PRESC", data, 8'h03);
            read_reg(4'h2, data); check8("REG", "TMR_LOAD", data, 8'h0F);
            read_reg(4'h3, data); check8("REG", "TMR_CMP", data, 8'h03);
            read_reg(4'h5, data); check8("REG", "ADC_CTRL readback", data, 8'h11);
            read_reg(4'h6, data); check8("REG", "ADC_SMP", data, 8'h00);
            read_reg(4'h7, data); check8("REG", "ADC_DIV", data, 8'h00);
            read_reg(4'h8, data); check8("REG", "ADC_THR_LO", data, 8'h00);
            read_reg(4'h9, data); check8("REG", "ADC_THR_HI", data, 8'hFF);
            read_reg(4'hD, data); check8("REG", "IRQ_EN", data, 8'h00);

            // TMR_CNT is RO and should remain at reset value while timer is disabled.
            write_reg(4'h4, 8'hAA);
            read_reg(4'h4, data);
            check8("REG", "write to RO TMR_CNT ignored", data, 8'h00);

            // ID is RO and must always return 0xA8.
            write_reg(4'hF, 8'h00);
            read_reg(4'hF, data);
            check8("REG", "PERIPH_ID", data, 8'hA8);

            // -------------------------------------------------------------
            // TEST 2: Timer overflow, compare flag, and PWM activity.
            // -------------------------------------------------------------
            `uvm_info("P3_REGRESSION", "TEST 2: Timer / Compare / PWM", UVM_LOW)

            write_reg(4'hE, 8'h1F); // Clear pending IRQ flags (W1C)
            write_reg(4'h1, 8'h00); // Prescaler: one timer step per clock
            write_reg(4'h2, 8'h03); // Counter sequence 0..3
            write_reg(4'h3, 8'h01); // PWM high while count < 1
            write_reg(4'hD, 8'h03); // Enable OVF and CMP IRQ outputs
            write_reg(4'h0, 8'h01); // Timer enable

            sample_pwm(16, pwm_high, pwm_low);
            check_condition("TIMER", "PWM has both HIGH and LOW phases",
                            (pwm_high > 0) && (pwm_low > 0));

            read_reg(4'h4, data);
            check_condition("TIMER", "TMR_CNT remains within 0..LOAD",
                            (data <= 8'h03));

            read_reg(4'hE, status);
            check_mask("TIMER", "Overflow and compare flags",
                       status, 8'h03, 8'h03);
            check_condition("TIMER", "IRQ pin asserted for enabled timer events",
                            (vif.irq === 1'b1));

            write_reg(4'h0, 8'h00); // Stop timer
            write_reg(4'hE, 8'h03); // Clear OVF/CMP
            read_reg(4'hE, status);
            check_mask("TIMER", "W1C clears OVF/CMP", status, 8'h03, 8'h00);

            // -------------------------------------------------------------
            // TEST 3: Software-triggered SAR ADC, channel 1 = 86 (0x56).
            // -------------------------------------------------------------
            `uvm_info("P3_REGRESSION", "TEST 3: SAR ADC software conversion", UVM_LOW)

            write_reg(4'h6, 8'h00); // SMP=0
            write_reg(4'h7, 8'h00); // DIV=0
            write_reg(4'h8, 8'h00); // THR_LO=0
            write_reg(4'h9, 8'hFF); // THR_HI=255
            write_reg(4'hD, 8'h04); // Enable ADC EOC interrupt
            write_reg(4'hE, 8'h1F); // Clear IRQ flags
            write_reg(4'h5, 8'h13); // EN=1, START=1, SW trigger, CH=1

            // With SMP=0 and DIV=0, allow more than the 8 SAR decisions.
            wait_clks(16);

            read_reg(4'hC, status); // ADC_STAT
            check_mask("ADC", "Conversion no longer busy", status, 8'h40, 8'h00);
            check_mask("ADC", "One result available", status, 8'h1F, 8'h01);

            read_reg(4'hB, rch); // ADC_RCH does not pop
            check8("ADC", "ADC_RCH valid/channel 1", rch, 8'h81);

            read_reg(4'hA, data); // ADC_DATA pops oldest result
            check8("ADC", "SAR result for channel 1", data, 8'h56);

            read_reg(4'hC, status);
            check_mask("ADC", "FIFO empty after one pop", status, 8'h10, 8'h10);

            read_reg(4'hE, status);
            check_mask("IRQ", "ADC EOC flag", status, 8'h04, 8'h04);
            check_condition("IRQ", "IRQ pin asserted for enabled ADC EOC",
                            (vif.irq === 1'b1));
            write_reg(4'hE, 8'h04); // W1C EOC
            read_reg(4'hE, status);
            check_mask("IRQ", "W1C clears ADC EOC", status, 8'h04, 8'h00);
            check_condition("IRQ", "IRQ pin deasserted after W1C",
                            (vif.irq === 1'b0));

            // -------------------------------------------------------------
            // TEST 4: Watchdog threshold and IRQ.
            // Channel 3 analog model is 232 (0xE8), above THR_HI=100.
            // -------------------------------------------------------------
            `uvm_info("P3_REGRESSION", "TEST 4: ADC watchdog / IRQ", UVM_LOW)

            write_reg(4'h8, 8'h00);
            write_reg(4'h9, 8'd100);
            write_reg(4'hD, 8'h0C); // Enable WD and EOC IRQ
            write_reg(4'hE, 8'h1F);
            write_reg(4'h5, 8'h33); // EN=1, START=1, SW trigger, CH=3
            wait_clks(16);

            read_reg(4'hB, rch);
            check8("ADC", "ADC_RCH valid/channel 3", rch, 8'h83);
            read_reg(4'hA, data);
            check8("ADC", "SAR result for channel 3", data, 8'hE8);

            read_reg(4'hE, status);
            check_mask("IRQ", "EOC and watchdog flags", status, 8'h0C, 8'h0C);
            check_condition("IRQ", "IRQ pin asserted for watchdog event",
                            (vif.irq === 1'b1));
            write_reg(4'hE, 8'h0C);
            read_reg(4'hE, status);
            check_mask("IRQ", "W1C clears EOC and watchdog", status, 8'h0C, 8'h00);

            // -------------------------------------------------------------
            // TEST 5: FIFO capacity, full behavior, ordering, and draining.
            // Channel 1 returns 0x56 for every conversion.
            // -------------------------------------------------------------
            `uvm_info("P3_REGRESSION", "TEST 5: FIFO fill / full / pop", UVM_LOW)

            write_reg(4'h9, 8'hFF); // Disable watchdog window for channel 1
            write_reg(4'hD, 8'h04); // EOC enable
            write_reg(4'hE, 8'h1F);

            for (i = 0; i < 8; i++) begin
                write_reg(4'h5, 8'h13); // Start one channel-1 conversion
                wait_clks(12);
            end

            read_reg(4'hC, status);
            check_mask("FIFO", "FIFO level is eight", status, 8'h0F, 8'h08);
            check_mask("FIFO", "FIFO Full flag", status, 8'h20, 8'h20);

            // Attempt a ninth conversion while full. A full FIFO must not
            // overwrite the eight older results.
            write_reg(4'h5, 8'h13);
            wait_clks(12);
            read_reg(4'hC, status);
            check_mask("FIFO", "FIFO remains full after extra result", status,
                       8'h2F, 8'h28);

            read_reg(4'hB, rch);
            check8("FIFO", "Oldest queued channel", rch, 8'h81);

            for (i = 0; i < 8; i++) begin
                read_reg(4'hA, data);
                check8("FIFO", $sformatf("FIFO data item %0d", i), data, 8'h56);
            end

            read_reg(4'hC, status);
            check_mask("FIFO", "FIFO empty after draining eight entries",
                       status, 8'h1F, 8'h10);

            // -------------------------------------------------------------
            // TEST 6: Timer-overflow-triggered ADC conversion (integration).
            // TRIG_SEL=01, channel 2; channel-2 analog sample is 155 (0x9B).
            // -------------------------------------------------------------
            `uvm_info("P3_REGRESSION", "TEST 6: Timer-triggered ADC integration", UVM_LOW)

            write_reg(4'h0, 8'h00); // Ensure timer stopped before reconfiguring
            write_reg(4'hE, 8'h1F);
            write_reg(4'h1, 8'h00); // Prescaler=0
            write_reg(4'h2, 8'd19); // Overflow every 20 timer clocks
            write_reg(4'h3, 8'd5);
            write_reg(4'hD, 8'h04); // EOC IRQ enabled
            write_reg(4'h5, 8'h25); // EN=1, timer-overflow trigger, CH=2
            write_reg(4'h0, 8'h01); // Start timer

            wait_clks(80);

            read_reg(4'hC, status);
            check_condition("INTEGRATION", "Timer trigger produced an ADC result",
                            (status[4] === 1'b0) && (status[3:0] >= 1));

            read_reg(4'hB, rch);
            check8("INTEGRATION", "Timer-triggered ADC channel", rch, 8'h82);
            read_reg(4'hA, data);
            check8("INTEGRATION", "Timer-triggered ADC result", data, 8'h9B);

            write_reg(4'h0, 8'h00); // Stop timer
            write_reg(4'h5, 8'h00); // Disable ADC
            write_reg(4'hD, 8'h00); // Disable IRQ outputs
            write_reg(4'hE, 8'h1F); // Clear any remaining flags

            `uvm_info("P3_REGRESSION",
                $sformatf("P3 REGRESSION FINISHED: checks_passed=%0d checks_failed=%0d",
                          checks_passed, checks_failed), UVM_LOW)

            if (checks_failed == 0)
                `uvm_info("P3_RESULT", "*** P3 STANDALONE REGRESSION: PASS ***", UVM_LOW)
            else
                `uvm_error("P3_RESULT", "*** P3 STANDALONE REGRESSION: FAIL ***")

        endtask

    endclass

endpackage
