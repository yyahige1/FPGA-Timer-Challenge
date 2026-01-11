#!/usr/bin/env python3
"""
Standalone long delay test - 1 second timer at 10 MHz
WARNING: This test takes ~1 second to run!
"""

from vunit import VUnit

# Create VUnit instance
vu = VUnit.from_argv()
lib = vu.add_library("lib")

# Add source files
lib.add_source_files("src/timer.vhd")
lib.add_source_files("tb/tb_timer_long.vhd")

# Configure GHDL
lib.set_compile_option("ghdl.a_flags", ["--std=08"])

print("=" * 70)
print("LONG DELAY TEST")
print("=" * 70)
print("Configuration: 10 MHz clock, 1 second delay")
print("Expected cycles: 10,000,000")
print("Simulation time: ~1 second real time")
print("=" * 70)
print()

# Run
vu.main()
