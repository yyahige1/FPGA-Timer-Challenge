library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity timer is
  generic (
    clk_freq_hz_g : natural;  -- Clock frequency in Hz
    delay_g       : time      -- Delay duration
  );
  port (
    clk_i   : in  std_ulogic;
    arst_i  : in  std_ulogic;
    start_i : in  std_ulogic;
    done_o  : out std_ulogic
  );
end entity timer;

architecture rtl of timer is
begin
-- Assumptions: -- - The reset is asynchronous, following standard VHDL semantics. 
-- - start_i is treated as a pulse (edge‑based), not a level signal, so an internal 
-- register will be required to detect rising edges. 
-- - Division must be handled carefully because the 'time' type is not synthesizable. 
-- - Integer-based arithmetic is synthesizable but may be limited in range depending 
-- on the integer width. 
-- - Floating‑point division can introduce precision issues (e.g., 1/3 may evaluate -- to 2.999999...), so it is not suitable for cycle calculations. 
-- - Using the 'time' type provides the best precision and range in simulation, but 
-- it is almost certainly not synthesizable. 
-- - Yosys will eventually be used to confirm the -- synthesizability of each approach.
end architecture rtl;

