`timescale 1ns / 1ps

module inst_mem (
    input  wire [7:0]  addr,
    output wire [15:0] inst
);

    reg [15:0] rom [0:255];
    integer i;

    initial begin
        // ========================================================
        // INITIALIZE ROM: DEFAULT NOP
        // ========================================================
        for (i = 0; i < 256; i = i + 1)
            rom[i] = 16'h0000;

        // ========================================================
        // PROGRAM: P2 CPU + P3 FOUR-CHANNEL ADC + FIFO + TIMER
        //
        // Address mapping:
        //   0x00 - 0xEF : P2 Data RAM
        //   0xF0 - 0xFF : P3 Peripheral
        //
        // P3 register map:
        //   F0 TMR_CTRL   F1 TMR_PRESC  F2 TMR_LOAD  F3 TMR_CMP
        //   F4 TMR_CNT    F5 ADC_CTRL   FA ADC_DATA  FB ADC_RCH
        //   FC ADC_STAT   FD IRQ_EN     FF PERIPH_ID
        // ========================================================

        // --------------------------------------------------------
        // PART 1: SET PERIPHERAL BASE ADDRESS
        // --------------------------------------------------------
        // 0: ADDI R1, R0, -16  -> R1 = 0xF0
        rom[0] = 16'b0010_001_000_110000;

        // --------------------------------------------------------
        // PART 2: SOFTWARE-TRIGGER ADC CONVERSIONS, CH0 TO CH3
        // ADC_CTRL format: {reserved[1:0], CH[1:0], TRIG_SEL[1:0],
        //                   START, EN}
        // Software trigger: TRIG_SEL = 00; EN = 1; START = 1.
        // --------------------------------------------------------

        // CH0: ADC_CTRL = 0x03
        // 1: ADDI R2, R0, 3
        rom[1] = 16'b0010_010_000_000011;

        // 2: SW R2, 5(R1) -> P3 address 0xF5
        rom[2] = 16'b0100_010_001_000101;

        // Wait for CH0 conversion and FIFO write (SMP=0, DIV=0).
        for (i = 3; i <= 14; i = i + 1)
            rom[i] = 16'h0000;

        // CH1: ADC_CTRL = 0x13
        // 15: ADDI R2, R0, 19
        rom[15] = 16'b0010_010_000_010011;

        // 16: SW R2, 5(R1)
        rom[16] = 16'b0100_010_001_000101;

        for (i = 17; i <= 28; i = i + 1)
            rom[i] = 16'h0000;

        // CH2: ADC_CTRL = 0x23.
        // Signed 6-bit ADDI cannot load +35 directly.
        // 29: ADDI R3, R0, 16
        rom[29] = 16'b0010_011_000_010000;

        // 30: ADD R2, R2, R3 -> 19 + 16 = 35 (0x23)
        rom[30] = 16'b0001_010_010_011_000;

        // 31: SW R2, 5(R1)
        rom[31] = 16'b0100_010_001_000101;

        for (i = 32; i <= 43; i = i + 1)
            rom[i] = 16'h0000;

        // CH3: ADC_CTRL = 0x33.
        // 44: ADD R2, R2, R3 -> 35 + 16 = 51 (0x33)
        rom[44] = 16'b0001_010_010_011_000;

        // 45: SW R2, 5(R1)
        rom[45] = 16'b0100_010_001_000101;

        for (i = 46; i <= 57; i = i + 1)
            rom[i] = 16'h0000;

        // --------------------------------------------------------
        // PART 3: CHECK FIFO LEVEL BEFORE READING
        // --------------------------------------------------------
        // 58: LW R7, 12(R1) -> ADC_STAT, expected 0x04:
        //     level=4, empty=0, full=0, busy=0.
        rom[58] = 16'b0011_111_001_001100;

        // --------------------------------------------------------
        // PART 4: READ FIFO IN ORDER: CH0, CH1, CH2, CH3
        // Read ADC_RCH first (peek; no pop), then ADC_DATA (pop).
        // --------------------------------------------------------

        // 59: LW R7, 11(R1) -> ADC_RCH for CH0
        rom[59] = 16'b0011_111_001_001011;

        // 60: LW R3, 10(R1) -> ADC_DATA for CH0, expected 0x1F
        rom[60] = 16'b0011_011_001_001010;

        // 61: LW R7, 11(R1) -> ADC_RCH for CH1
        rom[61] = 16'b0011_111_001_001011;

        // 62: LW R4, 10(R1) -> ADC_DATA for CH1, expected 0x56
        rom[62] = 16'b0011_100_001_001010;

        // 63: LW R7, 11(R1) -> ADC_RCH for CH2
        rom[63] = 16'b0011_111_001_001011;

        // 64: LW R5, 10(R1) -> ADC_DATA for CH2, expected 0x9B
        rom[64] = 16'b0011_101_001_001010;

        // 65: LW R7, 11(R1) -> ADC_RCH for CH3
        rom[65] = 16'b0011_111_001_001011;

        // 66: LW R6, 10(R1) -> ADC_DATA for CH3, expected 0xE8
        rom[66] = 16'b0011_110_001_001010;

        // 67: LW R7, 12(R1) -> ADC_STAT, expected 0x10:
        //     level=0, empty=1, full=0, busy=0.
        rom[67] = 16'b0011_111_001_001100;

        // 68: LW R7, 15(R1) -> Peripheral ID, expected 0xA8
        rom[68] = 16'b0011_111_001_001111;

        // --------------------------------------------------------
        // PART 5: TIMER + IRQ + PWM TEST
        // --------------------------------------------------------

        // 69: ADDI R2, R0, 3 -> enable Timer overflow/compare IRQ
        rom[69] = 16'b0010_010_000_000011;

        // 70: SW R2, 13(R1) -> IRQ_EN = 0x03
        rom[70] = 16'b0100_010_001_001101;

        // 71: SW R0, 1(R1) -> TMR_PRESC = 0
        rom[71] = 16'b0100_000_001_000001;

        // 72: ADDI R2, R0, 15 -> TMR_LOAD = 0x0F
        rom[72] = 16'b0010_010_000_001111;

        // 73: SW R2, 2(R1)
        rom[73] = 16'b0100_010_001_000010;

        // 74: ADDI R2, R0, 3 -> TMR_CMP = 0x03
        rom[74] = 16'b0010_010_000_000011;

        // 75: SW R2, 3(R1)
        rom[75] = 16'b0100_010_001_000011;

        // 76: ADDI R2, R0, 1 -> Timer enable
        rom[76] = 16'b0010_010_000_000001;

        // 77: SW R2, 0(R1) -> TMR_CTRL = 0x01
        rom[77] = 16'b0100_010_001_000000;

        // 78-81: allow Timer to count and generate events
        for (i = 78; i <= 81; i = i + 1)
            rom[i] = 16'h0000;

        // 82: LW R2, 4(R1) -> TMR_CNT readback
        rom[82] = 16'b0011_010_001_000100;

        // All remaining ROM locations remain NOP.
    end

    // Combinational instruction read
    assign inst = rom[addr];

endmodule