# Synthesis Analysis (Yosys)

This document summarizes why the timer successfully synthesizes using Yosys + GHDL and what the generated netlist confirms about the RTL.
Although the generics used here are in the optimal range(edge cases not tested)

---

## 1. Successful Elaboration

The wrapper (`timer_wrapper.vhd`) provides fixed generics, avoiding the GHDL limitation where command‑line generics are ignored. 
Yosys fully elaborates the design with no unresolved parameters or unsupported constructs.

---

## 2. Clean Flip‑Flop Inference

The netlist shows:

- a 7‑bit counter (`cnt_r`)
- a busy flag (`busy_r`)
- a delayed start register (`start_d_r`)

All registers use `posedge clk_i` with `posedge arst_i`, confirming:

- synchronous logic 
- asynchronous reset preserved 
- no latches or gated clocks 

---

## 3. Correct Counter Width

For 100 MHz and 1 µs, Yosys infers:
reg [6:0] cnt_r


This matches the expected cycle count and proves the integer cycle‑calculation and bit‑width estimation are correct. (Which was suggested already in the lab tests)

---

## 4. Start‑Pulse Detection Preserved

The synthesized logic contains:
start_i & ~start_d_r

This confirms the rising‑edge detector is implemented exactly as intended.

---

## 5. Pure Combinational Logic

The increment and terminal‑count logic are synthesized into clean combinational expressions. 
There are:

- no combinational loops 
- no multi‑driver nets 
- no tri‑states 

---

## 6. Overall Conclusion

The Yosys synthesis is a success. 
The generated netlist demonstrates that:

- the RTL is fully synthesizable 
- the architecture is preserved 
- the cycle computation and counter width are correct 





