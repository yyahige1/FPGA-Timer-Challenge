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

Further commits will add:
- Cycle calculation logic
- Timer RTL implementation
- Full VUnit test suite
- Synthesis scripts
- CI pipeline
- Further Documentation and Design choices

