`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 11/10/2026 08:57:51 AM
// Design Name: 
// Module Name: periph_env
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

package periph_env_pkg;

    import uvm_pkg::*;
    import periph_agent_pkg::*;
    import periph_scoreboard_pkg::*;

    `include "uvm_macros.svh"

    class periph_env extends uvm_env;

        `uvm_component_utils(periph_env)

        periph_agent      agent;
        periph_scoreboard sb;

        function new(string name = "periph_env",
                     uvm_component parent = null);
            super.new(name, parent);
        endfunction

        // Tao Agent va Scoreboard
        function void build_phase(uvm_phase phase);

            super.build_phase(phase);

            agent = periph_agent::type_id::create(
                    "agent", this);

            sb = periph_scoreboard::type_id::create(
                    "sb", this);

        endfunction

        // Ket noi Monitor voi Scoreboard
        function void connect_phase(uvm_phase phase);

            super.connect_phase(phase);

            agent.mon.ap.connect(sb.analysis_export);

        endfunction

    endclass

endpackage
