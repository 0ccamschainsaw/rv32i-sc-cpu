`timescale 1ns/1ps

module reg32(
input clk,
input rst,
input [31:0] d,
input we,
output reg [31:0] q
);
always @(posedge clk) begin
    if (rst) begin
        q <= #1 32'b0; 
    end else begin
        if (we) begin
            q <= #1 d;
            end else begin
                q <= q; 
                end
        end
end
endmodule