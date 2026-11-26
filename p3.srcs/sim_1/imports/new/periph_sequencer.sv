`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 08:44:55 AM
// Design Name: 
// Module Name: periph_sequencer
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

package periph_sequencer_pkg;

    import uvm_pkg::*;
    import periph_txn_pkg::*;

    `include "uvm_macros.svh"

    // Dieu phoi cac transaction den Driver
    class periph_sequencer extends uvm_sequencer #(periph_txn);

        `uvm_component_utils(periph_sequencer)

        // Ham khoi tao
        function new(string name = "periph_sequencer",
                     uvm_component parent = null);
            super.new(name, parent);
        endfunction

    endclass

endpackage

