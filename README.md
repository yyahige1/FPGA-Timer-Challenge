# FPGA Timer Challenge

A parametric, synthesizable VHDL timer designed and verified as part of the FPGA Engineering Challenge.
The project includes RTL, testbenches, precision-analysis scripts, and a Yosys synthesis flow.

---

## 1. Overview

This project implements a configurable timer with:

- integer-based cycle computation
- minimal counter width
- synchronous logic with asynchronous reset
- rising-edge start detection
- full simulation and synthesis validation

Technologies used: VHDL-2008, VUnit, Yosys + GHDL, and custom analysis scripts.

---

## 2. Repository Structure

src/          → RTL (timer + synthesis wrapper) 
tb/           → VUnit testbench 
lab_test/     → precision & bit-width experiments 
scripts/      → Yosys synthesis scripts 
netlist/      → synthesized output 
run.py        → VUnit runner 
Makefile      → run, clean, synth targets 

---

## 3. RTL Summary

- Cycle computation uses natural integer arithmetic:
  - synthesizable
  - predictable
  - minimal counter width

- start_i is treated as a pulse input using an internal rising-edge detector.
- The design is synchronous with an asynchronous reset.
- done_o is asserted when idle or when the programmed delay expires.

---

## 4. Verification

### VUnit Testbench

The VUnit testbench validates:

- reset behavior
- start-pulse detection
- busy/done transitions
- correct cycle count
- async-reset recovery

### Lab Tests (lab_test/)

- tb_compare_div.sh: compare cycle-calculation methods (natural integer, floating point, time, unsigned 64).
- tb_test_width.sh: sweep frequency/delay combinations to verify optimal counter width.
- tb_time_to_calc.sh: verify rounding-up correctness of the natural integer implementation.

These experiments confirm that the natural-integer method is the only fully synthesizable and bit-width-optimal approach.

---

## 5. Synthesis Flow (Yosys)

Yosys cannot reliably pass VHDL generics via the command line, so a wrapper fixes the parameters.It acts as a configuration layer here:

- src/timer_wrapper.vhd

The main synthesis script is:

- scripts/synth_check.ys

Run synthesis with:

make synth

This elaborates the wrapper, runs Yosys synthesis, performs structural checks, and generates a Verilog netlist in netlist/synth_output_timer.v.

---

## 6. Next Steps

Planned improvements:

- parameter-sweep synthesis (multiple freq/delay combinations)
- boundary-case tests (rounding edges, exact multiples)
- large-delay stress tests (counter width growth)
- start-pulse and async-reset stress tests
- CI integration (simulation + synthesis)

---

## 7. AI Assistance

AI was used for documentation and edge-case exploration.
RTL decisions were validated through simulation and synthesis; only synthesizable constructs were kept. AI often suggests non synthesizable code.

