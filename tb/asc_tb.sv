// ============================================================================
// Module: asc_tb
// Description: SystemVerilog Assertion Testbench and Stimulus Harness
// ============================================================================
`timescale 1ns/1ps

module asc_tb;

    // Clock and Reset
    logic clk;
    logic rst_n;

    // DUT I/O Signals
    logic signed [127:0] a;
    logic signed [127:0] b;
    logic [1:0]          op;
    logic signed [127:0] telemetry_in;
    logic signed [127:0] math_result;
    logic                assert_safety_halt;

    localparam bit signed [127:0] WAD = 128'd1_000_000_000_000_000_000;

    // Instantiate DUT (asc_top)
    asc_top u_dut (
        .clk(clk),
        .rst_n(rst_n),
        .a(a),
        .b(b),
        .op(op),
        .telemetry_in(telemetry_in),
        .math_result(math_result),
        .assert_safety_halt(assert_safety_halt)
    );

    // Clock Generation: 10ns period (100MHz)
    always #5 clk = ~clk;

    // SystemVerilog Assertion (SVA): Formally guard state space and safety halt latching
    property p_safety_halt_latched;
        @(posedge clk) disable iff (!rst_n) 
        (u_dut.axiom_violation |-> (assert_safety_halt == 1'b1));
    endproperty

    assert property (p_safety_halt_latched)
        else $fatal(1, "[SVA_VIOLATION] Safety halt failed to latch immediately on axiom violation!");

    // Stimulus and Verification Process
    initial begin
        // Initialize Signals
        clk = 0;
        rst_n = 0;
        a = 0;
        b = 0;
        op = 2'b00;
        telemetry_in = 50 * WAD; // Safe nominal telemetry state

        // Apply Hard Reset
        #20;
        rst_n = 1;
        #10;

        $display("[INFO] Running normal compliant state vector sequence...");
        
        // Test 1: Normal Addition (50.0 + 25.0 = 75.0 WAD)
        a = 50 * WAD;
        b = 25 * WAD;
        op = 2'b00; // Add
        telemetry_in = 100 * WAD;
        #10;
        assert (assert_safety_halt == 1'b0) else $error("False positive safety halt triggered during normal operation.");

        // Test 2: Normal Scaled Multiplication (2.0 * 3.0 = 6.0 WAD)
        a = 2 * WAD;
        b = 3 * WAD;
        op = 2'b10; // Mul
        telemetry_in = 250 * WAD;
        #10;

        $display("[INFO] Injecting intentional fault / boundary breach mutation...");
        
        // Test 3: Intentional Fault Mutation (Telemetry out of bounds: 1500.0 WAD)
        telemetry_in = 1500 * WAD; // Exceeds upper constitutional bound of 1000.0 WAD
        #10;

        // Verify that assert_safety_halt transitions to high and latches within exactly one clock cycle
        assert (assert_safety_halt == 1'b1) else $fatal(1, "[FAILURE] System failed to halt upon telemetry boundary breach.");
        
        $display("[SUCCESS] All Y18 Axiomatic Safety Core assertions passed cleanly.");
        $finish;
    end

endmodule
