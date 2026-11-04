// ============================================================================
// Module: asc_top
// Description: Top-Level Silicon Integration Wrapper with Latched Circuit Breaker
// ============================================================================
module asc_top (
    input  logic                clk,
    input  logic                rst_n,
    input  logic signed [127:0] a,
    input  logic signed [127:0] b,
    input  logic [1:0]          op,
    input  logic signed [127:0] telemetry_in,
    output logic signed [127:0] math_result,
    output logic                assert_safety_halt
);

    logic arithmetic_exception;
    logic axiom_violation;
    logic safety_halt_latched;

    // Instantiate WAD18 Fixed-Point Math Engine
    y18_math u_math (
        .a(a),
        .b(b),
        .op(op),
        .result(math_result),
        .arithmetic_exception(arithmetic_exception)
    );

    // Instantiate Constitutional Invariant Checker
    y18_axiom_eval u_axiom_eval (
        .telemetry_in(telemetry_in),
        .arithmetic_exception(arithmetic_exception),
        .axiom_violation(axiom_violation)
    );

    // Latched Circuit Breaker Logic
    // Once assert_safety_halt transitions to high ('1'), it physically latches 
    // and cannot be cleared by external software overrides without a hard hardware reset (rst_n).
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            safety_halt_latched <= 1'b0;
        end else if (axiom_violation) begin
            safety_halt_latched <= 1'b1;
        end
    end

    assign assert_safety_halt = safety_halt_latched || axiom_violation;

endmodule
