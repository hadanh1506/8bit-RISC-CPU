`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2026 07:14:05 PM
// Design Name: 
// Module Name: sar_adc_ctrl
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

module sar_adc_ctrl (
    input  wire       clk,
    input  wire       rst_n,

    // Cac tin hieu dieu khien
    input  wire       en,
    input  wire       start,
    input  wire [1:0] trig_sel,
    input  wire       timer_ovf,
    input  wire       timer_cmp,

    // Cau hinh ADC
    input  wire [1:0] channel,
    input  wire [7:0] smp,
    input  wire [7:0] div,

    // Tin hieu tu mo hinh analog
    input  wire       adc_cmp,

    // Tin hieu giao tiep analog
    output reg        adc_sample,
    output reg  [1:0] adc_ch,
    output reg  [7:0] adc_dac,

    // Ket qua chuyen doi
    output reg  [7:0] result_data,
    output reg  [1:0] result_ch,
    output reg        result_valid,
    output reg        busy
);

    // Trang thai FSM
    localparam IDLE    = 2'b00;
    localparam SAMPLE  = 2'b01;
    localparam CONVERT = 2'b10;

    reg [1:0] state;
    reg [7:0] div_count;
    reg [7:0] sample_count;
    reg [2:0] bit_index;

    // ADC tick: moi DIV + 1 clock
    wire adc_tick = (div_count >= div);

    // Chon kenh va nguon trigger
    wire trigger_req =
        ((trig_sel == 2'b00) && start)      ||
        ((trig_sel == 2'b01) && timer_ovf)  ||
        ((trig_sel == 2'b10) && timer_cmp)  ||
        ((trig_sel == 2'b11) && (state == IDLE));

    // Quyết định giữ hoặc xóa bit đang thử
    wire [7:0] sar_decision =
        adc_cmp ? adc_dac :
        (adc_dac & ~(8'b00000001 << bit_index));

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state         <= IDLE;
            div_count     <= 0;
            sample_count  <= 0;
            bit_index     <= 0;
            adc_sample    <= 0;
            adc_ch        <= 0;
            adc_dac       <= 0;
            result_data   <= 0;
            result_ch     <= 0;
            result_valid  <= 0;
            busy          <= 0;
        end
        else begin
            // Mac dinh EOC chi bao trong 1 clock
            result_valid <= 0;

            if (!en) begin
                state      <= IDLE;
                busy       <= 0;
                adc_sample <= 0;
                div_count  <= 0;
                adc_dac    <= 0;
            end
            else begin

                // Bo chia clock ADC
                if (state == IDLE)
                    div_count <= 0;
                else if (adc_tick)
                    div_count <= 0;
                else
                    div_count <= div_count + 1'b1;

                case (state)

                    // Cho lenh bat dau
                    IDLE: begin
                        busy       <= 0;
                        adc_sample <= 0;

                        if (trigger_req) begin
                            state        <= SAMPLE;
                            busy         <= 1;
                            adc_sample   <= 1;
                            adc_ch       <= channel;
                            sample_count <= 0;
                            bit_index    <= 7;
                            adc_dac      <= 0;
                            div_count    <= 0;
                        end
                    end

                    // Giu mau trong SMP + 1 ADC ticks
                    SAMPLE: begin
                        if (adc_tick) begin
                            if (sample_count >= smp) begin
                                adc_sample <= 0;
                                adc_dac    <= 8'h80;
                                bit_index  <= 7;
                                state      <= CONVERT;
                            end
                            else begin
                                sample_count <= sample_count + 1'b1;
                            end
                        end
                    end

                    // Thu tung bit tu MSB den LSB
                    CONVERT: begin
                        if (adc_tick) begin
                            adc_dac <= sar_decision;

                            if (bit_index == 0) begin
                                result_data  <= sar_decision;
                                result_ch    <= adc_ch;
                                result_valid <= 1;
                                busy         <= 0;
                                state        <= IDLE;
                            end
                            else begin
                                bit_index <= bit_index - 1'b1;

                                // Bat bit tiep theo de thu
                                adc_dac <= sar_decision |
                                           (8'b00000001 << (bit_index - 1'b1));
                            end
                        end
                    end

                    default: begin
                        state <= IDLE;
                        busy  <= 0;
                    end

                endcase
            end
        end
    end

endmodule


