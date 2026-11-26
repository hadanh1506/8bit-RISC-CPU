`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2026 07:29:33 PM
// Design Name: 
// Module Name: apb_regs8
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

module apb_regs8 (
    input  wire       clk,
    input  wire       rst_n,

    // Giao tiep CPU
    input  wire       cs,
    input  wire       we,
    input  wire [3:0] addr,
    input  wire [7:0] wdata,
    output reg  [7:0] rdata,

    // Dieu khien Timer
    output reg        timer_en,
    output reg        timer_oneshot,
    output reg  [7:0] timer_presc,
    output reg  [7:0] timer_load,
    output reg  [7:0] timer_cmp,
    input  wire [7:0] timer_count,
    input  wire       timer_ovf_evt,
    input  wire       timer_cmp_evt,

    // Dieu khien ADC
    output reg        adc_en,
    output reg        adc_start,
    output reg  [1:0] adc_trig_sel,
    output reg  [1:0] adc_channel,
    output reg  [7:0] adc_smp,
    output reg  [7:0] adc_div,
    output reg  [7:0] adc_thr_lo,
    output reg  [7:0] adc_thr_hi,
    input  wire       adc_busy,
    input  wire       adc_result_valid,
    input  wire [7:0] adc_result_data,

    // Giao tiep FIFO
    input  wire [7:0] fifo_data,
    input  wire [1:0] fifo_ch,
    input  wire [3:0] fifo_level,
    input  wire       fifo_full,
    input  wire       fifo_empty,
    input  wire       fifo_overflow,
    output wire       fifo_rd_en,

    // Interrupt
    output wire       irq
);

    reg [7:0] irq_en;
    reg [7:0] irq_status;

    // Doc ADC_DATA se pop phan tu dau FIFO
    assign fifo_rd_en = cs && !we &&
                        (addr == 4'hA) && !fifo_empty;

    // ADC warning khi ket qua nam ngoai nguong
    wire adc_wd = adc_result_valid &&
                  ((adc_result_data < adc_thr_lo) ||
                   (adc_result_data > adc_thr_hi));

    // Cac su kien phan cung
    // Bit 0: Timer Overflow
    // Bit 1: Timer Compare
    // Bit 2: ADC End Of Conversion
    // Bit 3: ADC Warning
    // Bit 4: FIFO Overflow
    wire [7:0] event_set = {
        3'b000,
        fifo_overflow,
        adc_wd,
        adc_result_valid,
        timer_cmp_evt,
        timer_ovf_evt
    };

    // IRQ chi duoc kich hoat neu flag duoc enable
    assign irq = |(irq_status & irq_en);

    // ==================================================
    // WRITE: Ghi cac thanh ghi cau hinh
    // ==================================================
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_en       <= 0;
            timer_oneshot  <= 0;
            timer_presc    <= 0;
            timer_load     <= 0;
            timer_cmp      <= 0;

            adc_en         <= 0;
            adc_start      <= 0;
            adc_trig_sel   <= 0;
            adc_channel    <= 0;
            adc_smp        <= 0;
            adc_div        <= 0;
            adc_thr_lo     <= 0;
            adc_thr_hi     <= 8'hFF;

            irq_en         <= 0;
            irq_status     <= 0;
        end
        else begin
            // START chi la xung mot clock
            adc_start <= 0;

            if (cs && we) begin
                case (addr)

                    4'h0: begin
                        timer_en      <= wdata[0];
                        timer_oneshot <= wdata[1];
                    end

                    4'h1: timer_presc <= wdata;
                    4'h2: timer_load  <= wdata;
                    4'h3: timer_cmp   <= wdata;

                    4'h5: begin
                        adc_en       <= wdata[0];
                        adc_start    <= wdata[1];
                        adc_trig_sel <= wdata[3:2];
                        adc_channel  <= wdata[5:4];
                    end

                    4'h6: adc_smp    <= wdata;
                    4'h7: adc_div    <= wdata;
                    4'h8: adc_thr_lo <= wdata;
                    4'h9: adc_thr_hi <= wdata;
                    4'hD: irq_en     <= wdata;

                    default: ; // RO va dia chi khong hop le

                endcase
            end

            // W1C: Ghi 1 de xoa flag.
            // Su kien moi uu tien neu xuat hien cung clock.
            if (cs && we && addr == 4'hE)
                irq_status <= (irq_status & ~wdata) | event_set;
            else
                irq_status <= irq_status | event_set;
        end
    end

    // ==================================================
    // READ: Chon du lieu tra ve CPU
    // ==================================================
    always @(*) begin
        rdata = 8'h00;

        if (cs && !we) begin
            case (addr)

                4'h0: rdata = {6'b0, timer_oneshot, timer_en};
                4'h1: rdata = timer_presc;
                4'h2: rdata = timer_load;
                4'h3: rdata = timer_cmp;
                4'h4: rdata = timer_count;

                4'h5: rdata = {
                    2'b00, adc_channel,
                    adc_trig_sel, 1'b0, adc_en
                };

                4'h6: rdata = adc_smp;
                4'h7: rdata = adc_div;
                4'h8: rdata = adc_thr_lo;
                4'h9: rdata = adc_thr_hi;

                4'hA: rdata = fifo_data;

                4'hB: rdata = fifo_empty ? 8'h00 :
                              {1'b1, 5'b00000, fifo_ch};

                4'hC: rdata = {
                    1'b0, adc_busy, fifo_full,
                    fifo_empty, fifo_level
                };

                4'hD: rdata = irq_en;
                4'hE: rdata = irq_status;
                4'hF: rdata = 8'hA8;

                default: rdata = 8'h00;

            endcase
        end
    end

endmodule


