module bit32_32to1mux(
    output [31:0] out,
    input [4:0] sel,
    input [31:0] in[0:31]
);

    assign out = in[sel];

endmodule
