# RV32I Single-Cycle CPU

A single-cycle RISC-V (RV32I) processor written in Verilog, with self-checking testbenches and a **one-command,
GUI-free regression flow** built on Xilinx Vivado's command-line simulator (`xsim`).

```
python scripts\run_sim.py
```

```
test                        result      time (s)
------------------------------------------------
tb_program1                 PASS             4.1
tb_program2                 PASS             3.9
tb_program3_fibonacci       PASS             4.3

3/3 passed
```

*(Example output. Times will vary.)*

---

## Overview

The design is a classic single-cycle RISC-V core: every instruction fetches, decodes, executes, accesses memory and
writes back within one clock cycle. The RTL is modular, with separate blocks for control, immediate generation,
the register file, the ALU and its sub-units, and byte-banked data memory.

The repository has two parts:

1. **The design** (`rtl/`) and its **testbenches** (`sim/`). Each testbench is pre-loaded with a machine-code
   program and checks the CPU's results itself.
2. **The automation** (`scripts/`). One command compiles the design, runs every testbench headlessly, reads the
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
| `python scripts\run_sim.py` | Run every testbench |
| `python scripts\run_sim.py --test tb_program1` | Run a single testbench |
| `python scripts\run_sim.py --wave` | Also save waveforms (`.wdb`) to `sim_out/` |
| `python scripts\run_sim.py --clean` | Delete `sim_out/` and rebuild from scratch |
| `python scripts\run_sim.py --timeout 300` | Allow 300 s per step (default 120) |

The script exits with code `0` if all tests pass and `1` otherwise, so it can be chained into other scripts or a CI job.

**New to terminals, Vivado's command line, or scripting?** Follow the step-by-step beginner's guide in
[`docs/GETTING_STARTED.md`](docs/GETTING_STARTED.md).

---

## How the flow works

`scripts/run_sim.py` automates what the Vivado GUI does behind the scenes:

1. **Compile**: `xvlog` reads every `.v` file in `rtl/` and `sim/`.
2. **Elaborate**: `xelab` builds a runnable simulation snapshot for one testbench.
3. **Simulate**: `xsim` runs it in batch mode and logs everything the testbench prints.
4. **Judge**: the script scans the log. `TEST PASSED` with no `TEST FAILED`, `FATAL` or `ERROR` means PASS.
   A run that exceeds the timeout is reported as `TIMEOUT`.
5. **Report**: a summary table, plus logs and optional waveforms in `sim_out/`.

Steps 2 to 4 repeat for each testbench; step 1 runs once.


## Repository structure

```
rtl/            CPU design (13 files)
sim/            testbenches and DUT wrapper
scripts/        run_sim.py (regression runner), timing.tcl (optional timing flow)
docs/           GETTING_STARTED.md (beginner's guide)
sim_out/        generated logs and waveforms (git-ignored)
```

### `rtl/`

| File | Role |
| ---- | ---- |
| `cpu_SC.v` | Top-level single-cycle datapath |
| `ControlUnit.v` | Decodes opcode/funct3/funct7 into control signals |
| `immGen.v` | Immediate generator (I/S/B/J formats) |
| `reg_file.v` | 32x32-bit register file (module name: `regfile`) |
| `decoder5to32.v` | 5-to-32 one-hot decoder used by the register file's write logic |
| `reg32.v` | Single 32-bit register (the register file instantiates 31 of these) |
| `bit32_32to1mux.v` | 32-to-1 register-read mux |
| `alu_ctrl.v` | Maps funct3/funct7 to a 3-bit ALU opcode |
| `rv32ialu.v` | The ALU |
| `aluaddsub.v`, `alucomp.v`, `alusltu.v` | ALU sub-units (add/sub, signed compare, unsigned compare) |
| `BankedMEM.v` | Byte-banked data memory (4x 1 KB banks) |

### `sim/`

| File | Role |
| ---- | ---- |
| `dut.v` | Top wrapper (`cpu_SC` instantiated as `cpu`) |
| `tb_program1.v` | Self-checking test program 1 |
| `tb_program2.v` | Self-checking test program 2 |
| `tb_program3_fibonacci.v` | Self-checking Fibonacci program |

The machine code for each program is pre-loaded inside its testbench.

---

## Timing analysis

The same batch approach works for static timing analysis: `scripts/timing.tcl` runs synthesis and implementation
without the GUI and writes timing and utilization reports to `sim_out_timing/`. 

```
vivado -mode batch -source scripts\timing.tcl -log sim_out\vivado.log -journal sim_out\vivado.jou
```

Setup (constraint file and FPGA part number) is described in
[`docs/GETTING_STARTED.md`](docs/GETTING_STARTED.md#12-optional-automate-the-timing-analysis).
Open `sim_out_timing/timing_summary.rpt` and check **WNS** (worst negative slack); a non-negative value means timing is met.
A sample report from the current RTL is in [`docs/results/timing_summary.rpt`](docs/results/timing_summary.rpt).

---

## Limitations

- **Pass/fail depends on the testbench.** The script trusts the verdict each testbench prints. A testbench that
  never reports a failure can hide a bug, which is the main motivation for the planned reference-model and
  assertion work below.
- **Hand-written test programs.** Coverage is limited to the cases written so far (three programs).
- **FPGA timing, not ASIC signoff.** Timing numbers come from Vivado on an FPGA target and are not comparable to
  ASIC synthesis or signoff results.

---

## Roadmap

- [ ] Run official RV32I test programs (for example from `riscv-tests` / `riscv-arch-test`) against the core, loaded
      from hex files so new tests need no Verilog changes
- [ ] Move test programs out of the testbenches into a `tests/` folder with a single generic testbench
- [ ] Compare the core against a reference model (for example Spike) instruction by instruction
- [ ] Random instruction-stream tests with reproducible seeds
- [ ] SystemVerilog assertions and functional coverage

