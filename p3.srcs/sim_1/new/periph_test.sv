`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 08:58:41 AM
// Design Name: 
// Module Name: periph_test
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

package periph_test_pkg;

    import uvm_pkg::*;
    import periph_env_pkg::*;
    import periph_sequence_pkg::*;

    `include "uvm_macros.svh"

    class periph_test extends uvm_test;

        `uvm_component_utils(periph_test)

        periph_env env;

        function new(string name = "periph_test",
                     uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Tao moi truong UVM
        function void build_phase(uvm_phase phase);

            super.build_phase(phase);

            env = periph_env::type_id::create(
                    "env", this);

        endfunction

        // Chay Sequence
        task run_phase(uvm_phase phase);

            periph_sequence seq;

            phase.raise_objection(this);

            seq = periph_sequence::type_id::create("seq");

            `uvm_info("TEST",
                "Starting Peripheral Test",
                UVM_LOW)

            seq.start(env.agent.seqr);

            `uvm_info("TEST",
                "Peripheral Test Completed",
                UVM_LOW)

            phase.drop_objection(this);

        endtask

    endclass

endpackage
