// ============================================================================
// Module: ata_top
// Project: USAxioms Axiomatic Temporal Anchor (ATA)
// Description: Monolithic integration block. Instantly gates clk_secure to zero
//              and asserts assert_temporal_void upon temporal drift or glitch.
// ============================================================================
module ata_top (
    input  logic clk_raw,
    input  logic ref_clk,
    input  logic rst_n,
    input  logic [31:0] state_pc_curr,
    input  logic [31:0] state_pc_next,
    input  logic        axiom_eval_complete,
    output logic        clk_secure,
    output logic        assert_temporal_void
);

    logic temporal_drift_exception;
    logic asynchronous_bypass_detected;
    logic breach_detected;
    logic clk_gate_en;

    // Instantiate Pulse Verifier Watchdog
    ata_pulse_verifier u_pulse_verifier (
        .sys_clk(clk_raw),
        .ref_clk(ref_clk),
        .rst_n(rst_n),
        .temporal_drift_exception(temporal_drift_exception)
    );

    // Instantiate State Sequence Guard
    ata_sequence_guard u_sequence_guard (
        .clk(clk_raw),
        .rst_n(rst_n),
        .state_pc_curr(state_pc_curr),
        .state_pc_next(state_pc_next),
        .axiom_eval_complete(axiom_eval_complete),
        .asynchronous_bypass_detected(asynchronous_bypass_detected)
    );

    // Combinational Interrupt Aggregation
    assign breach_detected = temporal_drift_exception || asynchronous_bypass_detected;

    // Physical Hardware Latched Intercept
    always_ff @(posedge clk_raw or negedge rst_n) begin
        if (!rst_n) begin
            assert_temporal_void <= 1'b0;
        end else if (breach_detected) begin
            assert_temporal_void <= 1'b1;
        end
    end

    // Sub-cycle Integrated Clock-Gating Cell (ICGC) Logic
    // Instantly drops gated secure clock line flat to zero on breach detection
    assign clk_gate_en = !(breach_detected || assert_temporal_void);
    assign clk_secure  = clk_raw & clk_gate_en;

endmodule
