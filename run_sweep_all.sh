#!/bin/bash
# Auto-generated sweep script

echo "Running timer test suite across multiple configurations..."
echo "============================================================"
echo ""

configs=(
  "10MHz_1us|10000000|1 us|Low frequency"
  "50MHz_1us|50000000|1 us|Medium frequency"
  "100MHz_100ns|100000000|100 ns|Standard - short delay"
  "100MHz_1us|100000000|1 us|Standard - default"
  "100MHz_10us|100000000|10 us|Standard - long delay"
  "150MHz_1us|150000000|1 us|High frequency"
  "200MHz_1us|200000000|1 us|Very high frequency"
  "500MHz_10ns|500000000|10 ns|Ultra high frequency"
  "1GHz_10ns|1000000000|10 ns|At limit (1 GHz)"
)

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
