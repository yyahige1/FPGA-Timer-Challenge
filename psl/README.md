# Formal Verification – Initial Commit

  
 This commit introduces the initial structure for formal verification using PSL.

  
## What was added

  

- A dedicated directory for **PSL-based formal verification**

- A formal version of the timer (`timer_formal.vhd`)

- A **single PSL property** proving the key functional requirement:

  

> The timer always asserts `done_o` after the correct number of cycles.

  

## Scope of this commit

  

- When the timer reaches its maximum count, `done_o` must be asserted on the next clock cycle.

- Reset behavior is excluded from the proof using an explicit abort condition.

   

## Motivation

  

The goal is to:

- Introduce formal verification incrementally

- Keep the initial proof easy to review and reason about

- Establish a solid base for adding further properties in later commits

  

Future commits will extend this with:

- Input assumptions

- Cover properties for reachability

- Full protocol verification
