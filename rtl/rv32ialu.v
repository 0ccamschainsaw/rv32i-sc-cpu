`timescale 1ns/1ps

module rv32ialu (
    input  signed [31:0] A,
    input  signed [31:0] B,
    input  [2:0] alu_ctrl,
    output signed [31:0] Y,
    output zero
);

    wire [31:0] add_result;
    wire [31:0] sub_result;
    wire [31:0] slt_result;
    wire [31:0] sltu_result;
    wire add_posflag, add_negflag, sub_posflag, sub_negflag;
    
    // Adder: ADD (alu_ctrl = 001)
    aluaddsub adder (
        .a(A),
        .b(B),
        .addsub(1'b0),
        .y(add_result),
        .posflag(add_posflag),
        .negflag(add_negflag)
    );
    
    // Subtractor: SUB (alu_ctrl = 000)
    aluaddsub subtractor (
        .a(A),
        .b(B),
        .addsub(1'b1),
        .y(sub_result),
        .posflag(sub_posflag),
        .negflag(sub_negflag)
    );
    
    // Comparator: SLT (110)
    alucomp comparator (
        .a(A),
        .b(B),
        .out(slt_result)
    );
    
    // Unsigned comparator: SLTU
    alusltu ucomp (
        .A(A),
        .B(B),
        .Y(sltu_result)
    );
    
    // Separate logic operations
    wire [31:0] logic_and, logic_or;
    assign #1 logic_and = A & B;
    assign #1 logic_or = A | B;
    
    // Separate shift operations
    wire [31:0] shift_left, shift_right;
    assign #2 shift_left = A << B[4:0];
    assign #2 shift_right = A >> B[4:0];
    
    wire [31:0] logical_xor;
    assign #1 logical_xor = A ^ B;
    
    // Main multiplexer with canonical delay #1
    wire [31:0] final_result;
    assign #1 final_result = (alu_ctrl == 3'b000) ? sub_result :
                             (alu_ctrl == 3'b001) ? add_result :
                             (alu_ctrl == 3'b010) ? logic_and :
                             (alu_ctrl == 3'b011) ? logic_or :
                             (alu_ctrl == 3'b100) ? shift_left :
                             (alu_ctrl == 3'b101) ? shift_right :
                             (alu_ctrl == 3'b110) ? slt_result :
                             (alu_ctrl == 3'b111) ? logical_xor :
                             32'h0;
    
    assign Y = final_result;
    assign zero = (final_result == 32'h0);

endmodule