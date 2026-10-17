`timescale 1ns/1ps
// Wrapper that exposes the CPU's instruction-memory WRITE PORT so a testbench
// can load programs the same way real hardware would (front door), instead of
// reaching into cpu.IMEM with hierarchical references (backdoor).
//
// sim/dut.v is intentionally left untouched: it still ties the port off and
// is used by tb_program1/2/3 exactly as before.
//
// The CPU instance is still named "cpu", so hierarchical READS such as
// u.cpu.rf.x[i] or u.cpu.dmem.b0[i] work the same as with dut.v.
module dut_ld(
    input         clk,
    input         rst,
    input         imem_we,
    input  [7:0]  imem_waddr,
    input  [31:0] imem_wdata,
    output [31:0] debug_pc
);

    cpu_SC cpu(
        .clk(clk), .rst(rst),
        .imem_we(imem_we), .imem_waddr(imem_waddr), .imem_wdata(imem_wdata),
        .debug_pc(debug_pc), .debug_wd()
    );

endmodule
