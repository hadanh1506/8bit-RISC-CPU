`timescale 1ns / 1ps

package periph_scoreboard_pkg;

    import uvm_pkg::*;
    import periph_txn_pkg::*;
    import periph_pkg::*;

    `include "uvm_macros.svh"

    class periph_scoreboard extends uvm_scoreboard;

        `uvm_component_utils(periph_scoreboard)

        uvm_analysis_imp #(periph_txn, periph_scoreboard) analysis_export;

        bit [7:0] reg_model [16];
        bit       reg_valid [16];

        bit       cov_write;
        bit [3:0] cov_addr;

        int unsigned write_count;
        int unsigned read_count;
        int unsigned readback_pass_count;
        int unsigned readback_fail_count;

        covergroup access_cg;
            cp_op: coverpoint cov_write {
                bins READ  = {0};
                bins WRITE = {1};
            }

            cp_addr: coverpoint cov_addr {
                bins TIMER = {[0:4]};
                bins ADC   = {[5:12]};
                bins IRQ   = {[13:14]};
                bins ID    = {15};
            }

            cross cp_op, cp_addr;
        endgroup

        function new(string name = "periph_scoreboard",
                     uvm_component parent = null);
            super.new(name, parent);
            analysis_export = new("analysis_export", this);
            access_cg = new();
            write_count = 0;
            read_count = 0;
            readback_pass_count = 0;
            readback_fail_count = 0;
        endfunction

        function void build_phase(uvm_phase phase);
            super.build_phase(phase);
            foreach (reg_model[i]) begin
                reg_model[i] = 8'h00;
                reg_valid[i] = 1'b0;
            end
        endfunction

        // Registers whose stable readback is modeled by this scoreboard.
        function bit is_mirrored_reg(bit [3:0] addr);
            case (addr)
                REG_TMR_CTRL,
                REG_TMR_PRESC,
                REG_TMR_LOAD,
                REG_TMR_CMP,
                REG_ADC_CTRL,
                REG_ADC_SMP,
                REG_ADC_DIV,
                REG_ADC_THR_LO,
                REG_ADC_THR_HI,
                REG_IRQ_EN: return 1'b1;
                default:    return 1'b0;
            endcase
        endfunction

        // ADC_CTRL.START is a write pulse and reads back as zero.
        function logic [7:0] readback_value(bit [3:0] addr,
                                            logic [7:0] wdata);
            if (addr == REG_ADC_CTRL)
                return (wdata & 8'hFD);
            return wdata;
        endfunction

        function void write(periph_txn tr);
            cov_write = (tr.op == periph_txn::WRITE);
            cov_addr  = tr.addr;
            access_cg.sample();

            if (tr.op == periph_txn::WRITE) begin
                write_count++;

                if (is_mirrored_reg(tr.addr)) begin
                    reg_model[tr.addr] = readback_value(tr.addr, tr.wdata);
                    reg_valid[tr.addr] = 1'b1;
                    `uvm_info("SB_WRITE",
                        $sformatf("WRITE ADDR=%h WDATA=%h MODEL=%h",
                                  tr.addr, tr.wdata, reg_model[tr.addr]),
                        UVM_MEDIUM)
                end
                else if (tr.addr == REG_IRQ_STAT) begin
                    `uvm_info("SB_W1C",
                        $sformatf("W1C write ADDR=%h MASK=%h", tr.addr, tr.wdata),
                        UVM_MEDIUM)
                end
                else begin
                    `uvm_info("SB_RO_WRITE",
                        $sformatf("Write to non-mirrored/RO register ADDR=%h DATA=%h",
                                  tr.addr, tr.wdata), UVM_HIGH)
                end
            end
            else begin
                read_count++;

                if (tr.addr == REG_ID) begin
                    if (tr.rdata !== PERIPH_ID) begin
                        readback_fail_count++;
                        `uvm_error("SB_ID",
                            $sformatf("ID ERROR: expected=%h actual=%h",
                                      PERIPH_ID, tr.rdata))
                    end
                    else begin
                        readback_pass_count++;
                        `uvm_info("SB_ID", "Peripheral ID check PASSED", UVM_LOW)
                    end
                end
                else if (is_mirrored_reg(tr.addr) && reg_valid[tr.addr]) begin
                    if (tr.rdata !== reg_model[tr.addr]) begin
                        readback_fail_count++;
                        `uvm_error("SB_READBACK",
                            $sformatf("READBACK ERROR ADDR=%h EXPECTED=%h ACTUAL=%h",
                                      tr.addr, reg_model[tr.addr], tr.rdata))
                    end
                    else begin
                        readback_pass_count++;
                        `uvm_info("SB_READBACK",
                            $sformatf("READBACK PASSED ADDR=%h DATA=%h",
                                      tr.addr, tr.rdata), UVM_LOW)
                    end
                end
                else if (tr.addr == REG_ADC_DATA) begin
                    `uvm_info("SB_ADC_DATA",
                        $sformatf("ADC_DATA read/pop DATA=%h", tr.rdata), UVM_MEDIUM)
                end
            end
        endfunction

        function void report_phase(uvm_phase phase);
            super.report_phase(phase);
            `uvm_info("SB_SUMMARY",
                $sformatf("Transactions: writes=%0d reads=%0d | register/ID readback: pass=%0d fail=%0d",
                          write_count, read_count,
                          readback_pass_count, readback_fail_count), UVM_LOW)
            `uvm_info("COV",
                $sformatf("Register access functional coverage = %0.2f%%",
                          access_cg.get_coverage()), UVM_LOW)
        endfunction

    endclass

endpackage
