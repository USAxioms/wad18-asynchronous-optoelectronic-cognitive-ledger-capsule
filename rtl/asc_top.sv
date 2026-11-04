// Module C: Interceptor. Halt is combinational (same cycle as the violating input) and latched (sticky until reset).
module asc_top #(parameter int W = 128) (
  input  logic clk, rst_n, in_valid,
  input  logic signed [4*W-1:0] s_flat, w_flat,
  output logic assert_safety_halt
);
  logic unsafe, undecidable, latched, viol;
  y18_axiom_eval #(W) ev (.in_valid(in_valid), .s_flat(s_flat), .w_flat(w_flat), .unsafe(unsafe), .undecidable(undecidable));
  assign viol = unsafe | undecidable;
  always_ff @(posedge clk or negedge rst_n)
    if (!rst_n) latched <= 1'b0;
    else if (viol) latched <= 1'b1;
  assign assert_safety_halt = latched | viol;
`ifdef ASC_SVA
  a_same_cycle: assert property (@(posedge clk) viol |-> assert_safety_halt);
  a_sticky:     assert property (@(posedge clk) disable iff (!rst_n) latched |-> assert_safety_halt);
  a_halt_cause: assert property (@(posedge clk) disable iff (!rst_n) assert_safety_halt |-> (viol || latched));
`endif
endmodule
