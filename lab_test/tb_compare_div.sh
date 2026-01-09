# Clean up files
rm -rf build

# Update test with integer arithmetic version and unsigned-64 implementation
cat > test_comp.vhd << 'EOF'
library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;
use ieee.math_real.all;

entity test_comp is
end entity test_comp;

architecture tb of test_comp is

  ------------------------------------------------------------------------------
  -- VERSION 1: Integer (ns) - The "Good" but limited version
  ------------------------------------------------------------------------------
  function time_to_cycles_int_ns(freq : natural; delay : time) return natural is
    variable delay_ns   : integer := delay / 1 ns;
    variable period_ns  : integer := 1000000000 / freq;
    variable num_cycles : natural;
  begin
    num_cycles := delay_ns / period_ns;
    if (delay_ns rem period_ns) > 0 then
      num_cycles := num_cycles + 1;
    end if;
    if num_cycles < 1 then num_cycles := 1; end if;
    return num_cycles;
  end function;

  ------------------------------------------------------------------------------
  -- VERSION 2: Real (Floating Point) - Floating point errors, logs raw value
  ------------------------------------------------------------------------------
  function time_to_cycles_real_risky(freq : natural; delay : time; msg : string) return natural is
    variable delay_s  : real := real(delay / 1 fs) / 1.0e15;
    variable period_s : real := 1.0 / real(freq);
    variable raw_val  : real;
    variable result   : natural;
  begin
    
    raw_val := delay_s / period_s;
    if raw_val < 0.0 then
      result := 1;
    else
      result := natural(raw_val);
      if result < 1 then result := 1; end if;
    end if;
    return result;
  end function;

  ------------------------------------------------------------------------------
  -- VERSION 3: Native Time (64-bit) - uses time arithmetic and returns natural
  ------------------------------------------------------------------------------
  function time_to_cycles_native(freq : natural; delay : time) return natural is
    constant clk_period : time := (1 sec / freq);
    variable num_cycles : natural;
  begin
    num_cycles := delay / clk_period;
    if (delay rem clk_period) > 0 fs then
      num_cycles := num_cycles + 1;
    end if;
    if num_cycles < 1 then num_cycles := 1; end if;
    return num_cycles;
  end function;

  ------------------------------------------------------------------------------
  -- VERSION 4: Unsigned 64-bit cycles - returns unsigned(63 downto 0)
  -- Uses native time arithmetic to avoid 32-bit integer overflow, then converts
  -- to unsigned(64).
  ------------------------------------------------------------------------------
  function time_to_cycles_uint64(freq : natural; delay : time) return unsigned is
    constant clk_period : time := (1 sec / freq);
    variable num_cycles : natural;
    variable result_u   : unsigned(63 downto 0);
  begin
    num_cycles := delay / clk_period;
    if (delay rem clk_period) > 0 fs then
      num_cycles := num_cycles + 1;
    end if;
    if num_cycles < 1 then num_cycles := 1; end if;
    -- convert to unsigned(64)
    result_u := to_unsigned(num_cycles, 64);
    return result_u;
  end function;

begin

  process
    variable v1, v2, v3 : natural;
    variable v4         : unsigned(63 downto 0);
  begin
    ----------------------------------------------------------------------------
    -- CASE: The 3 MHz Precision Cliff (1us delay)
    ----------------------------------------------------------------------------
    report "--- 3 MHz Precision Check ---";
    v1 := time_to_cycles_int_ns(3_000_000, 1 us);
    v2 := time_to_cycles_real_risky(3_000_000, 1 us, "3MHz");
    v3 := time_to_cycles_native(3_000_000, 1 us);
    v4 := time_to_cycles_uint64(3_000_000, 1 us);

    report "Integer(ns): " & integer'image(v1);
    report "Real(risky): " & integer'image(v2);
    report "Native Time: " & integer'image(v3);
    report "Unsigned64: " & integer'image(to_integer(v4));

    assert v3 = 4 report "Native time should correctly round up to 4" severity error;
    assert v2 < v3 report "Real math likely undercounted due to 2.999... truncation" severity note;

    ----------------------------------------------------------------------------
    -- CASE: The 10 Second Overflow Check
    ----------------------------------------------------------------------------
    report "--- 10 Second Overflow Check ---";
    -- We expect Integer(ns) to fail here due to 32-bit wrap-around
    v1 := time_to_cycles_int_ns(100_000_000, 10 sec);
    v2 := time_to_cycles_real_risky(100_000_000, 10 sec, "Overflow");
    v3 := time_to_cycles_native(100_000_000, 10 sec);
    v4 := time_to_cycles_uint64(100_000_000, 10 sec);

    report "Integer(ns) Result: " & integer'image(v1) & " (may overflow)";
    report "Real(risky) Result: " & integer'image(v2);
    report "Native Time Result: " & integer'image(v3) & " (Correct: 1000000000)";
    report "Unsigned64 Result: " & integer'image(to_integer(v4)) & " (as unsigned hex: " & to_hstring(v4) & ")";

    assert v3 = 1000000000 report "Native Time handles 10s delay perfectly" severity error;
    assert v1 /= v3 report "This proves 32-bit integers are insufficient for long delays" severity note;

    ----------------------------------------------------------------------------
    -- CASE: Sub-period safety (5ns @ 100MHz)
    ----------------------------------------------------------------------------
    report "--- Sub-period Safety Check ---";
    v1 := time_to_cycles_int_ns(100_000_000, 5 ns);
    v2 := time_to_cycles_real_risky(100_000_000, 5 ns, "5ns@100MHz");
    v3 := time_to_cycles_native(100_000_000, 5 ns);
    v4 := time_to_cycles_uint64(100_000_000, 5 ns);

    report "5ns @ 100MHz Integer(ns): " & integer'image(v1);
    report "5ns @ 100MHz Real(risky): " & integer'image(v2);
    report "5ns @ 100MHz Native: " & integer'image(v3);
    report "5ns @ 100MHz Unsigned64: " & integer'image(to_integer(v4));

    assert v3 = 1 report "Safety floor failed for native" severity error;
    assert v4 = to_unsigned(1,64) report "Safety floor failed for unsigned64" severity error;

    report "Verification complete. Use Unsigned64 has a higher range but we can't optimize the number of bits needed to hold Count_cycles." severity note;
    wait;
  end process;

end architecture tb;
EOF
mkdir -p build
echo "=== Testing cycle calculation (integer arithmetic, rounds up) ==="
ghdl -a --workdir=build --std=08 test_comp.vhd
ghdl -e --workdir=build --std=08 test_comp
ghdl -r --workdir=build --std=08 test_comp
mv -v test_comp build/ >/dev/null
mv -v e~test_comp.o build/ >/dev/null
echo ""
echo "=== Done ==="

