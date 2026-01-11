--------------------------------------------------------------------------------
-- File: tb_timer.vhd
-- COMPLETE VUnit test suite for parametric timer
-- Fixed: All constants use TB_CLK_FREQ and TB_DELAY (uppercase)
--------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_timer is
  generic (
    runner_cfg : string
  );
end entity tb_timer;

architecture tb of tb_timer is

  -- Test configuration
  constant TB_CLK_FREQ : natural := 1000000000;  -- 1GHz
  constant TB_DELAY    : time    := 10 ns;          -- 10ns
  constant CLK_PERIOD_C : time := 1 sec / TB_CLK_FREQ;
  
  -- DUT signals
  signal clk_i   : std_ulogic := '0';
  signal arst_i  : std_ulogic := '0';
  signal start_i : std_ulogic := '0';
  signal done_o  : std_ulogic;
  
  signal stop_clk : boolean := false;

  -- Helper procedures
  procedure wait_cycles(signal clk : in std_ulogic; n : natural) is
  begin
    for i in 1 to n loop
      wait until rising_edge(clk);
    end loop;
  end procedure;
  
  procedure pulse_start(signal clk : in std_ulogic; signal start : out std_ulogic) is
  begin
    wait until rising_edge(clk);
    start <= '1';
    wait until rising_edge(clk);
    start <= '0';
  end procedure;
  
  procedure apply_reset(signal clk : in std_ulogic; signal arst : out std_ulogic) is
  begin
    arst <= '1';
    wait_cycles(clk, 3);
    arst <= '0';
    wait_cycles(clk, 2);
  end procedure;
  
  -- Calculate expected cycles (matches timer's calculation)
  function calc_expected_cycles(freq : natural; delay : time) return natural is
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

begin

  -- Clock generation
  clk_i <= not clk_i after CLK_PERIOD_C / 2 when not stop_clk;

  -- Main test process
  main : process
    variable cycle_count : natural;
    variable expected_cycles : natural;
  begin
    test_runner_setup(runner, runner_cfg);
    
    while test_suite loop
      
      if run("test_basic_functionality") then
        info("Basic: Testing configured delay");
        
        apply_reset(clk_i, arst_i);
        check_equal(done_o, '1', "Should be idle after reset");
        
        pulse_start(clk_i, start_i);
        wait_cycles(clk_i, 1);
        check_equal(done_o, '0', "Should be busy");
        
        cycle_count := 1;
        while done_o = '0' loop
          wait until rising_edge(clk_i);
          if done_o = '0' then
            cycle_count := cycle_count + 1;
          end if;
        end loop;
        
        expected_cycles := calc_expected_cycles(TB_CLK_FREQ, TB_DELAY);
        info("Completed after " & integer'image(cycle_count) & " cycles (expected " & integer'image(expected_cycles) & ")");
        check_equal(cycle_count, expected_cycles, "Cycle count mismatch");
        
      elsif run("test_multiple_starts") then
        info("Testing multiple sequential starts");
        
        apply_reset(clk_i, arst_i);
        expected_cycles := calc_expected_cycles(TB_CLK_FREQ, TB_DELAY);
        
        for i in 1 to 3 loop
          pulse_start(clk_i, start_i);
          wait_cycles(clk_i, 1);
          check_equal(done_o, '0', "Run " & integer'image(i) & ": should start");
          
          -- Wait for completion 
          cycle_count := 1;
          while done_o = '0' loop
            wait until rising_edge(clk_i);
            cycle_count := cycle_count + 1;
            check(cycle_count < expected_cycles + 10, "Run " & integer'image(i) & ": timeout");
          end loop;
          
          check_equal(done_o, '1', "Run " & integer'image(i) & ": should complete");
        end loop;
        
      elsif run("test_ignored_start_while_busy") then
        info("Start pulses ignored while busy");
        
        apply_reset(clk_i, arst_i);
        expected_cycles := calc_expected_cycles(TB_CLK_FREQ, TB_DELAY);
        
        pulse_start(clk_i, start_i);
        
        -- Wait for 20% of the timer duration (or minimum 2 cycles)
        if expected_cycles > 10 then
          wait_cycles(clk_i, expected_cycles / 5);  -- 20%
        else
          wait_cycles(clk_i, 2);  -- Minimum wait for very short delays
        end if;
        
        check_equal(done_o, '0', "Should be busy");
        
        -- Bombard with start pulses
        for i in 1 to 5 loop
          pulse_start(clk_i, start_i);
        end loop;
        
        -- Just wait for completion (shouldn't restart)
        cycle_count := expected_cycles / 5 + 10;  -- Account for what we already waited
        while done_o = '0' loop
          wait until rising_edge(clk_i);
          cycle_count := cycle_count + 1;
          check(cycle_count < expected_cycles + 20, "Timeout - timer may have restarted");
        end loop;
        
        check(cycle_count >= expected_cycles and cycle_count <= expected_cycles + 10, 
              "Timer completed at ~" & integer'image(cycle_count) & " cycles (expected ~" & integer'image(expected_cycles) & ")");
        
      elsif run("test_reset_during_count") then
        info("Reset during active counting");
        
        apply_reset(clk_i, arst_i);
        pulse_start(clk_i, start_i);
        expected_cycles := calc_expected_cycles(TB_CLK_FREQ, TB_DELAY);
        wait_cycles(clk_i, expected_cycles / 2);
        check_equal(done_o, '0', "Should be running");
        
        arst_i <= '1';
        wait_cycles(clk_i, 1);
        check_equal(done_o, '1', "Should be idle during reset");
        arst_i <= '0';
        wait_cycles(clk_i, 2);
        check_equal(done_o, '1', "Should remain idle");
        
        -- Verify timer still works - count from start
        pulse_start(clk_i, start_i);
        wait_cycles(clk_i, 1);
        check_equal(done_o, '0', "Should be counting after restart");
        
        cycle_count := 1;
        while done_o = '0' loop
          wait until rising_edge(clk_i);
          cycle_count := cycle_count + 1;
        end loop;
        check(cycle_count >= expected_cycles and cycle_count <= expected_cycles + 3,
              "Should complete in expected cycles (got " & integer'image(cycle_count) & ")");
        
      elsif run("test_rapid_consecutive_starts") then
        info("Rapid consecutive starts");
        
        apply_reset(clk_i, arst_i);
        expected_cycles := calc_expected_cycles(TB_CLK_FREQ, TB_DELAY);
        
        for i in 1 to 5 loop
          pulse_start(clk_i, start_i);
          wait_cycles(clk_i, 1);
          check_equal(done_o, '0', "Run " & integer'image(i) & ": should be counting");
          
          cycle_count := 1;
          while done_o = '0' loop
            wait until rising_edge(clk_i);
            cycle_count := cycle_count + 1;
          end loop;
          check(cycle_count >= expected_cycles and cycle_count <= expected_cycles + 3,
                "Run " & integer'image(i) & ": completed in " & integer'image(cycle_count) & " cycles");
        end loop;
        
      elsif run("test_start_on_completion") then
        info("Start pulse on exact completion cycle");
        
        apply_reset(clk_i, arst_i);
        pulse_start(clk_i, start_i);
        expected_cycles := calc_expected_cycles(TB_CLK_FREQ, TB_DELAY);
        
        -- Wait for completion
        cycle_count := 0;
        while done_o = '0' loop
          wait until rising_edge(clk_i);
          cycle_count := cycle_count + 1;
        end loop;
        
        check_equal(done_o, '1', "Should complete");
        
        -- Start immediately
        wait until rising_edge(clk_i);
        start_i <= '1';
        wait until rising_edge(clk_i);
        start_i <= '0';
        wait_cycles(clk_i, 2);
        check_equal(done_o, '0', "Should restart");
        
      elsif run("test_glitchy_start_pulse") then
        info("Very short start pulse");
        
        apply_reset(clk_i, arst_i);
        wait until rising_edge(clk_i);
        start_i <= '1';
        wait until rising_edge(clk_i);
        start_i <= '0';
        wait_cycles(clk_i, 1);
        check_equal(done_o, '0', "Should start on single-cycle pulse");
        
      elsif run("test_reset_on_completion") then
        info("Reset on exact completion cycle");
        
        apply_reset(clk_i, arst_i);
        pulse_start(clk_i, start_i);
        expected_cycles := calc_expected_cycles(TB_CLK_FREQ, TB_DELAY);
        wait_cycles(clk_i, expected_cycles - 1);
        
        arst_i <= '1';
        wait_cycles(clk_i, 1);
        check_equal(done_o, '1', "Should be idle during reset");
        arst_i <= '0';
        wait_cycles(clk_i, 2);
        check_equal(done_o, '1', "Should remain idle");
        
      elsif run("test_rapid_reset_toggling") then
        info("Rapid reset toggling");
        
        apply_reset(clk_i, arst_i);
        pulse_start(clk_i, start_i);
        expected_cycles := calc_expected_cycles(TB_CLK_FREQ, TB_DELAY);
        
        -- Wait partway through (use max to ensure at least 2 cycles)
        if expected_cycles > 4 then
          wait_cycles(clk_i, expected_cycles / 2);
        else
          wait_cycles(clk_i, 2);
        end if;
        
        -- Apply rapid reset toggling
        for i in 1 to 3 loop
          arst_i <= '1';
          wait_cycles(clk_i, 1);
          arst_i <= '0';
          wait_cycles(clk_i, 1);
        end loop;
        
        check_equal(done_o, '1', "Should be idle after resets");
        
        -- Verify timer still works after reset stress
        pulse_start(clk_i, start_i);
        wait_cycles(clk_i, 1);  -- Check immediately after start
        check_equal(done_o, '0', "Should work after reset stress");
        
        -- Verify it completes correctly
        cycle_count := 1;
        while done_o = '0' loop
          wait until rising_edge(clk_i);
          cycle_count := cycle_count + 1;
          check(cycle_count < expected_cycles + 10, "Timer should complete");
        end loop;
        
        check(cycle_count >= expected_cycles and cycle_count <= expected_cycles + 3,
              "Completed in " & integer'image(cycle_count) & " cycles (expected " & 
              integer'image(expected_cycles) & ")");
        
      elsif run("test_reset_while_start_high") then
        info("Reset while start_i is high");
        
        apply_reset(clk_i, arst_i);
        wait until rising_edge(clk_i);
        start_i <= '1';
        wait_cycles(clk_i, 2);
        
        arst_i <= '1';
        wait_cycles(clk_i, 2);
        check_equal(done_o, '1', "Should be idle");
        
        arst_i <= '0';
        start_i <= '0';
        wait_cycles(clk_i, 2);
        check_equal(done_o, '1', "Should remain idle");
        
      elsif run("test_initial_state") then
        info("Initial state without reset");
        wait_cycles(clk_i, 5);
        check_equal(done_o, '1', "Should be idle initially");
        
      elsif run("test_continuous_operation") then
        info("Continuous operation (10 runs)");
        
        apply_reset(clk_i, arst_i);
        expected_cycles := calc_expected_cycles(TB_CLK_FREQ, TB_DELAY);
        
        for i in 1 to 10 loop
          pulse_start(clk_i, start_i);
          wait_cycles(clk_i, 1);
          check_equal(done_o, '0', "Run " & integer'image(i) & ": should be counting");
          
          cycle_count := 1;
          while done_o = '0' loop
            wait until rising_edge(clk_i);
            cycle_count := cycle_count + 1;
          end loop;
          check(cycle_count >= expected_cycles and cycle_count <= expected_cycles + 3,
                "Run " & integer'image(i) & ": completed in " & integer'image(cycle_count) & " cycles");
        end loop;
        
        
      elsif run("test_start_during_reset") then
        info("EDGE: Start asserted before reset releases");
        
        apply_reset(clk_i, arst_i);
        
        -- Assert start WITHOUT waiting for clock edge
        start_i <= '1';
        wait for CLK_PERIOD_C / 4;
        
        -- Now assert reset
        arst_i <= '1';
        wait_cycles(clk_i, 2);
        check_equal(done_o, '1', "Should be in reset");
        
        arst_i <= '0';
        start_i <= '0';
        wait_cycles(clk_i, 3);
        check_equal(done_o, '1', "Should remain idle");
        
        -- Verify still works
        pulse_start(clk_i, start_i);
        wait_cycles(clk_i, 5);
        check_equal(done_o, '0', "Should work after edge case");  
        
        elsif run("test_simultaneous_start_reset") then
        info("EDGE: Start and reset simultaneously");
        
        wait until rising_edge(clk_i);
        start_i <= '1';
        arst_i <= '1';
        wait_cycles(clk_i, 2);
        check_equal(done_o, '1', "Reset should dominate");
        
        arst_i <= '0';
        start_i <= '0';
        wait_cycles(clk_i, 2);
        check_equal(done_o, '1', "Should be idle");
        
      elsif run("test_verify_no_overflow") then
        info("VERIFICATION: No overflow during count");
        
        apply_reset(clk_i, arst_i);
        expected_cycles := calc_expected_cycles(TB_CLK_FREQ, TB_DELAY);
        pulse_start(clk_i, start_i);
        
        -- Check at multiple points
        for i in 1 to 5 loop
          if expected_cycles > 20 then
            wait_cycles(clk_i, expected_cycles / 10);
            check_equal(done_o, '0', "Checkpoint " & integer'image(i));
          end if;
        end loop;
        
        -- Wait for completion
        cycle_count := 0;
        while done_o = '0' and cycle_count < (expected_cycles * 2) loop
          wait until rising_edge(clk_i);
          cycle_count := cycle_count + 1;
        end loop;
        check_equal(done_o, '1', "Should complete without overflow");
        
      end if;
      
    
    
    end loop;
    
    stop_clk <= true;
    test_runner_cleanup(runner);
  end process;

  -- Watchdog
  test_runner_watchdog(runner, 100 ms);

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
