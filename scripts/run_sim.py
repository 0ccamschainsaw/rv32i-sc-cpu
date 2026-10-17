#!/usr/bin/env python3
"""
run_sim.py - run every RV32I testbench in Vivado's xsim WITHOUT opening the GUI.

Usage (from the repo root, in a terminal where Vivado's tools are on PATH):
    python scripts\\run_sim.py                  run all testbenches
    python scripts\\run_sim.py --test tb_program1
    python scripts\\run_sim.py --wave           also save waveforms (.wdb)
    python scripts\\run_sim.py --clean          delete sim_out/ first
    python scripts\\run_sim.py --timeout 300    seconds allowed per step

Exit code: 0 if every test passed, 1 otherwise.
"""
import argparse
import re
import shutil
import subprocess
import sys
import time
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent   # the repo folder
OUT = ROOT / "sim_out"                           # all generated files go here

# Names of the testbench MODULES (the word after "module" in each sim/tb_*.v file)
TESTS = ["tb_program1", "tb_program2", "tb_program3_fibonacci"]

# What the script looks for in a simulation's output
PASS_RE = re.compile(r"TEST PASSED")
FAIL_RE = re.compile(r"TEST FAILED|FATAL|\bERROR\b")


def tool(name):
    """Find a Vivado command (xvlog / xelab / xsim) on PATH, or stop with a hint."""
    path = shutil.which(name)  # on Windows this also finds xvlog.bat
    if not path:
        sys.exit(f"ERROR: '{name}' not found. Run Vivado's settings64.bat first "
                 f"(see README, Step 4).")
    return path


def run(cmd, logname, timeout):
    """Run a command inside sim_out/, save its output to a log file, return (code, text)."""
    result = subprocess.run(cmd, cwd=OUT, capture_output=True, text=True,
                            timeout=timeout)
    text = result.stdout + result.stderr
    (OUT / logname).write_text(text)
    return result.returncode, text


def main():
    ap = argparse.ArgumentParser(description="Run RV32I testbenches in Vivado xsim.")
    ap.add_argument("--test", help="run only this testbench module")
    ap.add_argument("--wave", action="store_true", help="save waveforms (.wdb)")
    ap.add_argument("--timeout", type=int, default=120,
                    help="seconds allowed per step (default 120)")
    ap.add_argument("--clean", action="store_true", help="delete sim_out/ first")
    args = ap.parse_args()

    if args.clean:
        shutil.rmtree(OUT, ignore_errors=True)
    OUT.mkdir(exist_ok=True)

    # 1) COMPILE every .v file in rtl/ and sim/
    sources = sorted((ROOT / "rtl").glob("*.v")) + sorted((ROOT / "sim").glob("*.v"))
    print(f"Compiling {len(sources)} Verilog files...")
    code, text = run([tool("xvlog")] + [str(p) for p in sources],
                     "compile.log", args.timeout)
    if code != 0 or "ERROR" in text:
        print(text)
        sys.exit("Compile failed. Details are in sim_out/compile.log")

    # 2) For each testbench: ELABORATE, then SIMULATE
    results = []
    for tb in ([args.test] if args.test else TESTS):
        print(f"Running {tb}...")
        start = time.time()
        snap = f"snap_{tb}"

        code, text = run([tool("xelab"), f"work.{tb}", "-s", snap, "--debug", "typical"],
                         f"{tb}_elab.log", args.timeout)
        if code != 0:
            results.append((tb, "ELAB FAIL", time.time() - start))
            continue

        # a tiny Tcl script that tells xsim what to do
        tcl = OUT / f"{tb}.tcl"
        tcl.write_text(("log_wave -r /*\n" if args.wave else "") + "run all\nquit\n")

        cmd = [tool("xsim"), snap, "-tclbatch", tcl.name, "-log", f"{tb}.log"]
        if args.wave:
            cmd += ["-wdb", f"{tb}.wdb"]
        try:
            code, text = run(cmd, f"{tb}_stdout.log", args.timeout)
            ok = PASS_RE.search(text) and not FAIL_RE.search(text)
            status = "PASS" if ok else "FAIL"
        except subprocess.TimeoutExpired:
            status = "TIMEOUT"
        results.append((tb, status, time.time() - start))

    # 3) SUMMARY
    print(f"\n{'test':<28}{'result':<12}{'time (s)':>8}")
    print("-" * 48)
    for tb, status, secs in results:
        print(f"{tb:<28}{status:<12}{secs:>8.1f}")
    failed = [r for r in results if r[1] != "PASS"]
    print(f"\n{len(results) - len(failed)}/{len(results)} passed")
    for tb, status, _ in failed:
        print(f"  -> look at sim_out/{tb}_stdout.log  ({status})")
    sys.exit(1 if failed else 0)


if __name__ == "__main__":
    main()
