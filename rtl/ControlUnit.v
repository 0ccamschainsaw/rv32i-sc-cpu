`timescale 1ns/1ps
module ControlUnit (instruction, zero, RegWrite, ALUSrc, MemWrite, MemRead, ImmSel, PCsrc, Jal, IsRtype);
    input [31:0] instruction;
    input zero;
    output RegWrite, ALUSrc, MemWrite, MemRead, Jal;
    output [2:0] ImmSel;
    output PCsrc;
    output IsRtype;

    wire [6:0] opcode = instruction[6:0];
    wire [2:0] funct3 = instruction[14:12];
    wire [6:0] funct7 = instruction[31:25];
    wire valid_opcode = opcode[1:0] == 2'b11;

    wire is_rtype = valid_opcode && opcode == 7'b0110011;
    wire is_ialu  = valid_opcode && opcode == 7'b0010011;
    wire is_iload = valid_opcode && opcode == 7'b0000011;
    wire is_stype = valid_opcode && opcode == 7'b0100011;
    wire is_btype = valid_opcode && opcode == 7'b1100011;
    wire is_jal   = valid_opcode && opcode == 7'b1101111;
    wire is_jalr  = valid_opcode && opcode == 7'b1100111 && funct3 == 3'b000;
    wire is_lui   = valid_opcode && opcode == 7'b0110111;
    wire is_auipc = valid_opcode && opcode == 7'b0010111;

    wire alu_unsup = (is_rtype || is_ialu) &&
                     (funct3 == 3'b011 || (funct3 == 3'b101 && funct7[5]));
    wire is_lw = is_iload && funct3 == 3'b010;
    wire is_sw = is_stype && funct3 == 3'b010;
    wire taken = is_btype &&
                 ((funct3 == 3'b000 && zero) ||
                  (funct3 == 3'b001 && !zero) ||
                  (funct3 == 3'b100 && !zero) ||
                  (funct3 == 3'b101 && zero));

    assign RegWrite = ((is_rtype || is_ialu) && !alu_unsup) || is_lw || is_jal || is_jalr || is_lui || is_auipc;
    assign ALUSrc = is_ialu || is_lw || is_sw || is_jalr;
    assign MemWrite = is_sw;
    assign MemRead = is_lw;
    assign PCsrc = is_jal || taken;
    assign Jal = is_jal || is_jalr;
    assign IsRtype = is_rtype;
    assign ImmSel[0] = is_stype || is_lui || is_jalr;
    assign ImmSel[1] = is_btype || is_lui || is_auipc;
    assign ImmSel[2] = is_jal || is_jalr || is_auipc;
endmodule
