`timescale 1ns/1ps

module immGen(
    input signed [31:0] instr,
    input wire [2:0] immSel,
    output signed [31:0] imm);

    //assign opcode = instr[6:0];
    //assign funct3 = instr[14:12];
    //assign funct7 = instr[31:25];
    assign imm = immSel == 3'b000 ? {{20{instr[31]}}, instr[31:20]} : // I-type
                 immSel == 3'b001 ? {{20{instr[31]}}, instr[31:25], instr[11:7]} : // S-type
                 immSel == 3'b010 ? {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0} : // B-type
                 immSel == 3'b100 ? {{11{instr[31]}}, instr[31], instr[19:12], instr[20], instr[30:21], 1'b0} : // J-type (jal)
                 32'b0; // Default case
endmodule
