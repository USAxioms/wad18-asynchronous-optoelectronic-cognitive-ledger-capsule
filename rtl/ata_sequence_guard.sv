// ============================================================================
// Module: ata_sequence_guard
// Project: USAxioms Axiomatic Temporal Anchor (ATA)
// Description: Monitors state transitions and ensures mandatory Y18 evaluation
//              steps are complete before execution state advances.
// ============================================================================
module ata_sequence_guard (
    input  logic clk,
    input  logic rst_n,
    input  logic [31:0]  state_pc_curr,
    input  logic [31:0]  state_pc_next,
    input  logic         axiom_eval_complete,
    output logic         asynchronous_bypass_detected
);

    localparam bit signed [127:0] WAD = 128'd1_000_000_000_000_000_000;

    logic state_advancing;
    logic illegal_bypass;

    always_comb begin
        // Detect state/PC mutation attempt
        state_advancing = (state_pc_curr != state_pc_next);

        // Fail-closed condition: Attempting to advance state without completing mandatory Y18 evaluation
        illegal_bypass = state_advancing && (!axiom_eval_complete);

        asynchronous_bypass_detected = illegal_bypass;
    end

endmodule
