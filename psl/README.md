# PSL Formal Verification

Formal verification of the parametric VHDL timer using **PSL (Property Specification Language)** with **GHDL + SymbiYosys** from the OSS CAD Suite.

## Overview

This directory contains formal verification infrastructure that mathematically proves the timer behaves correctly for all possible inputs and states—not just the test cases we thought of.

### Key Property Proven

> **When the timer reaches its maximum count, `done_o` is asserted on the next clock cycle.**

This guarantees the timer always completes after exactly the calculated number of cycles.

## Quick Start

```bash
# Ensure OSS CAD Suite is active
source /path/to/oss-cad-suite/environment

# Run bounded model checking
make bmc

# Run all verification modes
make all
```

## File Structure

```
psl/
├── timer_formal.vhd    # Timer with embedded PSL assertions
├── timer.sby           # BMC (Bounded Model Checking) config
├── timer_prove.sby     # Unbounded proving config
├── timer_cover.sby     # Coverage/reachability config
├── Makefile            # Build targets
└── README.md           # This file
```

## Entity Interface

The formal version preserves the exact same interface as the original timer:

```vhdl
entity timer_formal is
  generic (
    clk_freq_hz_g : natural;  -- Clock frequency in Hz
    delay_g       : time      -- Delay duration (VHDL time type)
  );
  port (
    clk_i   : in  std_ulogic;
    arst_i  : in  std_ulogic;
    start_i : in  std_ulogic;
    done_o  : out std_ulogic
  );
end entity timer_formal;
```

## Verification Modes

### BMC – Bounded Model Checking

```bash
make bmc
```

Explores all possible states up to a fixed depth (default: 50 cycles). Fast and effective for finding bugs.

**What it proves:** No assertion violations can occur within N clock cycles.

### Prove – Unbounded Verification

```bash
make prove
```

Uses k-induction to mathematically prove properties hold for **all time** (infinite cycles).

**What it proves:** Properties hold forever, not just within a bounded depth.

### Cover – Reachability Analysis

```bash
make cover
```

Verifies that cover properties are reachable—ensuring the design isn't over-constrained.

**What it proves:** All specified scenarios can actually occur.

## PSL Properties

All properties are embedded in `timer_formal.vhd` using PSL comment syntax (`-- psl ...`).

### Clock Declaration

```psl
default clock is rising_edge(clk_i);
```

### Safety Properties

| Property | Description |
|----------|-------------|
| `PROP_DONE_NOT_BUSY` | `done_o` always equals `not busy_r` |
| `PROP_RESET_IDLE` | After reset, timer is idle (`done_o = '1'`) |
| `PROP_COUNTER_BOUNDED` | Counter never exceeds `CYCLES_C - 1` |

### Liveness Properties

| Property | Description |
|----------|-------------|
| `PROP_START_TRIGGERS_BUSY` | Rising edge on `start_i` triggers busy state |
| `PROP_DONE_AT_MAX` | **Timer asserts `done_o` after exact cycle count** |
| `PROP_COUNTER_RESETS` | Counter resets to 0 at completion |
| `PROP_BUSY_PERSISTS` | Busy state persists until max count |
| `PROP_COUNTER_INCREMENTS` | Counter increments correctly each cycle |
| `PROP_IDLE_PERSISTS` | Idle state persists without start pulse |

### Cover Properties

| Property | Description |
|----------|-------------|
| `COVER_START` | Timer can be started from idle |
| `COVER_MAX_COUNT` | Timer can reach maximum count |
| `COVER_COMPLETE` | Timer can complete full cycle |

### Assumptions

| Assumption | Description |
|------------|-------------|
| `ASSUME_START_ONLY_AFTER_RESET` | Start only asserted when not in reset |

## PSL Syntax Reference

```psl
-- Implication operators
{A} |=> {B}              -- If A, then B on NEXT cycle
{A} |-> {B}              -- If A, then B on SAME cycle

-- Always (invariant)
assert always (P);       -- P must always be true

-- Abort (ignore during condition)
... abort (arst_i = '1'); -- Don't check during reset

-- Previous value
prev(signal)             -- Value from previous cycle

-- Sequences
{A; B; C}                -- A, then B next cycle, then C

-- Cover (reachability)
cover {condition};       -- Prove this state is reachable
```

## Troubleshooting

### Viewing Counterexamples

If verification fails, SymbiYosys generates a VCD waveform:

```bash
gtkwave timer/engine_0/trace.vcd
```

### Increasing Depth

For timers with many cycles, increase depth in `.sby` files:

```
[options]
depth 200
```

### Common Issues

| Issue | Solution |
|-------|----------|
| `GHDL not found` | Activate OSS CAD Suite: `source oss-cad-suite/environment` |
| `Timeout` | Reduce cycle count or increase depth incrementally |
| `Property fails` | Check counterexample waveform for cause |

## CI Integration

The formal verification is integrated into the GitHub Actions pipeline. See `.github/workflows/timer.yml` for the formal verification job configuration.

## References

- [SymbiYosys Documentation](https://symbiyosys.readthedocs.io/)
- [GHDL PSL Support](https://ghdl.github.io/ghdl/using/InvokingGHDL.html)
- [PSL Language Reference](https://en.wikipedia.org/wiki/Property_Specification_Language)
