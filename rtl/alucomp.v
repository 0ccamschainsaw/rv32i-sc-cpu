`timescale 1ns/1ps

module alucomp (
    input wire signed [31:0] a,
    input wire signed [31:0] b,
    output reg signed [31:0] out
);
    always @(*) out = {31'b0, ($signed(a) < $signed(b))};
endmodule
