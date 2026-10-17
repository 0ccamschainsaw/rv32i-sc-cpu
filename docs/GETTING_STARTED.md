# Getting started: the GUI-free simulation flow (complete beginner's guide)


This guide assumes you have **never used a terminal, bash, or a script before**. Every step says exactly what
to click or type. Follow the steps in order.

**Goal:** instead of opening Vivado, creating a project, clicking "Run Simulation" and reading waveforms by hand,
you type **one command** and the computer runs all three testbenches and tells you PASS or FAIL.

**Do I need Linux?** No. Everything here works on Windows. (If you are on Linux anyway, see the note in Step 4.)

## Contents

0. [Words you need to know](#0-words-you-need-to-know)
1. [What you need installed](#1-what-you-need-installed)
2. [Get the project onto your computer](#2-get-the-project-onto-your-computer)
3. [Open a terminal inside the project folder](#3-open-a-terminal-inside-the-project-folder)
4. [Tell the terminal where Vivado is](#4-tell-the-terminal-where-vivado-is)
5. [Check that everything works](#5-check-that-everything-works)
6. [Make your testbenches print PASS or FAIL](#6-make-your-testbenches-print-pass-or-fail)
7. [Add the script to the project](#7-add-the-script-to-the-project)
8. [Run it](#8-run-it)
9. [Understand the results](#9-understand-the-results)
10. [Useful options](#10-useful-options)
11. [Look at a waveform](#11-look-at-a-waveform-only-when-you-need-to)
12. [Optional: automate timing analysis](#12-optional-automate-the-timing-analysis)
13. [Save your work to GitHub](#13-save-your-work-to-github)
14. [Troubleshooting](#14-troubleshooting)
15. [Command cheat sheet](#15-command-cheat-sheet)

---

## 0. Words you need to know

| Word | Plain meaning |
| ---- | ------------- |
| **Terminal** (or "command prompt") | A window where you control the computer by typing text commands instead of clicking. |
| **Command** | One line of text you type, then press **Enter** to run. |
| **Folder / directory** | Same thing. The terminal always sits "inside" one folder, called the *current folder*. |
| **Path** | The address of a file or folder, like `C:\Users\you\rv32i-sc-cpu\rtl`. |
| **`cd`** | "Change directory": move the terminal into another folder. |
| **Script** | A text file containing instructions the computer runs for you. Ours is `run_sim.py`. |
| **Python** | The program that reads and runs `.py` script files. |
| **PATH** | A list of folders the terminal searches when you type a command name. If Vivado's folder is not on PATH, the terminal says it "is not recognized". Step 4 fixes this. |
| **xvlog / xelab / xsim** | Vivado's three command-line tools: *compile* Verilog, *elaborate* (connect the design together), *simulate*. The script runs these for you. |
| **Testbench** | A Verilog file that feeds a program to your CPU and checks the results. |
| **Regression** | Running *all* your tests every time, so you notice immediately if a change broke something. |

**Typing tip:** when this guide shows a grey code box, type exactly what is inside, then press **Enter**.
Do not type the `>` symbol if you see one; it just shows the terminal is waiting for you.

---

## 1. What you need installed

1. **Windows 10 or 11.**
2. **Vivado** (any recent version, including the free WebPACK/Standard edition). You already use it for this project, so it is probably installed.
3. **Python 3.8 or newer.** Check whether you already have it:
   - Press the **Windows key**, type `cmd`, press **Enter**. A black window opens. That is the terminal.
   - Type `python --version` and press **Enter**.
   - If it prints something like `Python 3.12.1`, you are done.
   - If it says *"Python was not found"* or opens the Microsoft Store: go to <https://www.python.org/downloads/>, download the installer, run it, and **tick the box "Add python.exe to PATH" on the first screen** before clicking Install. Then close the terminal and open a new one.

You do **not** need to install anything else. No extra libraries.

---

## 2. Get the project onto your computer

If you already have this repo in a folder on your computer, skip to Step 3.

**Option A (no extra software):**
1. Open <https://github.com/0ccamschainsaw/rv32i-sc-cpu> in your browser.
2. Click the green **Code** button, then **Download ZIP**.
3. Right-click the ZIP, choose **Extract All**, and put it somewhere simple like `C:\projects\rv32i-sc-cpu`.

**Option B (if you have Git installed):** in a terminal, type:
```
git clone https://github.com/0ccamschainsaw/rv32i-sc-cpu.git
```

> **Important:** avoid spaces in the folder path. `C:\projects\rv32i-sc-cpu` is good.
> `C:\My Projects\rv32i sc cpu` can cause confusing errors with Vivado's tools.

---

## 3. Open a terminal inside the project folder

1. Open **File Explorer** and go into the project folder, so you can see the `rtl` and `sim` folders.
2. Click once on the **address bar** at the top (where the folder path is shown). The path turns blue/highlighted.
3. Type `cmd` and press **Enter**.

A black terminal window opens, already inside your project folder. The text on the last line should end with the project folder, for example:

```
C:\projects\rv32i-sc-cpu>
```

To double-check, type `dir` and press **Enter**. It lists the folder's contents. You should see `rtl`, `sim` and `README.md`.

> Use **Command Prompt (cmd)**, not PowerShell. The Vivado setup file in Step 4 is built for Command Prompt.

---

## 4. Tell the terminal where Vivado is

Vivado includes a setup file named `settings64.bat`. Running it teaches the terminal where `xvlog`, `xelab` and `xsim` live.

**4a. Find the file.** Common locations (the version number will match yours):

```
C:\Xilinx\Vivado\2023.2\settings64.bat
C:\Xilinx\Vivado\2024.1\settings64.bat
```

Not there? Open File Explorer, click `This PC`, and search for `settings64.bat`. Or press the Windows key, type `Vivado`, right-click the Vivado app, choose **Open file location**, and look around nearby for a `Vivado` folder containing a version number.

**4b. Run it.** In your terminal, type the full path **inside double quotes** and press Enter. Example:

```
"C:\Xilinx\Vivado\2023.2\settings64.bat"
```

Nothing visible happens. That is normal.

> **You must repeat 4b every time you open a new terminal window.** It only lasts as long as that window is open.
> If you hate repeating it, see "Make it permanent" below.

**Make it permanent (optional):**
1. Press the Windows key, type `environment variables`, open **Edit the system environment variables**.
2. Click **Environment Variables**. Under *User variables*, select **Path**, click **Edit**.
3. Click **New** and paste Vivado's `bin` folder, for example `C:\Xilinx\Vivado\2023.2\bin`. Click OK on every window.
4. Close and reopen your terminal.

**Linux users:** instead of `settings64.bat`, run `source /tools/Xilinx/Vivado/<version>/settings64.sh`, and use `python3` and forward slashes (`scripts/run_sim.py`) everywhere below.

---

## 5. Check that everything works

In the same terminal, type each line and press Enter:

```
xvlog --version
```
You should see text mentioning *Vivado Simulator* and a version number.

```
python --version
```
You should see `Python 3.x.x`.

If either says **"is not recognized as an internal or external command"**, go to [Troubleshooting](#14-troubleshooting).

---

## 6. Make your testbenches print PASS or FAIL

The script decides whether a test passed by reading what the testbench prints. So each testbench must print a clear
final line and then stop.

**6a. Open each testbench** (`sim\tb_program1.v`, `sim\tb_program2.v`, `sim\tb_program3_fibonacci.v`) in Notepad, VS Code, or Vivado's editor.

**6b. Find the end of the test.** Near the bottom, where the testbench checks results and finishes, make sure it looks like this (your variable names will differ):

```verilog
if (error_count == 0)
    $display("TEST PASSED");
else
    $display("TEST FAILED: %0d mismatches", error_count);

$finish;
```

Things to check:

- The words **`TEST PASSED`** (exactly, capital letters) are printed only when everything is correct.
- On a problem, the testbench prints **`TEST FAILED`** (or anything containing `ERROR` in capitals).
- The testbench ends with **`$finish;`**. Without it, the simulation never ends and the script reports `TIMEOUT`.
- Normal progress messages must **not** contain `TEST FAILED`, `FATAL`, or the capitalised word `ERROR`. (A message like `Errors: 0` is fine because it is not all capitals.)

**6c. Find each testbench's module name.** In each file, find the line starting with `module`, for example:

```verilog
module tb_program1;
```

The word after `module` is the module name. Write down all three. They must match the `TESTS` list inside `run_sim.py` in Step 7. If your names differ (for example `tb_program3` instead of `tb_program3_fibonacci`), you will fix the list in Step 7.

---

## 7. Add the script to the project

**7a. Create a `scripts` folder.** In the terminal:

```
mkdir scripts
```

(Or right-click in File Explorer, **New**, **Folder**, name it `scripts`.)

**7b. Put `run_sim.py` inside it.** Copy the provided `run_sim.py` file into the new `scripts` folder.
If you are creating it by hand with Notepad, make sure the file is saved as `run_sim.py` and not `run_sim.py.txt`:
in File Explorer, click **View**, then **Show**, then tick **File name extensions** so you can see the real name.

**7c. Check the testbench names.** Open `scripts\run_sim.py` in Notepad or VS Code. Near the top, find:

```python
TESTS = ["tb_program1", "tb_program2", "tb_program3_fibonacci"]
```

Make this list match the three module names you wrote down in Step 6c. Keep the quotes and commas. Save the file.

**7d. Tell git to ignore generated files.** Create (or open) a file named `.gitignore` in the project folder and add this line:

```
sim_out/
```

**Your folder should now look like this:**

```
rv32i-sc-cpu/
    rtl/            (13 files)
    sim/            (4 files)
    scripts/
        run_sim.py
    .gitignore
    README.md
```

---

## 8. Run it

Make sure your terminal is **in the project folder** (Step 3) and that you ran `settings64.bat` in this terminal window (Step 4). Then type:

```
python scripts\run_sim.py
```

and press **Enter**. Wait 10 to 60 seconds. You will see progress lines, then a table.

A healthy run looks like:

```
Compiling 17 Verilog files...
Running tb_program1...
Running tb_program2...
Running tb_program3_fibonacci...

test                        result      time (s)
------------------------------------------------
tb_program1                 PASS             4.1
tb_program2                 PASS             3.9
tb_program3_fibonacci       PASS             4.3

3/3 passed
```

That is it. You just ran a full regression without opening Vivado.

---

## 9. Understand the results

| Result | Meaning | What to do |
| ------ | ------- | ---------- |
| `PASS` | The testbench printed `TEST PASSED` and nothing bad. | Nothing. |
| `FAIL` | The testbench printed `TEST FAILED` / `ERROR`, **or** never printed `TEST PASSED`. | Open `sim_out\<testbench>_stdout.log` and read the last lines. |
| `TIMEOUT` | The simulation did not finish in time (default 120 seconds). | The testbench probably lacks `$finish`, or the CPU is stuck in an infinite loop. |
| `ELAB FAIL` | The design compiled but could not be assembled for simulation. | Open `sim_out\<testbench>_elab.log`. Often a wrong module name. |
| "Compile failed" | A Verilog syntax error or missing file. | Open `sim_out\compile.log`. The first `ERROR` line names the file and line number. |

The script also exits with a code (0 = all passed, 1 = something failed). You will not see it, but it lets other
scripts, and later automation such as a CI job, react to your results automatically.

**Where are the logs?** In the `sim_out` folder, which the script creates. Open the `.log` files with Notepad.

---

## 10. Useful options

Add these after the command, separated by spaces.

| Command | What it does |
| ------- | ------------ |
| `python scripts\run_sim.py --test tb_program1` | Run only one testbench. |
| `python scripts\run_sim.py --wave` | Also save waveform files (`.wdb`) in `sim_out`. |
| `python scripts\run_sim.py --clean` | Delete `sim_out` first and rebuild everything from scratch. |
| `python scripts\run_sim.py --timeout 300` | Allow 300 seconds per step instead of 120. |
| `python scripts\run_sim.py --test tb_program3_fibonacci --wave` | Combine options. |

---

## 11. Look at a waveform (only when you need to)

1. Run with waveforms: `python scripts\run_sim.py --test tb_program1 --wave`
2. Open the saved waveform with:
   ```
   xsim -gui sim_out\tb_program1.wdb
   ```
   Or open the Vivado GUI and choose **File, Open Waveform Database** and pick the `.wdb` file.

Normally you never need this. You only open waveforms to investigate a `FAIL`.

---

## 12. Optional: automate the timing analysis

This reproduces your static timing analysis (for example the 50 MHz result) with one command, still without the GUI.

**12a. Create `constraints\clk50.xdc`.** Make a folder named `constraints` and a text file `clk50.xdc` inside with:

```
create_clock -period 20.000 -name clk [get_ports clk]
```

Replace `clk` with your CPU's actual clock input name. Open `rtl\cpu_SC.v` and look at the module's port list.
A period of 20 ns equals 50 MHz.

**12b. Create `scripts\timing.tcl`** with:

```tcl
# Batch synthesis + implementation + timing report (no GUI)
file mkdir sim_out
read_verilog [glob rtl/*.v]
read_xdc constraints/clk50.xdc

# Replace the part with the FPGA part from your original Vivado project
synth_design -top cpu_SC -part xc7z020clg400-1 -mode out_of_context
opt_design
place_design
route_design

report_timing_summary -file sim_out/timing_summary.rpt
report_utilization    -file sim_out/utilization.rpt
```

To find your real part name: open your old Vivado project, then **Tools, Project Settings, General**, and read the *Device* / *Part* field.

**12c. Run it** (same terminal rules as before):

```
vivado -mode batch -source scripts\timing.tcl -log sim_out\vivado.log -journal sim_out\vivado.jou
```

**12d. Read the result.** Open `sim_out\timing_summary.rpt` and search for **WNS** (worst negative slack).
A positive WNS means timing is met. Only list this on your resume once it runs successfully for you.

---

## 13. Save your work to GitHub

In the terminal, inside the project folder:

```
git status
```
Shows which files changed. Then:

```
git add .
git commit -m "Add GUI-free Vivado simulation regression script"
git push
```

`git add .` stages every changed file, `git commit` saves a snapshot with your message, and `git push` uploads it to GitHub.
Check that `sim_out/` does **not** appear in what you uploaded. That is what `.gitignore` is for.

---

## 14. Troubleshooting

**`'python' is not recognized...`**
Python is not installed or not on PATH. Reinstall from python.org and tick **Add python.exe to PATH**. Open a new terminal afterwards.

**`'xvlog' is not recognized...` or the script says `'xvlog' not found`**
You did not run `settings64.bat` in *this* terminal window. Redo Step 4b (or the permanent PATH fix).

**`The system cannot find the path specified` when running settings64.bat**
The path you typed is wrong. Recheck the Vivado version number and keep the double quotes.

**`python: can't open file ... scripts\run_sim.py`**
Your terminal is not in the project folder. Type `dir`. If you do not see `scripts`, `rtl` and `sim`, redo Step 3. Another cause: the file is named `run_sim.py.txt`. See Step 7b.

**`Compile failed`**
Open `sim_out\compile.log` in Notepad and find the first line starting with `ERROR`. It names the file and line.
Common causes: a typo in Verilog, a module used but not included, or two files defining the same module name.

**`ELAB FAIL`**
Open `sim_out\<name>_elab.log`. The most common cause is that the name in the `TESTS` list does not exactly match the `module` name in the testbench (Step 6c and 7c). Capitalisation matters.
If the log mentions a *timescale*, add the line `` `timescale 1ns/1ps `` at the top of any file that does not have one.

**Everything prints `FAIL` but the testbench works fine in Vivado**
The script cannot see `TEST PASSED`. Open `sim_out\<name>_stdout.log` and check the last lines. Fix Step 6 so the testbench prints exactly `TEST PASSED`.

**Everything prints `TIMEOUT`**
The testbench never ends. Add `$finish;` (Step 6). If a test is legitimately slow, use `--timeout 300`.
After a timeout, open **Task Manager** (Ctrl+Shift+Esc) and end any leftover `xsim` processes.

**Weird errors with the folder path**
Move the project to a path with no spaces, like `C:\projects\rv32i-sc-cpu`.

**Still stuck?**
Run with `--clean` to rebuild from scratch: `python scripts\run_sim.py --clean`. If it still fails, copy the full terminal output into a message and ask for help.

---

## 15. Command cheat sheet

Every time you want to run the tests:

```
1. Open the project folder in File Explorer
2. Click the address bar, type cmd, press Enter
3. "C:\Xilinx\Vivado\2023.2\settings64.bat"     <- use your path
4. python scripts\run_sim.py
```

| Command | Meaning |
| ------- | ------- |
| `dir` | List files in the current folder |
| `cd folder` | Go into a folder |
| `cd ..` | Go up one folder |
| `mkdir name` | Make a new folder |
| `cls` | Clear the screen |
| Up arrow | Bring back the previous command |
| Tab | Auto-complete a file or folder name |
| Ctrl+C | Stop a running command |

---

## How it works (for the curious)

`run_sim.py` automates what the Vivado GUI does behind the scenes:

1. **Compile.** `xvlog` reads every `.v` file in `rtl/` and `sim/` and checks the syntax.
2. **Elaborate.** `xelab` takes one testbench as the top module and connects the whole design into a runnable *snapshot*.
3. **Simulate.** `xsim` runs the snapshot (`run all`) and writes everything the testbench prints into a log.
4. **Judge.** Python reads the log: `TEST PASSED` with no `TEST FAILED`/`FATAL`/`ERROR` means PASS.
5. **Report.** It prints a table and exits with code 0 (all passed) or 1 (something failed).

Steps 2 to 4 repeat for each testbench; step 1 runs once.