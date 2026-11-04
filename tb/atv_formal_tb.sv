// ============================================================================
// Module: atv_formal_tb
// Project: USAxioms Axiomatic Telemetry Verifier (ATV)
// Description: Assertion-based testbench to verify fail-closed invariants and
//              1-clock cycle drop of execution permissions upon spoof/fault.
// ============================================================================
`timescale 1ns/1ps

module atv_formal_tb;

    logic clk;
    logic rst_n;
    logic signed [127:0] pos_curr;
    logic signed [127:0] vel_curr;
    logic signed [127:0] dt_wad;
    logic signed [127:0] raw_telemetry_stream;
    logic                assert_telemetry_tainted;

    localparam bit signed [127:0] WAD = 128'd1_000_000_000_000_000_000;

    // Instantiate DUT
    atv_integration_top u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .pos_curr(pos_curr),
        .vel_curr(vel_curr),
        .dt_wad(dt_wad),
        .raw_telemetry_stream(raw_telemetry_stream),
        .assert_telemetry_tainted(assert_telemetry_tainted)
    );

    // Clock Generation: 10ns period (100MHz)
    always #5 clk = ~clk;

    // SystemVerilog Assertion (SVA): System Fails Closed Immediately
    property p_fail_closed_on_taint;
        @(posedge clk) disable iff (!rst_n)
        ((u_dut.kinematic_fault || u_dut.telemetry_spoofed) |-> (assert_telemetry_tainted == 1'b1));
    endproperty

    assert property (p_fail_closed_on_taint)
        else $fatal(1, "[SVA_VIOLATION] ATV failed to drive assert_telemetry_tainted HIGH on fault detection!");

    // Stimulus Process
    initial begin
        clk = 0;
        rst_n = 0;
        pos_curr = 0;
        vel_curr = 0;
        dt_wad = 1 * WAD;
        raw_telemetry_stream = 0;

        #20;
        rst_n = 1;
        #10;

        $display("[INFO] Step 1: Testing compliant dynamic sensor telemetry stream...");
        
        // Feed valid continuous stream
        @ (posedge clk);
        pos_curr = 10 * WAD; vel_curr = 5 * WAD; raw_telemetry_stream = 100 * WAD;
        @ (posedge clk);
        pos_curr = 15 * WAD; vel_curr = 5 * WAD; raw_telemetry_stream = 105 * WAD;
        @ (posedge clk);
        pos_curr = 20 * WAD; vel_curr = 5 * WAD; raw_telemetry_stream = 102 * WAD;
        @ (posedge clk);
        pos_curr = 25 * WAD; vel_curr = 5 * WAD; raw_telemetry_stream = 108 * WAD;

        #1;
        assert (assert_telemetry_tainted == 1'b0) 
            else $error("[ERROR] False positive interrupt asserted on normal telemetry stream!");

        $display("[INFO] Step 2: Injecting adversarial spatial jump mutation (impossible kinematic step)...");
        
        @ (posedge clk);
        pos_curr = 500 * WAD; // Discontinuous position jump of 475 WAD (Exceeds MAX_POS_DELTA of 50 WAD)
        
        #1;
        assert (assert_telemetry_tainted == 1'b1) 
            else $fatal(1, "[FAILURE] ATV failed to trip interrupt on spatial discontinuity jump within 1 cycle!");

        $display("[INFO] Step 3: Injecting clamped frozen-frame sensor spoofing attack...");
        // Re-stabilize position
        pos_curr = 505 * WAD;
        
        // Freeze sensor values across 4 cycles
        @ (posedge clk); raw_telemetry_stream = 999 * WAD;
        @ (posedge clk); raw_telemetry_stream = 999 * WAD;
        @ (posedge clk); raw_telemetry_stream = 999 * WAD;
        @ (posedge clk); raw_telemetry_stream = 999 * WAD;

        #1;
        assert (assert_telemetry_tainted == 1'b1) 
            else $fatal(1, "[FAILURE] ATV failed to trip interrupt on clamped sensor stream!");

        $display("[SUCCESS] All ATV SystemVerilog assertion properties passed cleanly.");
        $finish;
    end

endmodule
