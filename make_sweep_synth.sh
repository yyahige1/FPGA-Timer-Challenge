#!/bin/bash
# Synthesis sweep through all configurations

echo "Synthesis Sweep"
echo "=================================================="
echo ""

mkdir -p synth_logs
mkdir -p netlist

# ALL configs - same as testbench
configs=(
  "10MHz_1us|10000000|1 us"
  "50MHz_1us|50000000|1 us"
  "100MHz_100ns|100000000|100 ns"
  "100MHz_1us|100000000|1 us"
  "100MHz_10us|100000000|10 us"
  "150MHz_1us|150000000|1 us"
  "200MHz_1us|200000000|1 us"
  "500MHz_10ns|500000000|10 ns"
  "1GHz_10ns|1000000000|10 ns"
)

passed=0
failed=0

for config in "${configs[@]}"; do
    IFS='|' read -r name freq delay <<< "$config"
    
    echo "Synthesizing: $name (${freq} Hz, ${delay})"
    
    # 1. Create timer_wrapper.vhd with current config
    cat > src/timer_wrapper.vhd << EOF
--------------------------------------------------------------------------------
-- File: timer_wrapper.vhd
-- Description: Wrapper for timer with fixed generics for synthesis
--------------------------------------------------------------------------------
library ieee;
use ieee.std_logic_1164.all;

entity timer_wrapper is
  port (
    clk_i   : in  std_ulogic;
    arst_i  : in  std_ulogic;
    start_i : in  std_ulogic;
    done_o  : out std_ulogic
  );
end entity timer_wrapper;

architecture rtl of timer_wrapper is
  
  -- Fixed parameters for synthesis
  constant CLK_FREQ_HZ_C : natural := ${freq};
  constant DELAY_C       : time    := ${delay};
  
begin
  -- Instantiate timer with fixed generics
  u_timer : entity work.timer
    generic map (
      clk_freq_hz_g => CLK_FREQ_HZ_C,
      delay_g       => DELAY_C
    )
    port map (
      clk_i   => clk_i,
      arst_i  => arst_i,
      start_i => start_i,
      done_o  => done_o
    );
end architecture rtl;
EOF

    # 2. Create/update yosys script (same for all)
    cat > scripts/synth_check.ys << 'YOSYS_EOF'
# synth_check.ys
# Synthesis using wrapper with fixed generics
ghdl src/timer.vhd src/timer_wrapper.vhd -e timer_wrapper
synth -top timer_wrapper
check -assert
write_verilog netlist/synth_output_timer.v
stat
YOSYS_EOF

    # 3. Run synthesis
    if make synth > "synth_logs/${name}.log" 2>&1; then
        echo "  ✓ PASS"
        ((passed++))
        # Save netlist with config name
        cp netlist/synth_output_timer.v "netlist/synth_${name}.v"
    else
        echo "  ✗ FAIL"
        ((failed++))
    fi
done

echo ""
echo "=================================================="
echo "Passed: $passed | Failed: $failed"
echo "=================================================="

if [ $failed -eq 0 ]; then
    echo "SUCCESS!"
fi
