module alu_ctrl(alu_ctrl, funct3, funct7_5, use_funct7);
    input [2:0] funct3;
    input funct7_5;
    input use_funct7;
    output reg [2:0] alu_ctrl;

    always @(*) begin
        case (funct3)
            3'b000:  alu_ctrl = #1 (use_funct7 && funct7_5) ? 3'b000 : 3'b001; // SUB : ADD
            3'b111:  alu_ctrl = #1 3'b010; // AND
            3'b110:  alu_ctrl = #1 3'b011; // OR
            3'b001:  alu_ctrl = #1 3'b100; // SLL
            3'b010:  alu_ctrl = #1 3'b110; // SLT
            3'b100:  alu_ctrl = #1 3'b111; // XOR
            default: alu_ctrl = #1 3'b000;
        endcase
    end
endmodule