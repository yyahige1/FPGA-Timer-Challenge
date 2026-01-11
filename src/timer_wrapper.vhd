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
  constant CLK_FREQ_HZ_C : natural := 1000000000;
  constant DELAY_C       : time    := 10 ns;
  
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
