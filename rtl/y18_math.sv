// Module A: Y18 fixed-point math unit (value = integer / 10^18). Total, combinational, no floats.
module y18_math #(parameter int W = 128) (
  input  logic signed [W-1:0] a, b,
  output logic signed [W-1:0] sum, diff, prod,
  output logic ovf_add, ovf_sub, ovf_mul
);
  logic signed [W:0]     s_ext, d_ext;
  logic signed [2*W-1:0] p_full, p_scaled;
  assign s_ext = {a[W-1], a} + {b[W-1], b};
  assign d_ext = {a[W-1], a} - {b[W-1], b};
  assign sum   = s_ext[W-1:0];
  assign diff  = d_ext[W-1:0];
  assign ovf_add = (s_ext[W] != s_ext[W-1]);
  assign ovf_sub = (d_ext[W] != d_ext[W-1]);
  // exact 2W-bit product, then exact division by WAD (truncation toward zero)
  assign p_full   = $signed(a) * $signed(b);
  assign p_scaled = p_full / 256'sd1000000000000000000;
  assign prod     = p_scaled[W-1:0];
  assign ovf_mul  = (p_scaled[2*W-1:W-1] != {(W+1){1'b0}}) && (p_scaled[2*W-1:W-1] != {(W+1){1'b1}});
endmodule
