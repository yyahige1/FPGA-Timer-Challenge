# Timer Testbench Documentation

## Overview

The timer testbench (`tb_timer.vhd`) contains a comprehensive VUnit test suite with **15 test cases** that validate all aspects of the timer's functionality, edge cases, and stress conditions.

## Test Configuration

The testbench uses two constants that define the test configuration:

```vhdl
constant TB_CLK_FREQ : natural := 100_000_000;  -- Clock frequency in Hz
constant TB_DELAY    : time    := 1 us;         -- Timer delay period
```

These can be modified to test different frequency/delay combinations.

## Test Suite (15 Tests)

### 1. `test_basic_functionality`
**Purpose:** Validates core timer operation

**What it tests:**
- Timer starts idle (`done_o = '1'`) after reset
- Timer goes busy (`done_o = '0'`) when started
- Timer completes after the expected number of cycles
- Cycle count matches calculated expectation

**Validates:** Basic timing accuracy

---

### 2. `test_multiple_starts`
**Purpose:** Ensures timer can run multiple times sequentially

**What it tests:**
- Timer can complete multiple countdown sequences (3 runs)
- Each run completes correctly
- Timer returns to idle state between runs
- Timing remains consistent across runs

**Validates:** Repeatability and state machine correctness

---

### 3. `test_ignored_start_while_busy`
**Purpose:** Verifies start pulses are ignored during countdown

**What it tests:**
- Timer doesn't restart when receiving start pulses while busy
- Multiple start pulses during countdown are rejected
- Timer completes at the original expected time
- No restart behavior occurs

**Validates:** Start pulse rejection logic

---

### 4. `test_reset_during_count`
**Purpose:** Tests asynchronous reset during active counting

**What it tests:**
- Reset immediately stops counting
- Timer returns to idle state during reset
- Timer remains idle after reset release
- Timer works correctly after being reset mid-count
- New countdown starts from zero after reset

**Validates:** Asynchronous reset functionality and recovery

---

### 5. `test_rapid_consecutive_starts`
**Purpose:** Stress tests sequential timer operations

**What it tests:**
- Timer handles 5 consecutive start-wait-complete cycles
- Each cycle completes in expected time
- No accumulated errors or timing drift
- State machine remains stable

**Validates:** Continuous operation reliability

---

### 6. `test_start_on_completion`
**Purpose:** Tests starting timer at exact completion moment

**What it tests:**
- Timer can be restarted immediately upon completion
- No dead cycle or setup time needed
- Restart works on the same cycle as completion
- New countdown begins correctly

**Validates:** Transition timing from done to busy

---

### 7. `test_glitchy_start_pulse`
**Purpose:** Validates single-cycle start pulse detection

**What it tests:**
- Timer responds to single-cycle pulse (minimum width)
- No pulse stretching required
- Clean edge detection

**Validates:** Start pulse sensitivity and edge detection

---

### 8. `test_reset_on_completion`
**Purpose:** Tests reset applied at exact completion cycle

**What it tests:**
- Reset on completion cycle works correctly
- Timer goes idle immediately
- Timer remains idle after reset release
- No timing conflicts

**Validates:** Reset priority over completion

---

### 9. `test_rapid_reset_toggling`
**Purpose:** Stress tests reset signal with rapid toggling

**What it tests:**
- Timer survives multiple rapid reset cycles (3 toggles)
- Timer returns to idle after reset stress
- Timer still functions correctly after reset abuse
- No state corruption from rapid resets

**Validates:** Reset robustness and state machine integrity

**Note:** This test was fixed to check at cycle 1 instead of cycle 10 to handle fast configurations (1 GHz / 10 ns).

---

### 10. `test_reset_while_start_high`
**Purpose:** Edge case - reset asserted while start signal is high

**What it tests:**
- Reset dominates when both signals active
- Timer stays idle during reset regardless of start
- Timer doesn't start after reset release if start is removed
- No spurious operation

**Validates:** Signal priority (reset > start)

---

### 11. `test_initial_state`
**Purpose:** Validates power-on state without explicit reset

**What it tests:**
- Timer defaults to idle state (`done_o = '1'`)
- No reset required for known state
- Safe initial conditions

**Validates:** Default state initialization

---

### 12. `test_continuous_operation`
**Purpose:** Long-duration stress test

**What it tests:**
- Timer runs correctly for 10 consecutive cycles
- No timing drift over extended operation
- Consistent cycle counts across all runs
- State machine stability over time

**Validates:** Long-term reliability and timing stability

---

### 13. `test_start_during_reset`
**Purpose:** Edge case - start asserted before reset releases

**What it tests:**
- Start signal present during reset doesn't cause issues
- Timer doesn't start until after reset release AND start removed
- Proper signal sequencing required
- Timer still works after this edge case

**Validates:** Reset/start interaction handling

---

### 14. `test_simultaneous_start_reset`
**Purpose:** Edge case - both signals asserted simultaneously

**What it tests:**
- Reset dominates over start when both asserted
- Timer stays idle during simultaneous assertion
- Clean state after both signals removed
- No undefined behavior

**Validates:** Concurrent signal priority

---

### 15. `test_verify_no_overflow`
**Purpose:** Validates counter doesn't overflow during countdown

**What it tests:**
- Timer counts correctly at multiple checkpoints
- No premature completion
- Counter behavior is monotonic
- Completion happens exactly when expected (not early/late)

**Validates:** Counter implementation correctness

---

## Test Coverage Summary

| Category | Tests | Coverage |
|----------|-------|----------|
| **Basic Operation** | 1, 2 | Start, stop, timing |
| **Start Logic** | 3, 6, 7 | Pulse detection, rejection |
| **Reset Logic** | 4, 8, 9 | Async reset, timing |
| **Edge Cases** | 10, 13, 14 | Signal conflicts |
| **Robustness** | 5, 9, 12 | Stress, continuous operation |
| **Verification** | 11, 15 | Initial state, overflow |

## Helper Functions

The testbench includes several helper procedures:

### `wait_cycles(clk, n)`
Waits for `n` clock cycles

### `pulse_start(clk, start)`
Generates a single-cycle start pulse

### `apply_reset(clk, arst)`
Applies reset for 3 cycles, then waits 2 cycles

### `calc_expected_cycles(freq, delay)`
Calculates expected cycle count matching timer's internal calculation

## Running the Tests

### Run all tests:
```bash
python run.py
```

### Run specific test:
```bash
python run.py *test_basic_functionality*
```

### Run with waveform viewer:
```bash
python run.py --gui
```

## Expected Results

All 15 tests should **PASS** for a correctly implemented timer.

```
pass 15 of 15
```

## Known Issues

### Fast Configuration Warning
For very fast configurations (e.g., >1 GHz clock with small delay), the implementation clamps the period to 1ns as natural precision does not allow going higher than this (upper bound issue)

