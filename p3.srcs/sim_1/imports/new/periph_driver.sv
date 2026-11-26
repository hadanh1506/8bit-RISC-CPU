`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 08:53:34 AM
// Design Name: 
// Module Name: periph_driver
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

package periph_driver_pkg;

    import uvm_pkg::*;
    import periph_txn_pkg::*;

    `include "uvm_macros.svh"

    class periph_driver extends uvm_driver #(periph_txn);

        `uvm_component_utils(periph_driver)

        // Ket noi den giao dien DUT
        virtual periph_if vif;

        function new(string name = "periph_driver",
                     uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Lay virtual interface
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if (!uvm_config_db#(virtual periph_if)::get(
                    this, "", "vif", vif)) begin
                `uvm_fatal("DRV", "Cannot get virtual interface")
            end
        endfunction

        // Nhan va xu ly transaction
        task run_phase(uvm_phase phase);

            periph_txn req;

            // Khoi tao bus
            vif.cs    = 0;
            vif.we    = 0;
            vif.addr  = 0;
            vif.wdata = 0;

            wait(vif.rst_n === 1'b1);

            forever begin

                seq_item_port.get_next_item(req);

                drive_transfer(req);

                seq_item_port.item_done();

            end
        endtask

        // Chuyen transaction thanh tin hieu bus
        task drive_transfer(periph_txn tr);

            @(negedge vif.clk);

            vif.cs    = 1'b1;
            vif.we    = (tr.op == periph_txn::WRITE);
            vif.addr  = tr.addr;
            vif.wdata = tr.wdata;

            @(posedge vif.clk);

            // Doc du lieu neu la thao tac READ
            if (tr.op == periph_txn::READ)
                tr.rdata = vif.rdata;

            @(negedge vif.clk);

            // Ket thuc giao dich
            vif.cs    = 1'b0;
            vif.we    = 1'b0;
            vif.addr  = 0;
            vif.wdata = 0;

        endtask

    endclass

endpackage
