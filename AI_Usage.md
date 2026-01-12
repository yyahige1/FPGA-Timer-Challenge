# AI Usage Disclosure

This document discloses the use of AI assistants during this project, as required by the challenge guidelines.

## Tools Used

**Claude (Anthropic)** - Used for assistance with specific parts of the assignment.

## Parts Where AI Was Used

### 1. PSL Formal Verification (Stretch Goal)

AI assistance was used for:
- Writing PSL property syntax for the formal verification assertions
- Creating SymbiYosys configuration files with help from official documentation(`.sby`)
- Structuring the `timer_formal.vhd` file with embedded PSL comments
- Documentation (README files for the psl/ directory)

### 2. Documentation

AI assistance was used for:
- README formatting and structure
- Explaining PSL syntax in documentation

## Parts Where AI Was NOT Used

- **Core timer design (`timer.vhd`)** - Written independently
- **Testbench logic (`tb_timer.vhd`, `tb_timer_long.vhd`)** - Written independently
- **VUnit test runner scripts** - Written independently
- **Synthesis scripts** - Written independently
- **CI/CD pipeline configuration** - Written independently
- **Design decisions and limits** - Determined independently

## Verification of AI-Generated Code

All AI-generated code was verified through the following methods:

### PSL Formal Verification Code

1. **Syntax Verification**: Ran `ghdl -a --std=08 -fpsl timer_formal.vhd` to verify VHDL and PSL syntax was correct

2. **Functional Verification**: Executed SymbiYosys with all three modes:
   - `make bmc` - Bounded model checking passed
   - `make prove` - Unbounded proving passed
   - `make cover` - Coverage analysis confirmed all states reachable

3. **Manual Review**: Reviewed each PSL property against the timer specification to ensure it captured the intended behavior:
   - `PROP_DONE_AT_MAX` - Verified this correctly captures the requirement that `done_o` asserts after the exact cycle count
   - `PROP_COUNTER_BOUNDED` - Verified counter bounds match `CYCLES_C`
   - All other properties reviewed for correctness

4. **Interface Verification**: Confirmed `timer_formal.vhd` uses identical interface to original `timer.vhd`:
   - `clk_freq_hz_g : natural`
   - `delay_g : time` (VHDL physical type preserved)

5. **Logic Verification**: Confirmed the RTL logic in `timer_formal.vhd` is identical to `timer.vhd` - only PSL assertions and helper signals were added

### Documentation

1. **Technical Accuracy**: Verified all documented commands work as described
2. **Property Descriptions**: Cross-referenced property descriptions against actual PSL code

## Issues Encountered

During the PSL development, I initially used the same entity with the time variable but then encoutered parsing errors. I initially thought that the issues stemmed from the time variable that was not fully supported as I encountered a similar problem in my synthesis script (Could not pass time variable parameters) or the sweep script(Which caused to use sed to change the values). Surprisingly, I changed the natural type to time and it worked as seamlessly as with the natural type so I reverted back to the time generic.

## Conclusion

AI assistance was limited to the stretch goal (formal verification) and documentation. The core timer implementation and test infrastructure were developed independently. All AI-generated code was verified through simulation, formal verification, and manual review before integration.
