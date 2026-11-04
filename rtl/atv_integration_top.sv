// ============================================================================
// Module: atv_integration_top
// Project: USAxioms Axiomatic Telemetry Verifier (ATV)
// Description: Peripheral Safety Shield integration top-level block. Routes
//              kinematic faults and adversarial spoofing to physical interrupt pin.
// ============================================================================
module atv_integration_top (
    input  logic clk,
    input  logic rst_n,
    input  logic signed [127:0] pos_curr,
    input  logic signed [127:0] vel_curr,
    input  logic signed [127:0] dt_wad,
    input  logic signed [127:0] raw_telemetry_stream,
    output logic                assert_telemetry_tainted
);

    logic kinematic_fault;
    logic telemetry_spoofed;

    // Instantiate Newtonian Kinematic Evaluator
    atv_kinematic_eval u_kinematic_eval (
        .clk(clk),
        .rst_n(rst_n),
        .pos_curr(pos_curr),
        .vel_curr(vel_curr),
        .dt_wad(dt_wad),
        .kinematic_fault(kinematic_fault)
    );

    // Instantiate Entropy Gate Adversarial Interceptor
    atv_entropy_gate u_entropy_gate (
        .clk(clk),
        .rst_n(rst_n),
        .raw_telemetry_stream(raw_telemetry_stream),
        .telemetry_spoofed(telemetry_spoofed)
    );

    // Peripheral Interrupt Output Assignment: Fails Closed
    assign assert_telemetry_tainted = (kinematic_fault || telemetry_spoofed);

endmodule
