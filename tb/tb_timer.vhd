library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_timer is
  generic (
    runner_cfg : string := ""
  );
end entity tb_timer;

architecture tb of tb_timer is

  signal clk   : std_ulogic := '0';
  signal arst  : std_ulogic := '1';
  signal start : std_ulogic := '0';
  signal done  : std_ulogic;

  -- DUT parameters chosen to be easy to reason about:
  constant CLK_FREQ_HZ : natural := 1_000_000;
  constant DELAY_MS    : time    := 1 ms;
  constant CLK_HALF    : time    := 500 ns; -- half period for 1 MHz

  -- Derived expected cycles for checks (kept in testbench)
  constant EXPECTED_CYCLES : natural := 1000;

begin

  ----------------------------------------------------------------------------
  -- DUT instance
  ----------------------------------------------------------------------------
  dut : entity work.timer
    generic map (
      clk_freq_hz_g => CLK_FREQ_HZ,
      delay_g       => DELAY_MS
    )
    port map (
      clk_i   => clk,
      arst_i  => arst,
      start_i => start,
      done_o  => done
    );

  ----------------------------------------------------------------------------
  -- Clock generation (1 MHz)
  ----------------------------------------------------------------------------
  clk_gen : process
  begin
    while true loop
      clk <= '0';
      wait for CLK_HALF;
      clk <= '1';
      wait for CLK_HALF;
    end loop;
  end process clk_gen;

  ----------------------------------------------------------------------------
  -- Test runner process
  ----------------------------------------------------------------------------
  main : process

  begin
    -- Setup VUnit runner
    test_runner_setup(runner, runner_cfg);

    --------------------------------------------------------------------------
    -- Initial reset and sanity checks
    --------------------------------------------------------------------------
    arst <= '1';
    wait for 20 ns;
    check_equal(done, '1', "done should be '1' while async reset asserted");

    arst <= '0';
    wait for 6 * CLK_HALF;
    check_equal(done, '1', "done should remain '1' after reset release (idle)");

    --------------------------------------------------------------------------
    -- Basic start/count test
    --------------------------------------------------------------------------
    wait until rising_edge(clk);
    start <= '1';
    wait until rising_edge(clk);
    start <= '0';

    wait until rising_edge(clk);
    check_equal(done, '0', "done should be '0' after start (timer busy)");

    for i in 1 to EXPECTED_CYCLES - 1 loop
      wait until rising_edge(clk);
    end loop;

    wait until rising_edge(clk);
    check_equal(done, '1', "done should be '1' after expected cycles elapsed");

    --------------------------------------------------------------------------
    -- Asynchronous reset during counting
    --------------------------------------------------------------------------
    wait until rising_edge(clk);
    start <= '1';
    wait until rising_edge(clk);
    start <= '0';

    wait until rising_edge(clk);
    check_equal(done, '0', "done should be '0' after second start (timer busy)");

    arst <= '1';
    wait for 1 ns;
    check_equal(done, '1', "done should be '1' immediately after asserting async reset (no clock)");

    wait for 50 ns;
    arst <= '0';
    wait for 2 * CLK_HALF;
    check_equal(done, '1', "done should be '1' after releasing async reset (idle)");

    --------------------------------------------------------------------------
    -- Restart after reset
    --------------------------------------------------------------------------
    wait until rising_edge(clk);
    start <= '1';
    wait until rising_edge(clk);
    start <= '0';

    for i in 1 to 10 loop
      wait until rising_edge(clk);
    end loop;

    arst <= '1';
    wait for 1 ns;
    check_equal(done, '1', "done should be '1' after async reset during restart");

    arst <= '0';
    wait for 2 * CLK_HALF;



    -- Cleanup VUnit runner
    test_runner_cleanup(runner);

    wait;
  end process main;

end architecture tb;

