--------------------------------------------------------------------------------
-- File: tb_timer_long.vhd
-- Description: Testbench for LONG delay testing (1 second at 10 MHz)
-- WARNING: Simulation takes ~1 second real time
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_timer_long is
  generic (
    runner_cfg : string
  );
end entity tb_timer_long;

architecture tb of tb_timer_long is

  -- Long delay configuration
  constant TB_CLK_FREQ : natural := 10_000_000;  -- 10 MHz
  constant TB_DELAY    : time    := 1 sec;       -- 1 SECOND!
  constant CLK_PERIOD_C : time := 1 sec / TB_CLK_FREQ;
  
  -- DUT signals
  signal clk_i   : std_ulogic := '0';
  signal arst_i  : std_ulogic := '0';
  signal start_i : std_ulogic := '0';
  signal done_o  : std_ulogic;
  
  signal stop_clk : boolean := false;

  -- Helper to wait cycles
  procedure wait_cycles(signal clk : in std_ulogic; n : natural) is
  begin
    for i in 1 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure;

begin

  -- Clock generation
  clk_i <= not clk_i after CLK_PERIOD_C / 2 when not stop_clk;

  -- Main test
  main : process
    variable cycle_count : natural;
    variable expected_cycles : natural;
    
    -- Calculate expected cycles
    function calc_expected_cycles(freq : natural; delay : time) return natural is
      variable delay_ns   : integer;
      variable period_ns  : integer;
      variable num_cycles : natural;
    begin
      delay_ns := delay / 1 ns;
      period_ns := 1000000000 / freq;
      num_cycles := delay_ns / period_ns;
      if (delay_ns rem period_ns) > 0 then
        num_cycles := num_cycles + 1;
      end if;
      return num_cycles;
    end function;
    
  begin
    test_runner_setup(runner, runner_cfg);
    
    expected_cycles := calc_expected_cycles(TB_CLK_FREQ, TB_DELAY);
    
    while test_suite loop
      
      if run("test_basic_long") then
        info("Basic test with long delay (" & integer'image(expected_cycles) & " cycles)");
        
        arst_i <= '1';
        wait_cycles(clk_i, 3);
        arst_i <= '0';
        wait_cycles(clk_i, 2);
        
        -- Start timer
        wait until rising_edge(clk_i);
        start_i <= '1';
        wait until rising_edge(clk_i);
        start_i <= '0';
        wait_cycles(clk_i, 1);
        
        check_equal(done_o, '0', "Should be busy");
        
        -- Wait for completion
        cycle_count := 1;
        while done_o = '0' loop
          wait until rising_edge(clk_i);
          cycle_count := cycle_count + 1;
          if cycle_count rem 1_000_000 = 0 then
            info("  Progress: " & integer'image(cycle_count / 1_000_000) & "M cycles");
          end if;
        end loop;
        
        info("  Completed: " & integer'image(cycle_count) & " cycles");
        check(cycle_count >= expected_cycles - 10 and cycle_count <= expected_cycles + 10);
        
      elsif run("test_reset_during_long_count") then
        info("Reset during long countdown");
        
        arst_i <= '1';
        wait_cycles(clk_i, 3);
        arst_i <= '0';
        wait_cycles(clk_i, 2);
        
        wait until rising_edge(clk_i);
        start_i <= '1';
        wait until rising_edge(clk_i);
        start_i <= '0';
        
        -- Wait partway through
        wait_cycles(clk_i, expected_cycles / 2);
        check_equal(done_o, '0', "Should still be counting");
        
        -- Reset
        arst_i <= '1';
        wait_cycles(clk_i, 3);
        check_equal(done_o, '1', "Should be idle during reset");
        arst_i <= '0';
        wait_cycles(clk_i, 2);
        check_equal(done_o, '1', "Should remain idle");
        
      elsif run("test_multiple_long_delays") then
        info("Multiple sequential long delays (this will take a while!)");
        
        arst_i <= '1';
        wait_cycles(clk_i, 3);
        arst_i <= '0';
        wait_cycles(clk_i, 2);
        
        -- Run 3 times
        for i in 1 to 3 loop
          info("  Run " & integer'image(i) & "/3");
          
          wait until rising_edge(clk_i);
          start_i <= '1';
          wait until rising_edge(clk_i);
          start_i <= '0';
          wait_cycles(clk_i, 1);
          
          check_equal(done_o, '0', "Should be counting");
          
          cycle_count := 1;
          while done_o = '0' loop
            wait until rising_edge(clk_i);
            cycle_count := cycle_count + 1;
          end loop;
          
          check(cycle_count >= expected_cycles - 10, 
                "Run " & integer'image(i) & " completed in " & integer'image(cycle_count) & " cycles");
          check_equal(done_o, '1', "Should be done");
        end loop;
        
      end if;
      
    end loop;
    
    stop_clk <= true;
    test_runner_cleanup(runner);
  end process;

  -- Extended watchdog for long test (10 seconds)
  test_runner_watchdog(runner, 10 sec);

  -- DUT instantiation
  dut : entity work.timer
    generic map (
      clk_freq_hz_g => TB_CLK_FREQ,
      delay_g       => TB_DELAY
    )
    port map (
      clk_i   => clk_i,
      arst_i  => arst_i,
      start_i => start_i,
      done_o  => done_o
    );

end architecture tb;
