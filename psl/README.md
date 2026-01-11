# Formal Verification – Initial Commit

This commit introduces the foundation for formal verification of the timer module using **PSL** and **SymbiYosys** (OSS CAD Suite). The goal is to begin with a minimal, focused proof that validates the core functional requirement before expanding to full protocol verification in later commits.

---

## What Was Added

- A dedicated directory for **PSL‑based formal verification**
- A formalized version of the timer (`timer_formal.vhd`)
- A first **SymbiYosys configuration file** (`timer.sby`)
- A `make bmc` target to run bounded model checking
- A **single PSL assertion** capturing the key timing requirement

> **Property proven:**  
> When the timer reaches its internally computed maximum count, `done_o` must be asserted on the next clock cycle.

---

## Scope of This Commit

This initial step focuses on one essential correctness property:

- The timer computes the number of cycles based on `CLK_FREQ_HZ` and `DELAY_NS`
- When `cnt_r = CYCLES_C - 1` and the timer is busy,  
  the next cycle must assert `done_o`
- Reset behavior is intentionally excluded from the proof using an explicit `abort (arst_i = '1')`

This keeps the first proof small, deterministic, and easy to review.

---

## Why Start This Way

The intent of this commit is to:

- Introduce formal verification **incrementally**
- Validate the most critical behavior first
- Keep the PSL block intentionally minimal
- Provide a clean baseline for future proofs
- Ensure the CI pipeline can run formal checks early


---

## How to Run the Check

From the `psl/` directory:

```sh
make bmc

