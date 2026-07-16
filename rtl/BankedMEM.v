`timescale 1ns/1ps

module BankedMEM(
    input wire clk,
    input wire rst,
    input wire [31:0] addr,
    input wire [31:0] wdata,
    input wire writeEn,
    output reg [31:0] rdata
);

    reg [7:0] b0 [0:1023];
    reg [7:0] b1 [0:1023];
    reg [7:0] b2 [0:1023];
    reg [7:0] b3 [0:1023];

    integer i;

    initial begin
        for (i = 0; i < 1024; i = i + 1) begin
            b0[i] = 8'h00;
            b1[i] = 8'h00;
            b2[i] = 8'h00;
            b3[i] = 8'h00;
        end
    end

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset logic if needed
        end else if (writeEn) begin
            b0[addr[11:2]] <= wdata[7:0];
            b1[addr[11:2]] <= wdata[15:8];
            b2[addr[11:2]] <= wdata[23:16];
            b3[addr[11:2]] <= wdata[31:24];
        end
    end

    always @(*) begin
        rdata = {b3[addr[11:2]], b2[addr[11:2]], b1[addr[11:2]], b0[addr[11:2]]};
    end

endmodule