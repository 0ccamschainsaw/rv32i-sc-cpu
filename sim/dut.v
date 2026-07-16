`timescale 1ns/1ps
// Top-level wrapper around the single-cycle CPU
// top-level module naming convention (dut is cpu_SC).

module dut(
    input clk,
    input rst
);

    cpu_SC cpu(
        .clk(clk),
        .rst(rst)
    );

endmodule
