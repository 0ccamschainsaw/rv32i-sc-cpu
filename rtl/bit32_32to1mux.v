`timescale 1ns/1ps
module bit32_32to1mux(
    output [31:0]   out,
    input  [4:0]    sel,
    input  [1023:0] in      // {reg31, reg30, ..., reg1, reg0}
);

    assign out = in[sel*32 +: 32];

endmodule