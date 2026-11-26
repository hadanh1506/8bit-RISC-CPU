`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 08:54:17 AM
// Design Name: 
// Module Name: periph_monitor
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

package periph_monitor_pkg;

    import uvm_pkg::*;
    import periph_txn_pkg::*;

    `include "uvm_macros.svh"

    class periph_monitor extends uvm_monitor;

        `uvm_component_utils(periph_monitor)

        virtual periph_if vif;

        // Gui transaction quan sat duoc
        uvm_analysis_port #(periph_txn) ap;

        function new(string name = "periph_monitor",
                     uvm_component parent = null);
            super.new(name, parent);
            ap = new("ap", this);
        endfunction

        // Lay virtual interface
        function void build_phase(uvm_phase phase);
            super.build_phase(phase);

            if (!uvm_config_db#(virtual periph_if)::get(
                    this, "", "vif", vif)) begin
                `uvm_fatal("MON", "Cannot get virtual interface")
            end
        endfunction

        // Quan sat bus
        task run_phase(uvm_phase phase);

            periph_txn tr;

            forever begin

                @(posedge vif.clk);

                if (vif.rst_n && vif.cs) begin

                    tr = periph_txn::type_id::create("tr");

                    tr.op    = vif.we ?
                               periph_txn::WRITE :
                               periph_txn::READ;

                    tr.addr  = vif.addr;
                    tr.wdata = vif.wdata;
                    tr.rdata = vif.rdata;

                    // Gui transaction den Scoreboard
                    ap.write(tr);

                    `uvm_info("MON",
                        $sformatf("OP=%s ADDR=%h WDATA=%h RDATA=%h",
                        (vif.we ? "WRITE" : "READ"),
                        vif.addr, vif.wdata, vif.rdata),
                        UVM_MEDIUM)

                end
            end
        endtask

    endclass

endpackage