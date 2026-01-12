--------------------------------------------------------------------------------
-- File: timer_formal.vhd
-- Timer with embedded PSL assertions for formal verification
-- Verified with GHDL + SymbiYosys (OSS CAD Suite)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity timer_formal is
  generic (
    clk_freq_hz_g : natural := 100000000;  -- 100 MHz default
    delay_g       : time    := 100 ns      -- I changed to natural temporaily because I kept running into issues but it turned out it was because i didnt add the ghdl plugin in the sby scripts 
  );
  port (
    clk_i   : in  std_ulogic;
    arst_i  : in  std_ulogic;
    start_i : in  std_ulogic;
    done_o  : out std_ulogic
  );
end entity timer_formal;

architecture rtl of timer_formal is

  ------------------------------------------------------------------------------
  -- Functions (identical to original timer.vhd)
  ------------------------------------------------------------------------------
  
  function time_to_cycles(freq : natural; delay : time) return natural is
    variable delay_ns   : integer;
    variable period_ns  : integer;
    variable num_cycles : natural;
    variable remainder  : integer;
  begin
    delay_ns := delay / 1 ns;
    period_ns := 1000000000 / freq;
    
    if period_ns < 1 then
      period_ns := 1;
    end if;
    
    num_cycles := delay_ns / period_ns;
    remainder := delay_ns rem period_ns;
    
    if remainder > 0 then
      num_cycles := num_cycles + 1;
    end if;
    
    if num_cycles < 1 then
      num_cycles := 1;
    end if;
    
    return num_cycles;
  end function;

  function ceil_log2(n : natural) return natural is
  begin
    if n <= 1 then
      return 1;
    else
      return natural(ceil(log2(real(n))));
    end if;
  end function;
  
  ------------------------------------------------------------------------------
  -- Constants (identical to original timer.vhd)
  ------------------------------------------------------------------------------
  constant CYCLES_C    : natural := time_to_cycles(clk_freq_hz_g, delay_g);
  constant CNT_WIDTH_C : natural := ceil_log2(CYCLES_C);
  
  ------------------------------------------------------------------------------
  -- Signals
  ------------------------------------------------------------------------------
  signal cnt_r      : unsigned(CNT_WIDTH_C - 1 downto 0) := (others => '0');
  signal busy_r     : std_ulogic := '0';
  signal start_d_r  : std_ulogic := '0';
  
  -- Helper signals for PSL properties
  signal start_rising : std_ulogic;
  signal at_max_count : std_ulogic;
  
begin

  ------------------------------------------------------------------------------
  -- Helper signal assignments
  ------------------------------------------------------------------------------
  start_rising <= '1' when (start_i = '1' and start_d_r = '0') else '0';
  at_max_count <= '1' when (cnt_r = to_unsigned(CYCLES_C - 1, CNT_WIDTH_C)) else '0';

  ------------------------------------------------------------------------------
  -- Main sequential process (identical to original timer.vhd)
  ------------------------------------------------------------------------------
  process(clk_i, arst_i)
  begin
    if arst_i = '1' then
      cnt_r     <= (others => '0');
      busy_r    <= '0';
      start_d_r <= '0';
      
    elsif rising_edge(clk_i) then
      start_d_r <= start_i;
      
      if busy_r = '1' then
        if at_max_count = '1' then
          cnt_r  <= (others => '0');
          busy_r <= '0';
        else
          cnt_r <= cnt_r + 1;
        end if;
      else
        if start_rising = '1' then
          cnt_r  <= (others => '0');
          busy_r <= '1';
        end if;
      end if;
    end if;
  end process;
  
  ------------------------------------------------------------------------------
  -- Output assignment
  ------------------------------------------------------------------------------
  done_o <= not busy_r;

  -- psl default clock is rising_edge(clk_i);

  -- psl PROP_DONE_NOT_BUSY : assert always (done_o = not busy_r);

  -- psl PROP_RESET_IDLE : assert always
  --   (arst_i = '1') |=> (done_o = '1');

  -- psl PROP_COUNTER_BOUNDED : assert always (cnt_r < CYCLES_C);

  -- psl PROP_START_TRIGGERS_BUSY : assert always
  --   ((busy_r = '0') and (start_rising = '1')) |=> (busy_r = '1')
  --   abort (arst_i = '1');
  
  -- psl ASSUME_START_ONLY_AFTER_RESET : assume always 
  --   (start_rising = '1') -> (arst_i = '0');
  
  -- psl PROP_DONE_AT_MAX : assert always
  --   ((busy_r = '1') and (at_max_count = '1')) |=> (done_o = '1')
  --   abort (arst_i = '1');

  -- psl PROP_COUNTER_RESETS : assert always
  --   ((busy_r = '1') and (at_max_count = '1')) |=> (cnt_r = 0)
  --   abort (arst_i = '1');

  -- psl PROP_BUSY_PERSISTS : assert always
  --   ((busy_r = '1') and (at_max_count = '0')) |=> (busy_r = '1')
  --   abort (arst_i = '1');

  -- psl PROP_COUNTER_INCREMENTS : assert always
  --   ((busy_r = '1') and (at_max_count = '0')) |=> (cnt_r = prev(cnt_r) + 1)
  --   abort (arst_i = '1');

  -- psl PROP_IDLE_PERSISTS : assert always
  --   ((busy_r = '0') and (start_rising = '0')) |=> (busy_r = '0')
  --   abort (arst_i = '1');
  
  -- psl COVER_START : cover { (busy_r = '0') and (start_rising = '1') }; 
  -- psl COVER_MAX_COUNT : cover { (busy_r = '1') and (at_max_count = '1') };
  -- psl COVER_COMPLETE : cover { busy_r = '1'; done_o = '1' };

end architecture rtl;
