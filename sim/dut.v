`timescale 1ns/1ps
// Top-level wrapper around the single-cycle CPU, matching the lab's
// required top-level module naming convention (dut -> cpu_SC).

module dut(
    input clk,
    input rst
);

    cpu_SC cpu(
        .clk(clk), .rst(rst),
        .imem_we(1'b0), .imem_waddr(8'd0), .imem_wdata(32'd0),
        .debug_pc(), .debug_wd()
    );

endmodule
