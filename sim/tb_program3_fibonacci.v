`timescale 1ns/1ps
//
// Program 3: Fibonacci
//   addi x1, x0, 0
//   addi x2, x0, 1
//   addi x3, x0, 10
// loop:
//   add  x4, x1, x2
//   add  x1, x2, x0
//   add  x2, x4, x0
//   addi x3, x3, -1
//   bne  x3, x0, loop
//
// After 10 loop iterations: x1 and x2 hold consecutive Fibonacci numbers.
// Expected final: x1 = 55, x2 = 89, x3 = 0

module tb_program3_fibonacci;

    reg clk;
    reg rst;
    integer error_count;

    dut cpu_dut(
        .clk(clk),
        .rst(rst)
    );

    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    initial begin
        cpu_dut.cpu.IMEM[0] = 32'h00000093; // addi x1, x0, 0
        cpu_dut.cpu.IMEM[1] = 32'h00100113; // addi x2, x0, 1
        cpu_dut.cpu.IMEM[2] = 32'h00a00193; // addi x3, x0, 10
        cpu_dut.cpu.IMEM[3] = 32'h00208233; // loop: add x4, x1, x2
        cpu_dut.cpu.IMEM[4] = 32'h000100b3; //       add x1, x2, x0
        cpu_dut.cpu.IMEM[5] = 32'h00020133; //       add x2, x4, x0
        cpu_dut.cpu.IMEM[6] = 32'hfff18193; //       addi x3, x3, -1
        cpu_dut.cpu.IMEM[7] = 32'hfe0198e3; //       bne x3, x0, loop
    end

    initial begin
        rst = 1;
        #10 rst = 0;
        // 3 setup instructions + 10 iterations * 5 instructions = 53 instructions,
        // give generous margin: 60 cycles * 10ns
        #620;

        error_count = 0;
        $display("---- Program 3 (Fibonacci) Results ----");
        $display("x1 = %0d (expected 55)", $signed(cpu_dut.cpu.rf.x[1]));
        $display("x2 = %0d (expected 89)", $signed(cpu_dut.cpu.rf.x[2]));
        $display("x3 = %0d (expected 0)",  $signed(cpu_dut.cpu.rf.x[3]));

        if ($signed(cpu_dut.cpu.rf.x[1]) !== 55) begin $display("ERROR: x1 expected 55, got %0d", $signed(cpu_dut.cpu.rf.x[1])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[2]) !== 89) begin $display("ERROR: x2 expected 89, got %0d", $signed(cpu_dut.cpu.rf.x[2])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[3]) !== 0) begin $display("ERROR: x3 expected 0, got %0d", $signed(cpu_dut.cpu.rf.x[3])); error_count = error_count + 1; end

        if (error_count == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED: %0d mismatches", error_count);

        $finish;
    end

    initial begin
        $dumpfile("tb_program3_fibonacci.vcd");
        $dumpvars(0, tb_program3_fibonacci);
    end

endmodule
