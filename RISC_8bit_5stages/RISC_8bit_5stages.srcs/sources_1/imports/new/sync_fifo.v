`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/08/2026 07:16:16 PM
// Design Name: 
// Module Name: sync_fifo
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

module sync_fifo (
    input  wire       clk,
    input  wire       rst_n,

    // Dieu khien ghi
    input  wire       wr_en,
    input  wire [7:0] wr_data,
    input  wire [1:0] wr_ch,

    // Dieu khien doc
    input  wire       rd_en,
    output wire [7:0] rd_data,
    output wire [1:0] rd_ch,

    // Trang thai FIFO
    output wire       full,
    output wire       empty,
    output wire [3:0] level,
    output reg        overflow
);

    // FIFO gom 8 phan tu, moi phan tu 10 bit
    reg [9:0] mem [0:7];

    // Con tro doc va ghi
    reg [2:0] wr_ptr;
    reg [2:0] rd_ptr;

    // So phan tu hien dang luu
    reg [3:0] count;

    wire write_ok = wr_en && !full;
    wire read_ok  = rd_en && !empty;

    // Trang thai FIFO
    assign full  = (count == 4'd8);
    assign empty = (count == 4'd0);
    assign level = count;

    // Doc phan tu dau tien, khong xoa cho den khi co rd_en
    assign rd_data = empty ? 8'h00 : mem[rd_ptr][7:0];
    assign rd_ch   = empty ? 2'b00 : mem[rd_ptr][9:8];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            wr_ptr   <= 0;
            rd_ptr   <= 0;
            count    <= 0;
            overflow <= 0;
        end
        else begin
            // Overflow event chi ton tai 1 clock
            overflow <= 0;

            // Ghi du lieu moi neu FIFO chua day
            if (wr_en && full) begin
                overflow <= 1;
            end
            else if (write_ok) begin
                mem[wr_ptr] <= {wr_ch, wr_data};
                wr_ptr <= wr_ptr + 1'b1;
            end

            // Doc va loai bo phan tu cu nhat
            if (read_ok) begin
                rd_ptr <= rd_ptr + 1'b1;
            end

            // Cap nhat so luong phan tu
            case ({write_ok, read_ok})
                2'b10: count <= count + 1'b1;
                2'b01: count <= count - 1'b1;
                default: count <= count;
            endcase
        end
    end

endmodule

