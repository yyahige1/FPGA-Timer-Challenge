# Clean up old files
rm -rf build
# Create VHDL testbench that checks computed counter widths
cat > test_calc_width.vhd << 'EOF'
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity test_calc_width is
end entity test_calc_width;

architecture tb of test_calc_width is
function time_to_cycles(freq : natural; delay : time) return natural is
    variable delay_ns   : integer;
    variable period_ns  : integer;
    variable num_cycles : natural;
    variable remainder  : integer;
  begin
    -- Convert to nanoseconds (universally supported)
    delay_ns := delay / 1 ns;
    
    -- Clock period in nanoseconds: 1e9 / freq_hz
    -- For typical frequencies:
    --   100 MHz  → 10 ns
    --   1 GHz    → 1 ns
    --   10 GHz   → 0.1 ns (rounds to 0, but we handle it)
    period_ns := 1000000000 / freq;
    
    -- Safety check for very high frequencies
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

  -- Test cases (frequency in Hz, delay as time)
  constant FREQ_100MHZ : natural := 100_000_000;
  constant FREQ_2MHZ   : natural := 2_000_000;

  -- Cases at 100 MHz
  constant CYCLES_1NS_100MHZ   : natural := time_to_cycles(FREQ_100MHZ, 1 ns);
  constant WIDTH_1NS_100MHZ    : natural := ceil_log2(CYCLES_1NS_100MHZ);

  constant CYCLES_100NS_100MHZ : natural := time_to_cycles(FREQ_100MHZ, 100 ns);
  constant WIDTH_100NS_100MHZ  : natural := ceil_log2(CYCLES_100NS_100MHZ);

  constant CYCLES_1US_100MHZ   : natural := time_to_cycles(FREQ_100MHZ, 1 us);
  constant WIDTH_1US_100MHZ    : natural := ceil_log2(CYCLES_1US_100MHZ);

  constant CYCLES_10US_100MHZ  : natural := time_to_cycles(FREQ_100MHZ, 10 us);
  constant WIDTH_10US_100MHZ   : natural := ceil_log2(CYCLES_10US_100MHZ);

  constant CYCLES_105NS_100MHZ : natural := time_to_cycles(FREQ_100MHZ, 105 ns);
  constant WIDTH_105NS_100MHZ  : natural := ceil_log2(CYCLES_105NS_100MHZ);

  constant CYCLES_1MS_100MHZ   : natural := time_to_cycles(FREQ_100MHZ, 1 ms);
  constant WIDTH_1MS_100MHZ    : natural := ceil_log2(CYCLES_1MS_100MHZ);

  -- Case at 2 MHz (different frequency)
  constant CYCLES_1MS_2MHZ     : natural := time_to_cycles(FREQ_2MHZ, 1 ms);
  constant WIDTH_1MS_2MHZ      : natural := ceil_log2(CYCLES_1MS_2MHZ);

begin

  process
  begin
    -- 1 ns @ 100 MHz -> cycles = 1 -> width = 0 (but set to 1 for safety)
    report "1 ns @ 100 MHz: cycles=" & integer'image(CYCLES_1NS_100MHZ) &
           " width=" & integer'image(WIDTH_1NS_100MHZ) & " (expect 1)";
    assert WIDTH_1NS_100MHZ = 1
      report "FAIL: expected width 1 for 1 cycle" severity error;

    -- 100 ns @ 100 MHz -> cycles = 10 -> width = 4
    report "100 ns @ 100 MHz: cycles=" & integer'image(CYCLES_100NS_100MHZ) &
           " width=" & integer'image(WIDTH_100NS_100MHZ) & " (expect 4)";
    assert WIDTH_100NS_100MHZ = 4
      report "FAIL: expected width 4 for 10 cycles" severity error;

    -- 1 us @ 100 MHz -> cycles = 100 -> width = 7
    report "1 us @ 100 MHz: cycles=" & integer'image(CYCLES_1US_100MHZ) &
           " width=" & integer'image(WIDTH_1US_100MHZ) & " (expect 7)";
    assert WIDTH_1US_100MHZ = 7
      report "FAIL: expected width 7 for 100 cycles" severity error;

    -- 10 us @ 100 MHz -> cycles = 1000 -> width = 10
    report "10 us @ 100 MHz: cycles=" & integer'image(CYCLES_10US_100MHZ) &
           " width=" & integer'image(WIDTH_10US_100MHZ) & " (expect 10)";
    assert WIDTH_10US_100MHZ = 10
      report "FAIL: expected width 10 for 1000 cycles" severity error;

    -- 105 ns @ 100 MHz -> cycles = 11 -> width = 4
    report "105 ns @ 100 MHz: cycles=" & integer'image(CYCLES_105NS_100MHZ) &
           " width=" & integer'image(WIDTH_105NS_100MHZ) & " (expect 4)";
    assert WIDTH_105NS_100MHZ = 4
      report "FAIL: expected width 4 for 11 cycles" severity error;

    -- 1 ms @ 100 MHz -> cycles = 100000 -> width = 17
    report "1 ms @ 100 MHz: cycles=" & integer'image(CYCLES_1MS_100MHZ) &
           " width=" & integer'image(WIDTH_1MS_100MHZ) & " (expect 17)";
    assert WIDTH_1MS_100MHZ = 17
      report "FAIL: expected width 17 for 100000 cycles" severity error;

    -- 1 ms @ 2 MHz -> cycles = 2000 -> width = 11
    report "1 ms @ 2 MHz: cycles=" & integer'image(CYCLES_1MS_2MHZ) &
           " width=" & integer'image(WIDTH_1MS_2MHZ) & " (expect 11)";
    assert WIDTH_1MS_2MHZ = 11
      report "FAIL: expected width 11 for 2000 cycles" severity error;

    report "All width calculations correct." severity note;
    wait;
  end process;

end architecture tb;
EOF
mkdir -p build 
echo "=== Testing computed counter widths ==="
ghdl -a --workdir=build --std=08 test_calc_width.vhd 
ghdl -e --workdir=build --std=08 test_calc_width 
ghdl -r --workdir=build --std=08 test_calc_width
mv -v test_calc_width build/ >/dev/null
mv -v e~test_calc_width.o build/ >/dev/null
echo ""
echo "=== Done ==="

