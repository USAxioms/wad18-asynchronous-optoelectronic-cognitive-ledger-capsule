// Module B: Axiomatic Rule Evaluator (RUAX placeholders: parameterise with real constants).
// RUAX-1: sum(w_i*s_i) <= LIMIT.  RUAX-2: SMIN <= s_i <= SMAX.  undecidable: !in_valid or any overflow.
module y18_axiom_eval #(parameter int W = 128) (
  input  logic in_valid,
  input  logic signed [4*W-1:0] s_flat, w_flat,
  output logic unsafe, undecidable
);
  localparam logic signed [W-1:0] LIMIT = 128'sd100000000000000000000;
  localparam logic signed [W-1:0] SMAX  = 128'sd50000000000000000000;
  localparam logic signed [W-1:0] SMIN  = -128'sd50000000000000000000;
  logic signed [4*W-1:0] pr;
  logic [3:0] ovm;
  genvar i;
  generate for (i = 0; i < 4; i++) begin : g_mul
    logic signed [W-1:0] d_s, d_d; logic d_a, d_b;
    y18_math #(W) m (.a(s_flat[i*W +: W]), .b(w_flat[i*W +: W]), .sum(d_s), .diff(d_d),
                     .prod(pr[i*W +: W]), .ovf_add(d_a), .ovf_sub(d_b), .ovf_mul(ovm[i]));
  end endgenerate
  logic signed [W-1:0] t01, t012, acc, x0, x1, x2, x3, x4, x5;
  logic oa0, oa1, oa2, y0, y1, y2, y3, y4, y5;
  y18_math #(W) a0 (.a(pr[0*W +: W]), .b(pr[1*W +: W]), .sum(t01),  .diff(x0), .prod(x1), .ovf_add(oa0), .ovf_sub(y0), .ovf_mul(y1));
  y18_math #(W) a1 (.a(t01),          .b(pr[2*W +: W]), .sum(t012), .diff(x2), .prod(x3), .ovf_add(oa1), .ovf_sub(y2), .ovf_mul(y3));
  y18_math #(W) a2 (.a(t012),         .b(pr[3*W +: W]), .sum(acc),  .diff(x4), .prod(x5), .ovf_add(oa2), .ovf_sub(y4), .ovf_mul(y5));
  logic range_bad;
  always_comb begin
    range_bad = 1'b0;
    for (int k = 0; k < 4; k++)
      if ($signed(s_flat[k*W +: W]) > SMAX || $signed(s_flat[k*W +: W]) < SMIN) range_bad = 1'b1;
  end
  assign undecidable = !in_valid | (|ovm) | oa0 | oa1 | oa2;
  assign unsafe      = range_bad | (acc > LIMIT);
endmodule
