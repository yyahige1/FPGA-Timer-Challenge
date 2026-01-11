# Timer Design Choices and Limitations

## Overview

This document explains the design decisions and limitations of the parameterized timer.

## Design Parameters

### Maximum Cycle Count

**Value:** `MAX_CYCLES = 16,777,216 (2²⁴)`

#### Why this limit?
- **Hardware efficiency**: 24-bit counters are cheap on any FPGA (uses LUTs + carry chain)
- **Prevents pathological cases**: Blocks requests for billions of cycles
- **Simulation practicality**: Keeps test execution time reasonable
- **Sufficient range**: Covers most practical timer applications

#### Practical Implications

Maximum delay varies with clock frequency:

| Clock Frequency | Max Cycles | Max Delay  |
|-----------------|------------|------------|
| 1 GHz           | 2²⁴        | 16.7 ms    |
| 500 MHz         | 2²⁴        | 33.5 ms    |
| 100 MHz         | 2²⁴        | 167 ms     |
| 10 MHz          | 2²⁴        | 1.67 s     |
| 1 MHz           | 2²⁴        | 16.7 s     |

**Trade-offs:**
- ✓ Adequate for most timers (ms to seconds range)
- ✗ Not suitable for multi-minute delays
- ✗ High-frequency configs limited to millisecond delays

**Alternative:** For long-duration timers, use 32-bit counters (4.3 billion cycles).

---

### Maximum Clock Frequency

**Value:** `MAX_FREQ = 1,000,000,000 Hz (1 GHz)`

#### Why this limit?
- **Physical reality**: No FPGA fabric clock reaches 1 GHz
  - UltraScale+ tops out at ~600-700 MHz with aggressive constraints
  - Most designs run at 100-400 MHz
- **Safety**: Prevents division-by-zero in period calculations
- **Clean boundary**: Round number for constraints and testbench sweeps

#### Purpose

This is a **logical limit**, not a realistic target:
- Protects design from nonsense inputs
- Enables boundary testing without hardware concerns
- Provides clear error messages for invalid configs

---

## Design Interaction

The two limits work together to create a predictable design space:

```
Frequency × Delay ≤ 2²⁴ cycles
```

### Example Configurations

**High frequency, short delay:**
```vhdl
clk_freq_hz_g => 1_000_000_000  -- 1 GHz
delay_g       => 16 ms           -- Near limit
cycles        => ~16M            ✓ OK
```

**Low frequency, long delay:**
```vhdl
clk_freq_hz_g => 1_000_000      -- 1 MHz
delay_g       => 10 sec          -- Reasonable
cycles        => 10M             ✓ OK
```

**Invalid configuration:**
```vhdl
clk_freq_hz_g => 100_000_000    -- 100 MHz
delay_g       => 10 sec          -- Too long!
cycles        => 1_000_000_000   ✗ FAIL (> 2²⁴)
```

---
## Implementation

See `src/timer.vhd` for assertion checks:
```vhdl
assert clk_freq_hz_g <= MAX_FREQ
  report "Clock frequency too high"
  severity failure;

assert CYCLES_C <= MAX_CYCLES
  report "Delay too large"
  severity failure;
```

