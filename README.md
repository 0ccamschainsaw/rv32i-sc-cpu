# RV32I Single-Cycle CPU

A single-cycle RISC-V processor (a subset of RV32I, see [Supported instructions](#supported-instructions)) written in
Verilog, with self-checking tests and a **one-command, GUI-free regression flow** built on Xilinx Vivado's
command-line simulator (`xsim`).

```
python scripts\run_sim.py
```

```
test                        result      time (s)
------------------------------------------------
tb_program1                 PASS             8.9
tb_program2                 PASS             7.1
tb_program3_fibonacci       PASS             7.2
prog1                       PASS             4.9
prog2                       PASS             1.2
prog2_store                 PASS             1.2
prog3_fibonacci             PASS             1.2
prog4_loadstore             PASS             1.2
prog5_branches              PASS             1.2

9/9 passed
```

*(Example output. Times will vary.)*

---

## Overview

The design is a classic single-cycle RISC-V core: every instruction fetches, decodes, executes, accesses memory and
writes back within one clock cycle. The RTL is modular, with separate blocks for control, immediate generation,
the register file, the ALU and its sub-units, and byte-banked data memory.

The repository has three parts:

1. **The design** (`rtl/`).
2. **The tests**, in two styles:
   - **Legacy testbenches** (`sim/tb_program*.v`), each with its machine-code program hard-coded inside and loaded
     directly into instruction memory by a hierarchical reference.
   - **Hex-file tests** (`tests/`), where programs and expected results are plain data files. One generic testbench
     loads each program through the CPU's own instruction-memory write port, runs it, and checks the results.
3. **The automation** (`scripts/`). One command compiles the design, runs every test headlessly, reads the
   results, and reports PASS/FAIL with an exit code, so a change that breaks something is caught immediately
   instead of by eyeballing waveforms.

---

## Quick start

**Requirements**

- Xilinx Vivado with the `xsim` simulator, with its `bin` folder on PATH (run Vivado's `settings64.bat` or
  `settings64.sh` in your terminal first)
- run "D:\AMDDesignTools\2025.2\Vivado\settings64.bat" (just a placeholder, change accordingly)
- Python 3.8 or newer (standard library only, nothing to install)

**Run**

```
git clone https://github.com/0ccamschainsaw/rv32i-sc-cpu.git
cd rv32i-sc-cpu
python scripts\run_sim.py          # Linux/macOS: python3 scripts/run_sim.py
```

**Options**

| Command | What it does |
| ------- | ------------ |
| `python scripts\run_sim.py` | Run every test (legacy testbenches, then every `tests/*.hex`) |
| `python scripts\run_sim.py --test tb_program1` | Run a single legacy testbench |
| `python scripts\run_sim.py --test prog1` | Run a single hex test (name = file name without `.hex`) |
| `python scripts\run_sim.py --wave` | Also save waveforms (`.wdb`) to `sim_out/` |
| `python scripts\run_sim.py --clean` | Delete `sim_out/` and rebuild from scratch |
| `python scripts\run_sim.py --timeout 300` | Allow 300 s per step (default 120) |

The script exits with code `0` if every counted test passes and `1` otherwise, so it can be chained into other
scripts or a CI job.

**New to terminals, Vivado's command line, or scripting?** Follow the step-by-step beginner's guide in
[`docs/GETTING_STARTED.md`](docs/GETTING_STARTED.md).

---

## How the flow works

`scripts/run_sim.py` automates what the Vivado GUI does behind the scenes:

1. **Compile**: `xvlog` reads every `.v` file in `rtl/` and `sim/`.
2. **Elaborate**: `xelab` builds a runnable simulation snapshot, once per testbench module. The generic testbench
   is elaborated a single time and shared by every hex test.
3. **Simulate**: `xsim` runs it in batch mode and logs everything the testbench prints. For a hex test the script
   first copies that test's files to `sim_out/test.hex` and `sim_out/test.exp`, which the generic testbench reads.
4. **Judge**: the script scans the log. `TEST PASSED` with no `TEST FAILED`, `FATAL` or `ERROR` means PASS.
   A run that exceeds the timeout is reported as `TIMEOUT`.
5. **Report**: a summary table, plus logs and optional waveforms in `sim_out/`. Each failing test also has its
   first few `ERROR` lines printed under the table.

Step 1 runs once; steps 2 to 4 repeat for each test.

---

## Hex-file tests

A test is two files in `tests/` with the same name. Adding a test needs no Verilog and no script edits.

### How a hex test runs (`sim/tb_generic.v`)

1. Every instruction-memory word is first set to a NOP, so unused memory is never `X`.
2. `test.hex` is read over it.
3. With the CPU held in reset, the program is written word by word through the real write port
   (`imem_we` / `imem_waddr` / `imem_wdata`, exposed by `sim/dut_ld.v`). This is the same path hardware would use.
4. Reset is released and the CPU runs until the program counter stops changing, or `5000` cycles pass (a failure).
5. The results are compared against `test.exp`. A test whose `.exp` file contains no checks fails, so a test
   cannot pass without checking anything.

### `<name>.hex`: the program

One 32-bit hex word per line (`$readmemh` format); `//` comments are allowed. **A program must end with a halt
loop**, `jal x0, 0` (`0000006f`), which is how the testbench knows the program has finished.

```
00a00093 // addi x1, x0, 10
01400113 // addi x2, x0, 20
0000006f // jal  x0, 0   (halt)
```

### `<name>.exp`: the expected results

One check per line; blank lines and `#` comments are ignored.

```
r 1 0000000a      # register x1 must equal 0x0000000a
m 4 0000002a      # data-memory word 4 (byte address 16) must equal 0x0000002a
```

| Kind | Meaning |
| ---- | ------- |
| `r <0..31> <hex>` | register file entry `x<n>` |
| `m <0..1023> <hex>` | data-memory word `n` (byte address `4*n`) |

### Known-failure tests

A test whose name starts with `xfail_` is a **known failure**. It is reported as `XFAIL` and does not affect the
exit code. If it unexpectedly passes it is reported as `XPASS` and counts as a failure, which is the prompt to
rename it and promote it to a normal test. `XFAIL` requires the testbench itself to report `TEST FAILED`; a
tool crash is reported as `FAIL`.

### Current tests

| Test | Kind | What it checks |
| ---- | ---- | -------------- |
| `tb_program1` / `prog1` | legacy / hex | arithmetic: `addi`, `xori`, `add`, `sub` (including a negative result) |
| `tb_program2` / `prog2` | legacy / hex | register dataflow including `lw`, `add`, `sw` (registers only) |
| `prog2_store` | hex | the `sw` from program 2 actually lands at the right data-memory word |
| `tb_program3_fibonacci` / `prog3_fibonacci` | legacy / hex | a loop closed by `bne` |

The hex tests `prog1`, `prog2` and `prog3_fibonacci` run the same three programs as the legacy testbenches (with a
halt instruction appended), so they can be compared directly.

## Repository structure

```
rtl/            CPU design (13 files)
sim/            legacy testbenches, generic hex-file testbench, DUT wrappers
tests/          hex-file tests: <name>.hex (program) + <name>.exp (expected results)
scripts/        run_sim.py (regression runner), timing.tcl (optional timing flow)
constraints/    clk.xdc (20 ns / 50 MHz clock constraint used by timing.tcl)
docs/           GETTING_STARTED.md (beginner's guide), results/ (sample timing report)
sim_out/        generated logs and waveforms (git-ignored)
```

### `rtl/`

| File | Role |
| ---- | ---- |
| `cpu_SC.v` | Top-level single-cycle datapath, including the 256-word instruction memory and its write port |
| `ControlUnit.v` | Decodes opcode/funct3/funct7 into control signals |
| `immGen.v` | Immediate generator (I/S/B/J formats) |
| `reg_file.v` | 32x32-bit register file (module name: `regfile`) |
| `decoder5to32.v` | 5-to-32 one-hot decoder used by the register file's write logic |
| `reg32.v` | Single 32-bit register (the register file instantiates 31 of these) |
| `bit32_32to1mux.v` | 32-to-1 register-read mux |
| `alu_ctrl.v` | Maps funct3/funct7 to a 3-bit ALU opcode; `force_add` / `force_sub` override it for loads/stores and branches |
| `rv32ialu.v` | The ALU |
| `aluaddsub.v`, `alucomp.v`, `alusltu.v` | ALU sub-units (add/sub, signed compare, unsigned compare) |
| `BankedMEM.v` | Byte-banked data memory (4x 1 KB banks) |

### `sim/`

| File | Role |
| ---- | ---- |
| `dut.v` | Wrapper used by the legacy testbenches (`cpu_SC` instantiated as `cpu`); ties the instruction-memory write port off |
| `dut_ld.v` | Wrapper that exposes the instruction-memory write port and `debug_pc`; used by the generic testbench |
| `tb_generic.v` | File-driven testbench: loads `test.hex` through the write port and checks `test.exp` |
| `tb_program1.v` | Legacy self-checking test program 1 |
| `tb_program2.v` | Legacy self-checking test program 2 |
| `tb_program3_fibonacci.v` | Legacy self-checking Fibonacci program |

The legacy testbenches pre-load their machine code by writing `cpu_dut.cpu.IMEM[i]` hierarchically. That is a
simulation-only shortcut and is not synthesizable; the hex-file tests use the real write port instead.

### Instruction memory

`IMEM` is a 256-word array inside `cpu_SC` with an asynchronous read and a synchronous write port. Vivado maps it
to distributed RAM. It has no initial contents in the RTL, so on hardware a program must be written in through the
write port while the CPU is held in reset.

---

## Supported instructions

The core implements a **subset of RV32I**. The test programs exercise `addi`, `xori`, `add`, `sub`, `lw`, `sw`,
`beq`, `bne`, and `jal` (as a halt loop). The ALU control also decodes the `and`, `or`, `sll`, `slt` operations,
which are not covered by a dedicated test yet.

Not implemented: `lui`, `auipc`, `jalr`, byte and halfword loads and stores, the remaining branches (`blt`, `bge`,
`bltu`, `bgeu`), `sltu`, and the right shifts. The data memory is word-access only, and the low two address bits are
ignored.

---

## Timing analysis

The same batch approach works for static timing analysis: `scripts/timing.tcl` runs synthesis and implementation
without the GUI and writes timing and utilization reports to `sim_out_timing/`. It reads `rtl/*.v` and
`constraints/clk.xdc`.

```
vivado -mode batch -source scripts\timing.tcl -log sim_out\vivado.log -journal sim_out\vivado.jou
```

Setup (constraint file and FPGA part number) is described in
[`docs/GETTING_STARTED.md`](docs/GETTING_STARTED.md#12-optional-automate-the-timing-analysis).
Open `sim_out_timing/timing_summary.rpt` and check **WNS** (worst negative slack); a non-negative value means timing is met.
`sim_out_timing/critical_path.rpt` shows the single worst path. A sample report is in
[`docs/results/timing_summary.rpt`](docs/results/timing_summary.rpt); regenerate it after any RTL change.

The design is synthesized out-of-context, so the I/O ports carry no input or output delay constraints. The numbers
describe paths inside the core only (register to register), not chip-level timing. The `#N` delays in the RTL are
simulation-only and are ignored by synthesis, so they do not affect these results.

---

## Limitations

- **Pass/fail depends on the test.** The script trusts the verdict each test prints. A hex test checks only the
  registers and memory words listed in its `.exp` file, and a legacy testbench checks only what it was written
  to check. The extra tests above exist because the first three programs missed real bugs.
- **Small test suite.** Nine tests (three legacy, six hex) covering a subset of the ISA.
- **Subset of RV32I.** See [Supported instructions](#supported-instructions).
- **Tested on Vivado `xsim` only.** The RTL puts `#N` propagation delays inside combinational logic. Synthesis
  ignores them, but in simulation they make results depend on event ordering, so another simulator (for example
  Icarus Verilog) may not give the same results. Removing them is on the roadmap.
- **Observation by hierarchy.** The generic testbench reads registers and data memory through hierarchical
  references (`u.cpu.rf.x[i]`, `u.cpu.dmem.b0[i]`). Programs enter through the real write port, but results are
  not read out through a hardware interface.
- **Programs must halt.** A hex test finishes when the PC stops changing, so every program must end in `jal x0, 0`.
- **FPGA timing, not ASIC signoff.** Timing numbers come from Vivado on an FPGA target and are not comparable to
  ASIC synthesis or signoff results.

---

## Roadmap

- [ ] Run official RV32I test programs (for example from `riscv-tests` / `riscv-arch-test`) against the core, loaded
      from hex files (the hex-file loader is in place; the remaining work is converting the official tests and
      implementing the instructions they need)
- [x] Move test programs out of the testbenches into a `tests/` folder with a single generic testbench
      (done for hex tests; the three legacy testbenches are kept alongside them)
- [ ] Implement the missing instructions: `lui`, `auipc`, `jalr`, byte/halfword loads and stores, `blt`/`bge`/`bltu`/`bgeu`,
      `sltu`, right shifts
- [ ] Remove the `#N` delays from the RTL so simulation does not depend on event ordering
- [ ] Compare the core against a reference model (for example Spike) instruction by instruction
- [ ] Random instruction-stream tests with reproducible seeds
- [ ] SystemVerilog assertions and functional coverage
