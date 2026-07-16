`timescale 1ns/1ps

module alucomp (
    input wire signed [31:0] a,
    input wire signed [31:0] b,
    output reg signed [31:0] out
);
    wire [31:0] sub;
    wire pos,neg;
    aluaddsub sub1(a,b,1'b1,sub,pos,neg);
    always@(*)begin
        if(sub < 0)begin
            out<=32'b1;
        end
        else if(neg==1)begin
            out<=32'b1;
        end
        else begin
            out<=32'b0;
        end
    end
endmodule