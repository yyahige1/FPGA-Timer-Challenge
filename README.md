# FPGA Timer Challenge

Initial project setup for the parametric timer design challenge.

This commit includes:
- Project directory structure (`src/`, `tb/`)
- Skeleton RTL file (`src/timer.vhd`) with design assumptions
- Minimal VUnit testbench with a simple test (`tb/tb_timer.vhd`)
- Basic VUnit runner script (`run.py`)
- Minimal Makefile with `run` and `clean` targets

This commit is mainly to confirm that the flow works.
The goal of the project is to implement and verify a parametric timer in VHDL,
following the specifications of the FPGA Engineering Challenge.
---------------------------------------------------------------------------------------------

				COMMIT 2: add RTL, VUnit tests, and lab_test precision experiments
---------------------------------------------------------------------------------------------

I added a set of experiments and a VUnit testbench to validate the timer’s cycle‑calculation
 
and bit‑width estimation.

What’s included

lab_test/ — helper scripts used to compare implementations and validate assumptions.

tb_compare_div.sh — compares cycle computation precision across implementations (natural integer, floating point, native time, unsigned 64). The natural integer implementation has the smallest numeric range for very large delays (expected), but it is the only approach that is synthesizable and produces optimal bit‑width estimates (synthesis to be verified with Yosys).

tb_test_width.sh — runs many (clk_hz, delay) combinations to verify the computed counter width is minimal for normal operating ranges.

tb_time_to_calc.sh — runs the natural integer cycle computation across frequency/delay combinations and verifies rounding‑up behavior.

Design choices

The RTL uses the natural integer implementation for cycle computation and bit‑width estimation to remain synthesizable and to minimize counter width.

start_i is treated as a pulse input; the RTL implements an internal register stage to detect rising edges.

The design is synchronous with an asynchronous reset (arst), and the testbench exercises reset, start, counting, and completion behavior for the typical parameter range.

If so I will then run :

Parameterized sweep run the same test for several (clk_freq_hz_g, delay_g) pairs and assert the computed cycles match a golden reference.

Boundary tests for exact multiples and just-above-multiple delays to validate rounding-up.

Large-delay test to exercise counter width and integer limits.

Start-pulse stress test repeated and overlapping starts while busy.

Async reset stress assert reset at many different times relative to clock and start.

Synthesis smoke test run Yosys to confirm synthesizability even for edge cases.



Further commits will add:
- Cycle calculation logic
- Timer RTL implementation
- Full VUnit test suite
- Synthesis scripts
- CI pipeline
- Further Documentation and Design choices


