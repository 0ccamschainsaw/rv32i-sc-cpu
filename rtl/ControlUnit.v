module ControlUnit (instruction, zero, RegWrite, ALUSrc, MemWrite, MemRead, ImmSel, PCsrc, Jal, IsRtype);
    input [31:0] instruction;
    input zero;
    output RegWrite, ALUSrc, MemWrite, MemRead, Jal;
    output [2:0] ImmSel;
    output PCsrc;
    output IsRtype;

    wire [6:0] opcode;
    wire [2:0] funct3;
    wire [6:0] funct7;

    assign opcode = instruction[6:0];
    assign funct3 = instruction[14:12];
    assign funct7 = instruction[31:25];

    wire is_rtype;
    wire is_ialu;
    wire is_iload;
    wire is_stype;
    wire is_btype;
    wire is_jal;

    assign is_rtype = ~opcode[6] &  opcode[5] &  opcode[4] & ~opcode[3] & ~opcode[2] &  opcode[1] &  opcode[0];
    assign is_ialu  = ~opcode[6] & ~opcode[5] &  opcode[4] & ~opcode[3] & ~opcode[2] &  opcode[1] &  opcode[0];
    assign is_iload = ~opcode[6] & ~opcode[5] & ~opcode[4] & ~opcode[3] & ~opcode[2] &  opcode[1] &  opcode[0];
    assign is_stype = ~opcode[6] &  opcode[5] & ~opcode[4] & ~opcode[3] & ~opcode[2] &  opcode[1] &  opcode[0];
    assign is_btype =  opcode[6] &  opcode[5] & ~opcode[4] & ~opcode[3] & ~opcode[2] &  opcode[1] &  opcode[0];
    assign is_jal   = opcode[6] &  opcode[5] &  ~opcode[4] &  opcode[3] & opcode[2] &  opcode[1] &  opcode[0];

    wire f3_000;
    wire f3_001;
    wire f3_010;
    wire f3_100;
    wire f3_101;
    wire f3_110;
    wire f3_111;

    assign f3_000 = ~funct3[2] & ~funct3[1] & ~funct3[0];
    assign f3_001 = ~funct3[2] & ~funct3[1] &  funct3[0];
    assign f3_010 = ~funct3[2] &  funct3[1] & ~funct3[0];
    assign f3_100 =  funct3[2] & ~funct3[1] & ~funct3[0];
    assign f3_101 =  funct3[2] & ~funct3[1] &  funct3[0];
    assign f3_110 =  funct3[2] &  funct3[1] & ~funct3[0];
    assign f3_111 =  funct3[2] &  funct3[1] &  funct3[0];

    wire is_beq;
    wire is_bne;

    assign is_beq = is_btype & f3_000;
    assign is_bne = is_btype & f3_001;

    wire f7_alt;
    assign f7_alt = ~funct7[6] &  funct7[5] & ~funct7[4] & ~funct7[3] & ~funct7[2] & ~funct7[1] & ~funct7[0];

    wire is_alu_instr;
    assign is_alu_instr = is_rtype | is_ialu;

    assign RegWrite  = is_rtype | is_ialu | is_iload | is_jal;
    assign ALUSrc    = is_ialu  | is_iload | is_stype;
    assign MemWrite  = is_stype;
    assign MemRead   = is_iload;
    assign ImmSel[0] = is_stype;
    assign ImmSel[1] = is_btype;
    assign ImmSel[2] = is_jal;
    assign PCsrc     = is_jal | (is_beq & zero) | (is_bne & ~zero);
    assign Jal       = is_jal;
    assign IsRtype   = is_rtype;

    //assign ALUOp[2] = is_alu_instr & (f3_001 | f3_010 | f3_100 | f3_101);
    //assign ALUOp[1] = is_alu_instr & (f3_010 | f3_101 | f3_110 | f3_111);
    //assign ALUOp[0] = is_alu_instr & ( (f3_000 & is_rtype & f7_alt) | f3_001 | f3_010 | f3_110 );
endmodule