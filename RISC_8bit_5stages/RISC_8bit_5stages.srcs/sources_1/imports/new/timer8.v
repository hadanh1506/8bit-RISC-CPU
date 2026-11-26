`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2026 07:04:23 PM
// Design Name: 
// Module Name: timer8
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

module timer8 (
    input  wire       clk,
    input  wire       rst_n,

    input  wire       en,          // Bit EN
    input  wire       oneshot,     // Bit ONESHOT
    input  wire [7:0] presc,       // Prescaler
    input  wire [7:0] load,        // Gia tri LOAD
    input  wire [7:0] cmp,         // Gia tri Compare

    output reg  [7:0] count,       // Gia tri dem hien tai
    output reg        tick,        // Xung khi Timer tran
    output wire       pwm,         // Tin hieu PWM
    output reg        ovf_evt,     // Su kien Overflow
    output reg        cmp_evt      // Su kien Compare
);

    reg [7:0] presc_count;
    reg       oneshot_done;

    // Timer dung sau khi hoan thanh mot chu ky ONESHOT
    wire running = en && !(oneshot && oneshot_done);

    // PWM muc cao khi count nho hon cmp
    assign pwm = running && (count < cmp);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            presc_count <= 8'd0;
            count       <= 8'd0;
            tick        <= 1'b0;
            ovf_evt     <= 1'b0;
            cmp_evt     <= 1'b0;
            oneshot_done <= 1'b0;
        end
        else begin
            // Mac dinh cac xung su kien chi ton tai 1 chu ky
            tick    <= 1'b0;
            ovf_evt <= 1'b0;
            cmp_evt <= 1'b0;

            if (!en) begin
                presc_count  <= 8'd0;
                count        <= 8'd0;
                oneshot_done <= 1'b0;
            end
            else if (running) begin
                // Dem du so clock Prescaler
                if (presc_count >= presc) begin
                    presc_count <= 8'd0;

                    // Phat hien su kien Compare
                    if (count == cmp)
                        cmp_evt <= 1'b1;

                    // Het chu ky Timer
                    if (count >= load) begin
                        count   <= 8'd0;
                        tick    <= 1'b1;
                        ovf_evt <= 1'b1;

                        // Dung Timer neu dang ONESHOT
                        if (oneshot)
                            oneshot_done <= 1'b1;
                    end
                    else begin
                        count <= count + 8'd1;
                    end
                end
                else begin
                    presc_count <= presc_count + 8'd1;
                end
            end
        end
    end

endmodule

