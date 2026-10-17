`timescale 1ns/1ps
//
// Program 1:
//   addi x1, x0, 10
//   addi x2, x0, 20
//   addi x4, x0, 5
//   xori x3, x1, 0xFF
//   addi x3, x3, 1
//   sub  x5, x4, x1
//   add  x6, x2, x4
//   add  x7, x3, x2
//
// Expected: x1=10 x2=20 x3=245 x4=5 x5=-5 x6=25 x7=265

module tb_program1;

    reg clk;
    reg rst;
    integer error_count;

    dut cpu_dut(
        .clk(clk),
        .rst(rst)
    );

    // Clock generation
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // Load program directly into instruction memory (hierarchical reference)
    initial begin
        cpu_dut.cpu.IMEM[0] = 32'h00a00093; // addi x1, x0, 10
        cpu_dut.cpu.IMEM[1] = 32'h01400113; // addi x2, x0, 20
        cpu_dut.cpu.IMEM[2] = 32'h00500213; // addi x4, x0, 5
        cpu_dut.cpu.IMEM[3] = 32'h0ff0c193; // xori x3, x1, 0xFF
        cpu_dut.cpu.IMEM[4] = 32'h00118193; // addi x3, x3, 1
        cpu_dut.cpu.IMEM[5] = 32'h401202b3; // sub  x5, x4, x1
        cpu_dut.cpu.IMEM[6] = 32'h00410333; // add  x6, x2, x4
        cpu_dut.cpu.IMEM[7] = 32'h002183b3; // add  x7, x3, x2
    end

    initial begin
        rst = 1;
        #10 rst = 0;
        #100; // enough cycles for 8 instructions (10ns/cycle)
        error_count = 0;
        $display("x1 = %0d (expected 10)",  $signed(cpu_dut.cpu.rf.x[1]));
        $display("x2 = %0d (expected 20)",  $signed(cpu_dut.cpu.rf.x[2]));
        $display("x3 = %0d (expected 246)", $signed(cpu_dut.cpu.rf.x[3]));
        $display("x4 = %0d (expected 5)",   $signed(cpu_dut.cpu.rf.x[4]));
        $display("x5 = %0d (expected -5)",  $signed(cpu_dut.cpu.rf.x[5]));
        $display("x6 = %0d (expected 25)",  $signed(cpu_dut.cpu.rf.x[6]));
        $display("x7 = %0d (expected 266)", $signed(cpu_dut.cpu.rf.x[7]));


        if ($signed(cpu_dut.cpu.rf.x[1]) !== 10) begin $display("ERROR: x1 expected 10, got %0d", $signed(cpu_dut.cpu.rf.x[1])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[2]) !== 20) begin $display("ERROR: x2 expected 20, got %0d", $signed(cpu_dut.cpu.rf.x[2])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[3]) !== 246) begin $display("ERROR: x3 expected 245, got %0d", $signed(cpu_dut.cpu.rf.x[3])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[4]) !== 5) begin $display("ERROR: x4 expected 5, got %0d", $signed(cpu_dut.cpu.rf.x[4])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[5]) !== -5) begin $display("ERROR: x5 expected -5, got %0d", $signed(cpu_dut.cpu.rf.x[5])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[6]) !== 25) begin $display("ERROR: x6 expected 25, got %0d", $signed(cpu_dut.cpu.rf.x[6])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[7]) !== 266) begin $display("ERROR: x7 expected 266, got %0d", $signed(cpu_dut.cpu.rf.x[7])); error_count = error_count + 1; end

        if (error_count == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED: %0d mismatches", error_count);

        $finish;
    end

    // Optional waveform dump for GTKWave / Vivado waveform viewer
    initial begin
        $dumpfile("tb_program1.vcd");
        $dumpvars(0, tb_program1);
    end

endmodule
