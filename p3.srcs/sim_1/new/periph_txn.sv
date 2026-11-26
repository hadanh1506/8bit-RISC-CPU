`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 08:19:15 AM
// Design Name: 
// Module Name: periph_txn
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




package periph_txn_pkg;

    import uvm_pkg::*;
    `include "uvm_macros.svh"

    // Mo ta mot giao dich truy cap ngoai vi
    class periph_txn extends uvm_sequence_item;

        typedef enum bit {
            READ,
            WRITE
        } op_t;

        rand op_t      op;
        rand bit [3:0] addr;
        rand bit [7:0] wdata;

             bit [7:0] rdata;

        `uvm_object_utils_begin(periph_txn)
            `uvm_field_enum(op_t, op, UVM_ALL_ON)
            `uvm_field_int(addr, UVM_ALL_ON)
            `uvm_field_int(wdata, UVM_ALL_ON)
            `uvm_field_int(rdata, UVM_ALL_ON)
        `uvm_object_utils_end

        function new(string name = "periph_txn");
            super.new(name);
        endfunction

    endclass

endpackage
