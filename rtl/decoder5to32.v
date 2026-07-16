`timescale 1ns/1ps

module decoder5to32(
    input wire [4:0] rd,
    input wire reg_write_en,
    output wire [31:0] dec_out
);

assign #1 dec_out = (reg_write_en && rd != 5'b00000) ? (32'b1 << rd) : 32'b0;
endmodule