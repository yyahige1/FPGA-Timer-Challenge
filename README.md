# FPGA Timer - Parametric Timer Design

![Tests](https://github.com/yyahige1/FPGA-Timer-Challenge/workflows/Timer%20Verification/badge.svg)

A synthesizable, parameterized hardware timer with comprehensive verification and CI/CD automation.

## Overview

This project implements a configurable timer module for FPGA applications with:
- Generic clock frequency and delay parameters
- Comprehensive VUnit test suite (15 tests)
- Multi-configuration validation (9 configs)
- Automated synthesis verification
- First stage of formal verification
- Full CI/CD pipeline

## Quick Start

### Prerequisites

- **OSS CAD Suite** (includes GHDL, Yosys, VUnit)
- **Python 3.10+**
- **Make**

### Local Setup

```bash
# 1. Download OSS CAD Suite
wget https://github.com/YosysHQ/oss-cad-suite-build/releases/download/2026-01-07/oss-cad-suite-linux-x64-20260107.tgz
tar -xzf oss-cad-suite-linux-x64-20260107.tgz

# 2. Install VUnit
pip install vunit_hdl

# 3. Source the environment
source oss-cad-suite/environment

# 4. Run tests
make run
```

## Project Structure

```
.
├── src/                    # VHDL source files
│   └── timer.vhd          # Parametric timer implementation
├── tb/                     # Testbenches
│   ├── tb_timer.vhd       # Main test suite (15 tests)
│   └── tb_timer_long.vhd  # Long delay tests
├── scripts/                # Build scripts
│   └── synth_check.ys     # Yosys synthesis script
├── psl/                   # PSL formal verification
│   └── timer_psl          # Directory with formal Timer
├── .github/workflows/      # CI/CD configuration
│   └── timer.yml          # GitHub Actions workflow
├── run.py                  # VUnit test runner
├── run_long_delay.py       # Long delay test runner
├── generate_sweep.py       # Test sweep generator
├── report_sweep.py         # Sweep results analyzer
├── run_sweep_all.sh        # Test sweep automation
├── make_sweep_synth.sh     # Synthesis sweep automation
├── makefile                # Build automation
├── README.md               # This file
├── Design_limits.md        # Design rationale and limits
└── AI_Usage.md             # AI assistance disclosure
```

## Testing

### Basic Tests

Run all 15 tests with current configuration:

```bash
source oss-cad-suite/environment
make run
```

**Test Suite Coverage:**
- Basic functionality and timing accuracy
- Reset behavior (async reset, edge cases)
- Start pulse handling and rejection
- Stress testing and continuous operation
- Edge cases and signal conflicts

See [tb/TB_TESTS.md](tb/TB_TESTS.md) for detailed test documentation.

### Multi-Configuration Testing

Test across 9 frequency/delay combinations:

```bash
source oss-cad-suite/environment
make sweep         # Run full sweep + report
make sweep-report  # View results only
```

**Configurations tested:**
- 10 MHz → 1 GHz clock frequencies
- 10 ns → 10 µs delay periods  
- Total: 9 configs × 15 tests = **135 test cases**

Logs saved to `sweep_logs/`

### Long Delay Testing

Test with extended delays (1 second at 10 MHz):

```bash
source oss-cad-suite/environment
make test-long    # Takes ~25 seconds
```

Tests validate:
- Basic 1-second countdown accuracy
- Reset during long countdown
- Multiple consecutive long delays

## Synthesis

### Single Configuration

Synthesize with current configuration:

```bash
source oss-cad-suite/environment
make synth
```

Output: `netlist/synth_output_timer.v`

### Multi-Configuration Synthesis

Synthesize all 9 configurations:

```bash
source oss-cad-suite/environment
make synth-sweep
```

**Output:**
- Logs: `synth_logs/<config>.log`
- Netlists: `netlist/synth_<config>.v`

All configurations synthesize successfully with Yosys.

## Design Limits

The timer enforces limits to prevent misuse:

**Frequency Limits:**
- Maximum: 1 GHz (protects against unrealistic configurations)
- Minimum: > 0 Hz (must be positive)

**Delay Limits:**
- Maximum cycles: 16,777,216 (2²⁴) - prevents huge counters
- Minimum: > 0 fs (must be positive)

**Practical Impact:**

| Clock Frequency | Max Delay  |
|-----------------|------------|
| 1 GHz           | 16.7 ms    |
| 500 MHz         | 33.5 ms    |
| 100 MHz         | 167 ms     |
| 10 MHz          | 1.67 s     |
| 1 MHz           | 16.7 s     |

Violations trigger assertion failures at elaboration/simulation time.

See [Design_limits.md](Design_limits.md) for detailed rationale.

## CI/CD Pipeline

### Automated Testing

Every push triggers GitHub Actions workflow that:

1. ✓ Installs dependencies (OSS CAD Suite, VUnit)
2. ✓ Runs basic tests (15 tests)
3. ✓ Runs test sweep (135 tests across 9 configs)
4. ✓ Runs synthesis sweep (9 configs)
5. ✓ Uploads artifacts (logs and netlists)

View results: **Actions** tab on GitHub

### Artifacts

After each CI run, download:
- `sweep-logs` - Test results for all configurations
- `synthesis-logs` - Synthesis reports
- `netlists` - Generated Verilog for all configs

## Makefile Commands

| Command | Description |
|---------|-------------|
| `make run` | Run tests with current config |
| `make sweep` | Run test sweep + report |
| `make sweep-report` | View sweep results |
| `make test-long` | Run long delay tests (~25s) |
| `make synth` | Synthesize current config |
| `make synth-sweep` | Synthesize all configs |
| `make clean` | Remove build outputs |
| `make clean-sweep` | Remove sweep logs |
| `make clean-synth` | Remove synthesis outputs |
| `make clean-all` | Remove everything |

## Entity Interface

```vhdl
entity timer is
  generic (
    clk_freq_hz_g : natural;  -- Clock frequency in Hz
    delay_g       : time      -- Delay duration (e.g., 1 us)
  );
  port (
    clk_i   : in  std_ulogic;  -- Clock input
    arst_i  : in  std_ulogic;  -- Async reset
    start_i : in  std_ulogic;  -- Start pulse (ignored if busy)
    done_o  : out std_ulogic   -- '1' when idle, '0' when counting
  );
end entity timer;
```

## Functional Behavior

- Timer calculates required clock cycles from `clk_freq_hz_g` and `delay_g`
- Rising edge on `start_i` begins countdown (if not already busy)
- `done_o` is high when idle, low when counting
- Asynchronous reset immediately returns timer to idle state
- Start pulses ignored during countdown

## Implementation Details

- **Counter width:** Dynamically calculated based on required cycles
- **Time precision:** Nanosecond resolution
- **Rounding:** Always rounds UP to guarantee minimum delay
- **Edge detection:** Detects rising edge on start_i for clean operation

## Future Work

### Formal Verification (Stretch Goal)

Plan to add formal verification using SymbiYosys (sby):
- Properties to verify: timer completion after exact cycle count
- Coverage: all possible frequency/delay combinations within limits
- Integration: Add formal checks to CI pipeline

## Development Notes

See [AI_Usage.md](AI_Usage.md) for AI assistance disclosure.


