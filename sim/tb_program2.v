`timescale 1ns/1ps
//
// Program 2:
//   addi x1, x0, 10
//   addi x2, x0, 5
//   add  x3, x1, x2
//   sub  x4, x3, x2
//   lw   x5, 0(x3)
//   add  x6, x5, x1
//   sw   x6, 0(x2)
//
// Notes: x3 = 15 is used as a byte address for the lw. BankedMEM is
// zero-initialized, so x5 (loaded from address 15) will read back 0.

module tb_program2;

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
        cpu_dut.cpu.IMEM[0] = 32'h00a00093; // addi x1, x0, 10
        cpu_dut.cpu.IMEM[1] = 32'h00500113; // addi x2, x0, 5
        cpu_dut.cpu.IMEM[2] = 32'h002081b3; // add  x3, x1, x2
        cpu_dut.cpu.IMEM[3] = 32'h40218233; // sub  x4, x3, x2
        cpu_dut.cpu.IMEM[4] = 32'h0001a283; // lw   x5, 0(x3)
        cpu_dut.cpu.IMEM[5] = 32'h00128333; // add  x6, x5, x1
        cpu_dut.cpu.IMEM[6] = 32'h00612023; // sw   x6, 0(x2)
    end

    initial begin
        rst = 1;
        #10 rst = 0;
        #90;

        error_count = 0;
        $display("---- Program 2 Results ----");
        $display("x1 = %0d (expected 10)", $signed(cpu_dut.cpu.rf.x[1]));
        $display("x2 = %0d (expected 5)",  $signed(cpu_dut.cpu.rf.x[2]));
        $display("x3 = %0d (expected 15)", $signed(cpu_dut.cpu.rf.x[3]));
        $display("x4 = %0d (expected 10)", $signed(cpu_dut.cpu.rf.x[4]));
        $display("x5 = %0d (expected 0)", $signed(cpu_dut.cpu.rf.x[5]));
        $display("x6 = %0d (expected 10)", $signed(cpu_dut.cpu.rf.x[6]));

        if ($signed(cpu_dut.cpu.rf.x[1]) !== 10) begin $display("ERROR: x1 expected 10, got %0d", $signed(cpu_dut.cpu.rf.x[1])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[2]) !== 5) begin $display("ERROR: x2 expected 5, got %0d", $signed(cpu_dut.cpu.rf.x[2])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[3]) !== 15) begin $display("ERROR: x3 expected 15, got %0d", $signed(cpu_dut.cpu.rf.x[3])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[4]) !== 10) begin $display("ERROR: x4 expected 10, got %0d", $signed(cpu_dut.cpu.rf.x[4])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[5]) !== 0) begin $display("ERROR: x5 expected 0, got %0d", $signed(cpu_dut.cpu.rf.x[5])); error_count = error_count + 1; end
        if ($signed(cpu_dut.cpu.rf.x[6]) !== 10) begin $display("ERROR: x6 expected 10, got %0d", $signed(cpu_dut.cpu.rf.x[6])); error_count = error_count + 1; end

        if (error_count == 0)
            $display("TEST PASSED");
        else
            $display("TEST FAILED: %0d mismatches", error_count);

        $finish;
    end

    initial begin
        $dumpfile("tb_program2.vcd");
        $dumpvars(0, tb_program2);
    end

endmodule
