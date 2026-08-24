# rv32i-sc-cpu
Verilog Implementation of a RISC-V 32 bit ISA CPU, along with self checking testbenches. 

## Folder layout

```
rtl/        - the actual CPU design (Vivado Design Sources)
sim/        - ready-to-run testbenches (Simulation Sources)
```

### `rtl/` — the CPU 
| File | Role |
|---|---|
| `cpu_SC.v` | Top-level single-cycle datapath |
| `ControlUnit.v` | Decodes opcode/funct3/funct7 → control signals |
| `immGen.v` | Immediate generator (I/S/B/J formats) |
| `reg_file.v` | 32×32-bit register file (module name: `regfile`) |
| `decoder5to32.v` | 5-to-32 one-hot decoder used by the register file's write logic |
| `reg32.v` | Single 32-bit register (the register file instantiates 31 of these) |
| `bit32_32to1mux.v` | 32-to-1 register-read mux |
| `alu_ctrl.v` | Maps funct3/funct7 → 3-bit ALU opcode |
| `rv32ialu.v` | The ALU itself |
| `aluaddsub.v`, `alucomp.v`, `alusltu.v` | ALU sub-units (add/sub, signed compare, unsigned compare) |
| `BankedMEM.v` | Byte-banked data memory (4× 1KB banks) |
### `sim/`
- `dut.v` — top wrapper (`cpu_SC` instantiated as `cpu`)
- `tb_program1.v`, `tb_program2.v`, `tb_program3_fibonacci.v` — the three test programs, **pre-loaded with machine code** and self-checking.
### `constrs/`
- `timing.xdc` — 50 MHz clock constraint (`create_clock -period 20.000`) targeting a Zynq-7000 (`xc7z010iclg225-1L`)
### `reports/`
- `timing_summary.rpt` — Vivado static timing analysis summary; timing closed with 0 failing setup/hold endpoints
- `timing_top10.rpt` — top 10 worst-case paths; critical path (2.83 ns, through the PC increment carry-chain) yields a theoretical Fmax of ~350 MHz
---
