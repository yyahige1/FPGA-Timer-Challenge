--------------------------------------------------------------------------------
-- File: timer.vhd
-- Parametric Timer - Synthesizable Version
-- Uses Nanosecond integer arithmetic (no overflow for typical frequencies but clamps higher frequencies >GHz)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity timer is
  generic (
    clk_freq_hz_g : natural;
    delay_g       : time
  );
  port (
    clk_i   : in  std_ulogic;
    arst_i  : in  std_ulogic;
    start_i : in  std_ulogic;
    done_o  : out std_ulogic
  );
end entity timer;

architecture rtl of timer is

 

function time_to_cycles(freq : natural; delay : time) return natural is
    variable delay_ns   : integer;
    variable period_ns  : integer;
    variable num_cycles : natural;
    variable remainder  : integer;
  begin

    delay_ns := delay / 1 ns; --I have done other tests with higher precision (ps or fs) but
    --it always caused bound check failures. A good realistic limit I found was ns precision.
    period_ns := 1000000000 / freq;
    
    -- Safety check for very high frequencies. But these high frequencies should be cut off at elaboration time
    if period_ns < 1 then
      period_ns := 1;  -- Minimum 1 ns period
    end if;
    
    -- Integer division: cycles = delay / period
    num_cycles := delay_ns / period_ns;
    
    -- Round UP if there's a remainder (guarantees minimum delay)
    remainder := delay_ns rem period_ns;
    if remainder > 0 then
      num_cycles := num_cycles + 1;
    end if;
    
    -- Ensure minimum 1 cycle
    if num_cycles < 1 then
      num_cycles := 1;
    end if;
    
    return num_cycles;
  end function;

  -- Calculate counter width (ceiling of log2)
  function ceil_log2(n : natural) return natural is
  begin
    if n <= 1 then
      return 1;
    else
      return natural(ceil(log2(real(n))));
    end if;
  end function;
  
  -- Constants computed at elaboration time (compile-time)
  constant CYCLES_C    : natural := time_to_cycles(clk_freq_hz_g, delay_g);
  constant CNT_WIDTH_C : natural := ceil_log2(CYCLES_C);
  -- Maximum cycles to prevent huge counters(24 bits counter is reasonable to synthesize) - THis is around 17ms of max delay at limit 1GHz frequency
  constant MAX_CYCLES : natural := 16_777_216;  -- 2^24
  
  -- Maximum frequency (1 GHz is the limit), 
  constant MAX_FREQ : natural := 1_000_000_000;  
  -- Signals
  signal cnt_r      : unsigned(CNT_WIDTH_C - 1 downto 0) := (others => '0');
  signal busy_r     : std_ulogic := '0';
  signal start_d_r  : std_ulogic := '0';

  
begin
	-- Check limits at elaboration time
  assert clk_freq_hz_g <= MAX_FREQ
    report "Clock frequency too high: " & integer'image(clk_freq_hz_g) & " Hz"
    severity failure;
  
  assert CYCLES_C <= MAX_CYCLES
    report "Delay requires " & integer'image(CYCLES_C) & 
           " cycles (max: " & integer'image(MAX_CYCLES) & ")"
    severity failure;

   -- Design validation (checked at elaboration time)
  assert clk_freq_hz_g > 0
    report "clk_freq_hz_g must be > 0"
    severity failure;
    
  assert delay_g > 0 fs
    report "delay_g must be > 0"
    severity failure;
    
  assert CYCLES_C >= 1
    report "Calculated cycles must be >= 1"
    severity failure;
  -- Main sequential process
  process(clk_i, arst_i)
    variable prev_start : std_ulogic;
  begin
    if arst_i = '1' then
      cnt_r     <= (others => '0');
      busy_r    <= '0';
      start_d_r <= '0';
      
    elsif rising_edge(clk_i) then
      -- Edge detection: capture previous value before updating
      prev_start := start_d_r;
      start_d_r  <= start_i;
      
      if busy_r = '1' then
        -- Counting mode
        if cnt_r = to_unsigned(CYCLES_C - 1, CNT_WIDTH_C) then
          cnt_r  <= (others => '0');
          busy_r <= '0';
        else
          cnt_r <= cnt_r + 1;
        end if;
        
      else
        -- Idle mode: detect rising edge on start_i
        if (start_i = '1') and (prev_start = '0') then
          cnt_r  <= (others => '0');
          busy_r <= '1';
        end if;
      end if;
    end if;
  end process;
  
  -- Output assignment
  done_o <= not busy_r;
end architecture rtl;
