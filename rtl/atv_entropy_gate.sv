// ============================================================================
// Module: atv_entropy_gate
// Project: USAxioms Axiomatic Telemetry Verifier (ATV)
// Description: Monitors raw telemetry lines for frozen frames, telemetry clamping,
//              or zero-variance adversarial injections using integer math.
// ============================================================================
module atv_entropy_gate (
    input  logic clk,
    input  logic rst_n,
    input  logic signed [127:0] raw_telemetry_stream,
    output logic                telemetry_spoofed
);

    localparam bit signed [127:0] WAD = 128'd1_000_000_000_000_000_000;
    
    // Threshold for minimum required variation (0.000001 WAD)
    localparam bit signed [127:0] MIN_VARIANCE_THRESHOLD = 128'sd1_000_000_000_000; 
    
    // Sample Window Depth: 4 Cycles
    logic signed [127:0] window [0:3];
    logic signed [127:0] mean;
    logic signed [127:0] diff0, diff1, diff2, diff3;
    logic signed [127:0] total_abs_variance;

    // Shift register logic for telemetry history
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            window[0] <= 128'sd0;
            window[1] <= 128'sd0;
            window[2] <= 128'sd0;
            window[3] <= 128'sd0;
        end else begin
            window[0] <= raw_telemetry_stream;
            window[1] <= window[0];
            window[2] <= window[1];
            window[3] <= window[2];
        end
    end

    // Absolute Deviation Calculation
    always_comb begin
        mean = (window[0] + window[1] + window[2] + window[3]) / 128'sd4;
        
        diff0 = window[0] - mean; if (diff0 < 128'sd0) diff0 = -diff0;
        diff1 = window[1] - mean; if (diff1 < 128'sd0) diff1 = -diff1;
        diff2 = window[2] - mean; if (diff2 < 128'sd0) diff2 = -diff2;
        diff3 = window[3] - mean; if (diff3 < 128'sd0) diff3 = -diff3;

        total_abs_variance = (diff0 + diff1 + diff2 + diff3) / 128'sd4;

        // Trigger spoof flag if data is completely frozen / clamped across window
        // (Ignoring initial reset stabilization phase)
        telemetry_spoofed = (total_abs_variance < MIN_VARIANCE_THRESHOLD) && 
                            (window[3] != 128'sd0);
    end

endmodule
