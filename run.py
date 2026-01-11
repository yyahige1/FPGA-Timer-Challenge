#!/usr/bin/env python3
"""
VUnit test runner for parametric timer
Single configuration (time generics can't be passed via VUnit)
"""

from vunit import VUnit

# Create VUnit instance
vu = VUnit.from_argv()

# Add library
lib = vu.add_library("lib")

# Add source files
lib.add_source_files("src/timer.vhd")
lib.add_source_files("tb/tb_timer.vhd")

# Set compile options
lib.set_compile_option("ghdl.a_flags", ["--std=08"])

# Run tests
# Note: The testbench uses hardcoded TB_CLK_FREQ=100MHz and TB_DELAY=1us
# To test other configurations, modify those constants in tb_timer.vhd
vu.main()
