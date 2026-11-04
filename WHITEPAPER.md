# Y18 Axiomatic Safety Core (ASC) — Capsule v1.0.0

## 1. Framework
Values are signed 128-bit integers n denoting n/10^18 (WAD). No floating point exists anywhere (RTL, model, tooling).
All operations are total: overflow never traps, it raises a flag; flags feed the **undecidable** predicate.

## 2. Proofs (sketch)
- **P1 Exact add/sub.** Operands are sign-extended to W+1 bits; the true sum lies in [-2^W, 2^W-2], so it is represented exactly. Overflow ⇔ top two bits differ. Hence sum is exact whenever ovf_add=0.
- **P2 Multiplication.** Product of two W-bit signed integers fits in 2W bits, so a*b is exact. Result = trunc(a*b / 10^18), error < 1 unit (10^-18) toward zero; matches the Python model `mul`. Overflow ⇔ result outside [-2^127, 2^127-1] ⇔ bits [2W-1:W-1] not all equal.
- **P3 Totality.** Every module is purely combinational except one latch; every input has a defined output; no division by variable, no loops with data-dependent bounds.
- **P4 Fail-safe halt.** halt = latched ∨ unsafe ∨ undecidable. Combinational ⇒ asserted in the same cycle as the offending input (before the next edge); latch makes it sticky until reset. Unknown (!in_valid) or any overflow ⇒ halt (decidability boundary treated as unsafe).
- **P5 Determinism.** Integer-only semantics are bit-identical across simulators/synthesis; the Python model has no floats.

## 3. Architecture
A `y18_math` → B `y18_axiom_eval` (RUAX-1: Σ w_i·s_i ≤ LIMIT; RUAX-2: SMIN ≤ s_i ≤ SMAX; placeholders 100/50/-50 WAD) → C `asc_top` (latch + SVA under `ASC_SVA`) → D `asc_tb`.

## 4. Verification status (honest)
Executed: ledger hash-chain verify, integer model. **Not executed (no simulator in build sandbox):** RTL simulation, SVA, mutation suite (12 mutants in tools/mutants.py). Run `./run_all.sh`.
Caveats: RUAX constants are placeholders; the 256-bit constant divider is synthesizable but large — a production design would pipeline it (breaking the zero-latency claim only for the multiplier path, so retain the combinational range checks as the primary trip).
