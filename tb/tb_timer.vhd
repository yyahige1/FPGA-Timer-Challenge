library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

library vunit_lib;
context vunit_lib.vunit_context;

entity tb_timer is
  generic (
    runner_cfg : string
  );
end entity tb_timer;

architecture tb of tb_timer is

  signal clk   : std_ulogic := '0';
  signal arst  : std_ulogic := '1';
  signal start : std_ulogic := '0';
  signal done  : std_ulogic;

begin

  -- DUT instance (unused for now)
  dut : entity work.timer
    generic map (
      clk_freq_hz_g => 1_000_000,
      delay_g       => 1 ms
    )
    port map (
      clk_i   => clk,
      arst_i  => arst,
      start_i => start,
      done_o  => done
    );

  -- Clock generation
  clk <= not clk after 500 ns;

  -- VUnit test runner
  main : process
  begin
    test_runner_setup(runner, runner_cfg);

    -- Reset sequence
    arst <= '1';
    wait for 20 ns;
    arst <= '0';

    -- Simple test
    check_equal(1 + 1, 2, "Basic arithmetic sanity check");

    test_runner_cleanup(runner);
    wait;
  end process;

end architecture tb;

