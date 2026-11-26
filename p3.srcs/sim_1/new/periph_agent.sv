`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 08:54:55 AM
// Design Name: 
// Module Name: periph_agent
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

package periph_agent_pkg;

    import uvm_pkg::*;
    import periph_sequencer_pkg::*;
    import periph_driver_pkg::*;
    import periph_monitor_pkg::*;

    `include "uvm_macros.svh"

    class periph_agent extends uvm_agent;

        `uvm_component_utils(periph_agent)

        periph_sequencer seqr;
        periph_driver    drv;
        periph_monitor   mon;

        function new(string name = "periph_agent",
                     uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Tao cac thanh phan
        function void build_phase(uvm_phase phase);

            super.build_phase(phase);

            mon = periph_monitor::type_id::create(
                    "mon", this);

            if (get_is_active() == UVM_ACTIVE) begin

                seqr = periph_sequencer::type_id::create(
                        "seqr", this);

                drv = periph_driver::type_id::create(
                        "drv", this);

            end
        endfunction

        // Ket noi Sequencer va Driver
        function void connect_phase(uvm_phase phase);

            super.connect_phase(phase);

            if (get_is_active() == UVM_ACTIVE) begin
                drv.seq_item_port.connect(
                    seqr.seq_item_export
                );
            end
        endfunction

    endclass

endpackage
