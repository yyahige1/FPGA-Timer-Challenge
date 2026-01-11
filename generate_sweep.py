#!/usr/bin/env python3
"""
Full Test Suite Sweep
Runs ALL 15 tests across multiple frequency/delay configurations
"""

import sys
# Configuration matrix
configs = [
    # (name, freq_hz, delay_str, description)
    ("10MHz_1us",   10_000_000,   "1 us",   "Low frequency"),
    ("50MHz_1us",   50_000_000,   "1 us",   "Medium frequency"),
    ("100MHz_100ns", 100_000_000, "100 ns", "Standard - short delay"),
    ("100MHz_1us",  100_000_000,  "1 us",   "Standard - default"),
    ("100MHz_10us", 100_000_000,  "10 us",  "Standard - long delay"),
    ("150MHz_1us",  150_000_000,  "1 us",   "High frequency"),
    ("200MHz_1us",  200_000_000,  "1 us",   "Very high frequency"),
    ("500MHz_10ns", 500_000_000,  "10 ns",  "Ultra high frequency"),
    ("1GHz_10ns",   1_000_000_000, "10 ns", "At limit (1 GHz)"),
]

print("AVAILABLE CONFIGURATIONS:")
print("-" * 70)
for i, (name, freq, delay, desc) in enumerate(configs, 1):
    period_ns = 1e9 / freq
    cycles = int((float(delay.split()[0]) * {'ns': 1e-9, 'us': 1e-6, 'ms': 1e-3}[delay.split()[1]]) / (1.0/freq))
    print(f"{i:2d}. {name:15s} | {freq:>12,} Hz | {delay:>7s} | {desc:25s} | ~{cycles} cycles")
print("-" * 70)
print()

# Since we can't pass time generics via VUnit, we'll do this through scripts
helper_script = """#!/bin/bash
# Auto-generated sweep script

echo "Running timer test suite across multiple configurations..."
echo "============================================================"
echo ""

configs=(
"""

for name, freq, delay, desc in configs:
    helper_script += f'  "{name}|{freq}|{delay}|{desc}"\n'

helper_script += """)

total=0
passed=0
failed=0

for config in "${configs[@]}"; do
    IFS='|' read -r name freq delay desc <<< "$config"
    
    echo ""
    echo "Testing: $name - $desc"
    echo "  Frequency: $freq Hz"
    echo "  Delay: $delay"
    echo "  Updating testbench..."
    mkdir -p sweep_logs
    # Update the testbench constants
    sed -i.bak "s/constant TB_CLK_FREQ : natural := [0-9_]*;/constant TB_CLK_FREQ : natural := ${freq};/" tb/tb_timer.vhd
    sed -i.bak "s/constant TB_DELAY    : time    := .*;/constant TB_DELAY    : time    := ${delay};/" tb/tb_timer.vhd
    
    # Run tests
    echo "  Running tests..."
    if python run.py > "sweep_logs/sweep_${name}.log" 2>&1; then
        result=$(grep "pass.*of" "sweep_logs/sweep_${name}.log" | tail -1)
        echo "  [PASS] $result"
        ((passed++))
    else
        result=$(grep "fail.*of" "sweep_logs/sweep_${name}.log" | tail -1 || echo "unknown")
        echo "  [FAIL] $result"
        echo "    See sweep_logs/sweep_${name}.log for details"
        ((failed++))
    fi
    ((total++))
done

echo ""
echo "============================================================"
echo "SWEEP COMPLETE"
echo "============================================================"
echo "Total configurations: $total"
echo "Passed: $passed"
echo "Failed: $failed"
echo ""

if [ $failed -eq 0 ]; then
    echo "SUCCESS: ALL CONFIGURATIONS PASSED!"
else
    echo "WARNING: Some configurations failed. Check logs:"
    ls -1 sweep_logs/sweep_*.log
    echo ""
    echo "Run: python sweep_summary.py for detailed analysis"
fi

# Restore original (optional - uncomment if needed)
# mv tb/tb_timer.vhd.bak tb/tb_timer.vhd
"""

# Write the helper script
with open("run_sweep_all.sh", "w") as f:
    f.write(helper_script)

import os
os.chmod("run_sweep_all.sh", 0o755)

