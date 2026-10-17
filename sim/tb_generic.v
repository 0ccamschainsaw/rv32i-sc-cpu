`timescale 1ns/1ps
//
// Generic, file-driven testbench.  One testbench runs ANY program:
//
//   test.hex        program, one 32-bit hex word per line ($readmemh format)
//   test.exp        expected results (see below)
//                   (both read from the simulator's working directory; run_sim.py
//                    copies them there. +HEX=<file> / +EXP=<file> override the names)
//   +MAXCYC=<n>     give up if the program has not halted after n cycles (default 5000)
//
// Flow:  hold reset -> load program through the CPU's write port (front door)
//        -> release reset -> run until the program halts -> check results.
//
// A program halts by ending in a self-loop:  jal x0, 0  (0x0000006f).
// The testbench sees the PC stop changing and moves on to checking.
//
// Expected-results file, one check per line ('#' lines and blank lines ignored):
//     r <reg 0..31>    <hex value>     check register file entry  x<reg>
//     m <word 0..1023> <hex value>     check data-memory word (byte address = 4*word)
//
module tb_generic;

    reg         clk = 0;
    reg         rst = 1;
    reg         imem_we = 0;
    reg  [7:0]  imem_waddr = 0;
    reg  [31:0] imem_wdata = 0;
    wire [31:0] pc;

    dut_ld u(
        .clk(clk), .rst(rst),
        .imem_we(imem_we), .imem_waddr(imem_waddr), .imem_wdata(imem_wdata),
        .debug_pc(pc)
    );

    always #5 clk = ~clk;

    reg [31:0]       prog [0:255];
    reg [8*256-1:0]  hexfile;
    reg [8*256-1:0]  expfile;
    reg [8*256-1:0]  line;
    reg [8*8-1:0]    kind;
    integer          maxcyc, fd, n, idx, i;
    reg  [31:0]      val, got, last_pc;
    integer          cyc, same, errors, checks;

    // Write every IMEM word through the real write port: one word per clock.
    // Inputs change on the falling edge so they are stable at the rising edge.
    task load_program;
        integer k;
        begin
            for (k = 0; k < 256; k = k + 1) begin
                @(negedge clk);
                imem_we    = 1;
                imem_waddr = k[7:0];
                imem_wdata = prog[k];
            end
            @(negedge clk);       // last word was captured on the edge just passed
            imem_we = 0;
        end
    endtask

    initial begin
        errors = 0; checks = 0;

        // run_sim.py copies the current test to test.hex / test.exp in the
        // simulator's working directory; +HEX= / +EXP= override that for manual runs.
        if (!$value$plusargs("HEX=%s", hexfile)) hexfile = "test.hex";
        if (!$value$plusargs("EXP=%s", expfile)) expfile = "test.exp";
        if (!$value$plusargs("MAXCYC=%d", maxcyc)) maxcyc = 5000;

        // Unused memory = NOP (addi x0,x0,0), never X
        for (i = 0; i < 256; i = i + 1) prog[i] = 32'h00000013;
        $readmemh(hexfile, prog);

        // ---- load through the front door, CPU held in reset ----
        rst = 1;
        load_program;
        @(negedge clk);
        rst = 0;

        // ---- run until the PC stops moving (halt self-loop) ----
        last_pc = 32'hFFFFFFFF; same = 0; cyc = 0;
        while (same < 3 && cyc < maxcyc) begin
            @(posedge clk); #1;
            if (pc === last_pc) same = same + 1; else same = 0;
            last_pc = pc;
            cyc = cyc + 1;
        end
        if (same < 3) begin
            $display("ERROR: program did not halt within %0d cycles (pc=%0h)", maxcyc, pc);
            errors = errors + 1;
        end

        // ---- compare against the expected-results file ----
        fd = $fopen(expfile, "r");
        if (fd == 0) begin
            $display("ERROR: cannot open expected-results file");
            errors = errors + 1;
        end else begin
            while ($fgets(line, fd) != 0) begin
                n = $sscanf(line, "%s %d %h", kind, idx, val);
                if (n == 3 && kind == "r") begin
                    got = u.cpu.rf.x[idx];
                    checks = checks + 1;
                    if (got !== val) begin
                        $display("ERROR: x%0d expected %0h, got %0h", idx, val, got);
                        errors = errors + 1;
                    end else
                        $display("x%0d = %0h ok", idx, got);
                end else if (n == 3 && kind == "m") begin
                    got = {u.cpu.dmem.b3[idx], u.cpu.dmem.b2[idx],
                           u.cpu.dmem.b1[idx], u.cpu.dmem.b0[idx]};
                    checks = checks + 1;
                    if (got !== val) begin
                        $display("ERROR: mem[word %0d] expected %0h, got %0h", idx, val, got);
                        errors = errors + 1;
                    end else
                        $display("mem[word %0d] = %0h ok", idx, got);
                end
            end
            $fclose(fd);
        end

        // A test with no checks would "pass" vacuously, so refuse that.
        if (checks == 0) begin
            $display("ERROR: expected-results file contained no checks");
            errors = errors + 1;
        end

        $display("cycles run: %0d, checks: %0d", cyc, checks);
        if (errors == 0) $display("TEST PASSED");
        else             $display("TEST FAILED: %0d mismatches", errors);
        $finish;
    end

endmodule
