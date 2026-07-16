`timescale 1ns/1ps

module aluaddsub(
    input signed [31:0] a,
    input signed [31:0] b,
    input wire addsub,
    output reg signed [31:0] y,
    output reg posflag,
    output reg negflag);
    wire [31:0] bcomp;
    assign bcomp = (~b + 1'b1);
    always @(*) begin
        if(addsub == 1'b0) begin
            y <= #3 a + b;
        end
        else begin
            y <= #3 a + bcomp;
        end
        negflag <= y[31];
        posflag <= (y > 0) && (!y[31]);

    end
endmodule
