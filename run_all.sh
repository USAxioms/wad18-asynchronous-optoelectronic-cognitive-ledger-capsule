#!/bin/sh
cd "$(dirname "$0")"
python3 tools/ledger.py verify && python3 tests/wad18_model.py
if command -v iverilog >/dev/null; then
  iverilog -g2012 -o sim.out tb/asc_tb.sv rtl/y18_math.sv rtl/y18_axiom_eval.sv rtl/asc_top.sv && vvp sim.out
  python3 tools/mutants.py
else echo "iverilog not found: install it (or use Verilator/commercial SVA tool; define ASC_SVA)"; fi
