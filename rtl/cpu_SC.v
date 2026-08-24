`timescale 1ns/1ps

module cpu_SC(
    input clk,
    input rst
    output [31:0] debug_pc,
    output [15:0] debug_wd
);

    reg [31:0] PC;
    reg [31:0] IMEM [0:255]; // Instruction memory, 256 words

    wire [31:0] instruction;
    wire [31:0] imm;
    wire [31:0] r1, r2;
    wire [31:0] alu_result;
    wire zero;
    wire [31:0] mem_data;
    wire [31:0] wd; // write data to reg

    wire RegWrite, ALUSrc, MemWrite, MemRead, Jal;
    //wire [2:0] ALUOp;
    wire [2:0] ImmSel;
    wire PCsrc;

    wire [2:0] alu_ctrl_sig;
    wire is_rtype_sig;

    // Instruction fetch
    assign instruction = IMEM[PC[9:2]];

    // Control unit
    ControlUnit cu(
        .instruction(instruction),
        .zero(zero),
        .RegWrite(RegWrite),
        .ALUSrc(ALUSrc),
        .MemWrite(MemWrite),
        .MemRead(MemRead),
        .ImmSel(ImmSel),
        .PCsrc(PCsrc),
        .Jal(Jal),
        .IsRtype(is_rtype_sig)
    );

    // Immediate generator
    immGen ig(
        .instr(instruction),
        .immSel(ImmSel),
        .imm(imm)
    );

    // Register file
    regfile rf(
        .clk(clk),
        .reset(rst),
        .we(RegWrite),
        .rs1(instruction[19:15]),
        .rs2(instruction[24:20]),
        .rd(instruction[11:7]),
        .wd(wd),
        .r1(r1),
        .r2(r2)
    );

    // ALU control
    alu_ctrl alu_c(
        .alu_ctrl(alu_ctrl_sig),
        .funct3(instruction[14:12]),
        .funct7_5(instruction[30]),
        .use_funct7(is_rtype_sig)
    );

    // ALU
    rv32ialu alu(
        .A(r1),
        .B(ALUSrc ? imm : r2),
        .alu_ctrl(alu_ctrl_sig),
        .Y(alu_result),
        .zero(zero)
    );

    // Data memory
    BankedMEM dmem(
        .clk(clk),
        .rst(rst),
        .addr(alu_result),
        .wdata(r2),
        .writeEn(MemWrite),
        .rdata(mem_data)
    );

    // Write data mux
    assign wd = Jal ? (PC + 4) : (MemRead ? mem_data : alu_result);

    // PC update logic
    wire [31:0] pc_plus_4;
    wire [31:0] pc_branch;

    aluaddsub pc_add4(
        .a(PC),
        .b(32'd4),
        .addsub(1'b0),
        .y(pc_plus_4),
        .posflag(),
        .negflag()
    );

    aluaddsub pc_branch_add(
        .a(PC),
        .b(imm),
        .addsub(1'b0),
        .y(pc_branch),
        .posflag(),
        .negflag()
    );

    always @(posedge clk or posedge rst) begin
        if (rst) begin
            PC <= 32'b0;
        end else begin
            PC <= PCsrc ? pc_branch : pc_plus_4;
        end
    end
    assign debug_pc = PC;
    assign debug_wd = wd[15:0];

endmodule
