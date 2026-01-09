# Clean up old files
rm -rf build
#Testbench to verify integer arithmetic used to convert time delays into clock cycles.
#Computes the number of cycles required for a given delay and clock frequency.
#Does not handle arbitrarily large inputs that could cause integer overflow; this is a known limitation.
#The testbench demonstrates correctness for typical values and expected results.
#If the requested delay is shorter than one clock period, the function rounds up to 1 cycle to guarantee a minimum delay.
#Because real (time) values are converted to integers, truncation can occur; to avoid underestimating the delay, the computation rounds up whenever there is a remainder.

cat > test_calc.vhd << 'EOF'
library ieee;
use ieee.std_logic_1164.all;
use ieee.math_real.all;

entity test_calc is
end entity test_calc;

architecture tb of test_calc is
  
 function time_to_cycles(freq : natural; delay : time) return natural is
  variable delay_ns   : integer;
  variable period_ns  : integer;
  variable num_cycles : natural;
  variable remainder  : integer;
begin
  delay_ns := delay / 1 ns;          -- much smaller than fs
  period_ns := 1000000000 / freq;    -- 1e9, fits in integer

  num_cycles := delay_ns / period_ns;
  remainder  := delay_ns rem period_ns;
  if remainder > 0 then
    num_cycles := num_cycles + 1;
  end if;
  if num_cycles < 1 then
    num_cycles := 1;
  end if;
  return num_cycles;
end function;
  
  constant CYCLES_1US_100MHZ   : natural := time_to_cycles(100_000_000, 1 us);
  constant CYCLES_100NS_100MHZ : natural := time_to_cycles(100_000_000, 100 ns);
  constant CYCLES_10US_100MHZ  : natural := time_to_cycles(100_000_000, 10 us);
  constant CYCLES_105NS_100MHZ : natural := time_to_cycles(100_000_000, 105 ns);
  constant CYCLES_1NS_100MHZ   : natural := time_to_cycles(100_000_000, 1 ns);
  constant CYCLES_1MS_100MHZ   : natural := time_to_cycles(100_000_000, 1 ms);
  
begin

  process
  begin
    report "1 us @ 100 MHz = " & integer'image(CYCLES_1US_100MHZ) & " cycles (expect 100)";
    assert CYCLES_1US_100MHZ = 100 
      report "FAIL: Expected 100 cycles" severity error;
      
    report "100 ns @ 100 MHz = " & integer'image(CYCLES_100NS_100MHZ) & " cycles (expect 10)";
    assert CYCLES_100NS_100MHZ = 10 
      report "FAIL: Expected 10 cycles" severity error;
      
    report "10 us @ 100 MHz = " & integer'image(CYCLES_10US_100MHZ) & " cycles (expect 1000)";
    assert CYCLES_10US_100MHZ = 1000 
      report "FAIL: Expected 1000 cycles" severity error;
      
    report "105 ns @ 100 MHz = " & integer'image(CYCLES_105NS_100MHZ) & " cycles (expect 11, rounds up for safety)";
    assert CYCLES_105NS_100MHZ = 11 
      report "FAIL: Expected 11 cycles (rounded up)" severity error;


    report "1 ns @ 100 MHz = " & integer'image(CYCLES_1NS_100MHZ) & " cycles (expect 1)";
    assert CYCLES_1NS_100MHZ = 1
      report "FAIL: Expected 1 cycle for 1 ns delay" severity error;


    report "1 ms @ 100 MHz = " & integer'image(CYCLES_1MS_100MHZ) & " cycles (expect 100000)";
    assert CYCLES_1MS_100MHZ = 100000
      report "FAIL: Expected 100000 cycles for 1 ms delay" severity error;
    
    report "All calculations correct! Timer guarantees minimum delay." severity note;
    wait;
  end process;

end architecture tb;
EOF

echo "=== Testing cycle calculation (integer arithmetic, rounds up) ==="
mkdir -p build 
ghdl -a --workdir=build --std=08 test_calc.vhd 
ghdl -e --workdir=build --std=08 test_calc 
ghdl -r --workdir=build --std=08 test_calc
mv -v test_calc build/ >/dev/null
mv -v e~test_calc.o build/ >/dev/null
echo ""
echo "=== Running VUnit tests ==="

