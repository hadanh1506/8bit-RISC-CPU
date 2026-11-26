`timescale 1ns / 1ps

module tb_top;

    import uvm_pkg::*;
    import periph_pkg::*;
    import periph_test_pkg::*;

    //================================================
    // 1. CLOCK
    //================================================
    logic clk = 0;

    always #5 clk = ~clk;


    //================================================
    // 2. INTERFACE
    //================================================
    periph_if bus_if(clk);


    //================================================
    // 3. ADC ANALOG MODEL
    //================================================
    logic [7:0] analog_vin;

    always_comb begin
        case (bus_if.adc_ch)

            2'd0: analog_vin = 8'd31;
            2'd1: analog_vin = 8'd86;
            2'd2: analog_vin = 8'd155;
            2'd3: analog_vin = 8'd232;

            default: analog_vin = 8'd31;

        endcase
    end

    // Comparator: CMP = 1 when Vin >= DAC
    always_comb begin
        bus_if.adc_cmp = (analog_vin >= bus_if.adc_dac);
    end


    //================================================
    // 4. DUT
    //================================================
    timer_adc8_cpu_if dut (
        .clk        (clk),
        .rst_n      (bus_if.rst_n),

        .cs         (bus_if.cs),
        .we         (bus_if.we),
        .addr       (bus_if.addr),
        .wdata      (bus_if.wdata),
        .rdata      (bus_if.rdata),

        .irq        (bus_if.irq),

        .adc_sample (bus_if.adc_sample),
        .adc_ch     (bus_if.adc_ch),
        .adc_dac    (bus_if.adc_dac),
        .adc_cmp    (bus_if.adc_cmp),

        .pwm_out    (bus_if.pwm_out)
    );


    //================================================
    // 5. RESET
    //================================================
    initial begin

        bus_if.rst_n = 0;

        repeat (5) @(posedge clk);

        bus_if.rst_n = 1;

    end


    //================================================
    // 6. SAR DEBUG - DAC CHANGES
    //================================================
    // Trigger whenever ADC DAC output changes.
    // #1ps allows comparator model to settle.

    always @(bus_if.adc_dac) begin

        #1ps;

        if (bus_if.rst_n === 1'b1) begin

            $display(
                "[SAR_TRACE] t=%0t CH=%0d BIT=%0d DAC=%02h VIN=%02h CMP=%b DEC=%02h",

                $time,

                bus_if.adc_ch,

                dut.u_timer_adc.u_adc.bit_index,

                bus_if.adc_dac,

                analog_vin,

                bus_if.adc_cmp,

                dut.u_timer_adc.u_adc.sar_decision
            );

        end

    end


    //================================================
    // 7. SAR RESULT DEBUG
    //================================================
    always @(posedge clk) begin

        if (bus_if.rst_n === 1'b1) begin

            if (dut.u_timer_adc.adc_result_valid === 1'b1) begin

                $display(
                    "[SAR_RESULT] t=%0t CH=%0d DATA=%02h",

                    $time,

                    dut.u_timer_adc.adc_result_ch,

                    dut.u_timer_adc.adc_result_data
                );

            end

        end

    end


    //================================================
    // 8. UVM CONFIGURATION AND TEST
    //================================================
    initial begin

        uvm_config_db#(virtual periph_if)::set(
            null,
            "*",
            "vif",
            bus_if
        );

        run_test("periph_test");

    end

endmodule