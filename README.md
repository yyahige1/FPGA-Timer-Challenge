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


## Testing

The testbench contains **15 comprehensive tests** covering:
- Basic functionality and timing
- Reset behavior (async reset, edge cases)
- Start pulse handling and rejection
- Stress testing and continuous operation
- Edge cases and signal conflicts

**See [tb/guide.md](tb/guide.md) for detailed test documentation.**

## Test Results

All tests should pass:
```
pass 15 of 15
Total time was 4.4 seconds
All passed!
```
## Multi-Configuration Testing

Test the timer across 9 frequency/delay combinations:

```bash
make sweep         # Run full sweep + report
make sweep-report  # View results
make clean-sweep   # Remove logs
```

**Configurations tested:**
- 10 MHz → 1 GHz clock frequencies
- 10 ns → 10 µs delay periods 


Logs saved to `sweep_logs/
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

## Synthesis Sweep

Verify the design synthesizes across all configurations:

```bash
make synth-sweep    # Synthesize all 9 configs
make clean-synth    # Remove synthesis outputs
```

**Output:**
- Logs: `synth_logs/<config>.log`
- Netlists: `netlist/synth_<config>.v`

All configurations use a wrapper with fixed generics (workaround for GHDL's inability to pass `time` generics).
---

## 6. Next Steps

## Planned Improvements

### 
### CI/CD Integrationn
### Documentation

## Current Limitations

### VHDL `time` Generic Issue
The timer uses a `time` type generic (`delay_g : time`) which cannot be passed via command line to GHDL:

```vhdl
-- This doesn't work:
ghdl -gdelay_g=1us timer.vhd  -- GHDL ignores time generics
```

**Current Workarounds:**

1. **For Testing**: Constants in testbench that are modified via scripts
   ```vhdl
   constant TB_DELAY : time := 1 us;  -- Changed by sed/bash
   ```

2. **For Synthesis**: Wrapper module with hardcoded generics
   ```vhdl
   constant DELAY_C : time := 1 us;  -- Regenerated per config
   ```

**Sweep Strategy:**
- Script-based approach (bash/Python) to modify source files
- Run simulation/synthesis for each configuration
- Aggregate and analyze results
- Trade-off: Less elegant than pure VUnit, but necessary with `time` generics

---

## 7. AI Assistance

AI was used for documentation and edge-case exploration.
RTL decisions were validated through simulation and synthesis; only synthesizable constructs were kept. AI often suggests non synthesizable code.

