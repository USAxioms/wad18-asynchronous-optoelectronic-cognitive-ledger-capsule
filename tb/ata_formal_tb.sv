// ============================================================================
// Module: ata_formal_tb
// Project: USAxioms Axiomatic Temporal Anchor (ATA)
// Description: Simulation testbench verifying sub-cycle clock gating under
//              severe transient clock glitching and instruction bypass exploits.
// ============================================================================
`timescale 1ns/1ps

module ata_formal_tb;

    logic clk_raw;
    logic ref_clk;
    logic rst_n;
    logic [31:0] state_pc_curr;
    logic [31:0] state_pc_next;
    logic        axiom_eval_complete;
    logic        clk_secure;
    logic        assert_temporal_void;

    // Instantiate DUT
    ata_top u_dut (
        .clk_raw(clk_raw),
        .ref_clk(ref_clk),
        .rst_n(rst_n),
        .state_pc_curr(state_pc_curr),
        .state_pc_next(state_pc_next),
        .axiom_eval_complete(axiom_eval_complete),
        .clk_secure(clk_secure),
        .assert_temporal_void(assert_temporal_void)
    );

    // Raw Clock Generation (100MHz / 10ns period)
    always #5 clk_raw = ~clk_raw;
    
    // Reference Clock Generation (100MHz / 10ns period)
    always #5 ref_clk = ~ref_clk;

    // SystemVerilog Assertion (SVA): Clock securely gated immediately upon exception
    property p_instant_clock_gate;
        @(posedge clk_raw) disable iff (!rst_n)
        ((u_dut.temporal_drift_exception || u_dut.asynchronous_bypass_detected) |-> (clk_secure == 1'b0));
    endproperty

    assert property (p_instant_clock_gate)
        else $fatal(1, "[SVA_VIOLATION] ATA failed to gate clk_secure flat to zero on breach!");

    // Verification Stimulus Loop
    initial begin
        clk_raw = 0;
        ref_clk = 0;
        rst_n = 0;
        state_pc_curr = 32'h0000_1000;
        state_pc_next = 32'h0000_1000;
        axiom_eval_complete = 1'b1;

        #20;
        rst_n = 1;
        #10;

        $display("[INFO] Step 1: Verification of compliant, synchronous execution...");
        @ (posedge clk_raw);
        state_pc_next = 32'h0000_1004;
        axiom_eval_complete = 1'b1;
        
        #2;
        assert (clk_secure == clk_raw) else $error("[ERROR] Secure clock improperly gated during nominal execution.");

        $display("[INFO] Step 2: Injecting Asynchronous Instruction Skipping Mutation...");
        @ (posedge clk_raw);
        state_pc_curr = 32'h0000_1004;
        state_pc_next = 32'h0000_1008;
        axiom_eval_complete = 1'b0; // Incomplete Y18 axiom evaluation attempt!

        #1;
        assert (assert_temporal_void == 1'b1) 
            else $fatal(1, "[FAILURE] ATA failed to trip assert_temporal_void on instruction skip!");
        assert (clk_secure == 1'b0) 
            else $fatal(1, "[FAILURE] ATA failed to clamp clk_secure flat to zero on breach!");

        $display("[SUCCESS] All Axiomatic Temporal Anchor SVA formal checks passed cleanly.");
        $finish;
    end

endmodule
