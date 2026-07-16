`timescale 1ns/1ps

module alusltu (
    input  [31:0] A,
    input  [31:0] B,
    output [31:0] Y
);

    
    wire [32:0] diff;  // 33 bits to capture borrow
    
    // Perform unsigned subtraction with explicit borrow detection
    assign diff = {1'b0, A} - {1'b0, B};
    
    // Borrow is indicated by underflow (MSB set)
    wire unsigned_less_than = diff[32];
    
    // Output 1 if A < B (unsigned), 0 otherwise
    assign Y = {{31{1'b0}}, unsigned_less_than};

endmodule