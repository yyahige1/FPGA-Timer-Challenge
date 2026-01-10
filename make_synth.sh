# 1. Save timer_wrapper.vhd to src/timer_wrapper.vhd
cat > src/timer_wrapper.vhd << 'EOF'
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
  constant CLK_FREQ_HZ_C : natural := 100_000_000;  -- 100 MHz
  constant DELAY_C       : time    := 1 us;          -- 1 microsecond
  
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

# 2. Update yosys_script/synth_check.ys
cat > scripts/synth_check.ys << 'EOF'
# synth_check.ys
# Synthesis using wrapper with fixed generics

# Read both files and elaborate the wrapper

# old command not working: ghdl --std=08 -gclk_freq_hz_g=100000000 -gdelay_g=1us src/timer.vhd #-e timer
#synth -top timer

#The ghdl plugin in yosys did not support passing the generics in the command line and ignored them
#As a result the elaboration failed and the synthesis check was not possible
#A workaround was to use a wrapper which initialized those generics making the synthesis possible



ghdl src/timer.vhd src/timer_wrapper.vhd -e timer_wrapper

# Synthesize
synth -top timer_wrapper

check -assert
# Write output
write_verilog netlist/synth_output_timer.v

# Statistics
stat
EOF

# 3. Run synthesis
make synth
