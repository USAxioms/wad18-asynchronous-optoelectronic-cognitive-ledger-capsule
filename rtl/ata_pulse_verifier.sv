// ============================================================================
// Module: ata_pulse_verifier
// Project: USAxioms Axiomatic Temporal Anchor (ATA)
// Description: Deterministic Clock Watchdog. Measures runtime drift and pulse
//              jitter between system clock and reference oscillator in WAD18.
// ============================================================================
module ata_pulse_verifier (
    input  logic sys_clk,
    input  logic ref_clk,
    input  logic rst_n,
    output logic temporal_drift_exception
);

    // WAD18 Scaling Factor (10^18)
    localparam bit signed [127:0] WAD = 128'd1_000_000_000_000_000_000;

    // Sub-nanosecond Y18 Tolerance Window (Hardcoded in WAD18: 0.05 WAD unit tolerance)
    localparam bit signed [127:0] DRIFT_TOLERANCE_MAX = 128'sd50_000_000_000_000_000; 
    
    // Internal 128-bit counters
    logic signed [127:0] sys_counter;
    logic signed [127:0] ref_counter;
    logic signed [127:0] delta_count;
    logic signed [255:0] ratio_scaled;
    logic signed [127:0] drift_wad;

    // Count system clock ticks between reference pulses
    always_ff @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            sys_counter <= 128'sd0;
        end else begin
            sys_counter <= sys_counter + 128'sd1;
        end
    end

    // Sample and measure ratio against reference clock
    always_ff @(posedge ref_clk or negedge rst_n) begin
        if (!rst_n) begin
            ref_counter <= 128'sd0;
            drift_wad   <= 128'sd0;
        end else begin
            ref_counter <= ref_counter + 128'sd1;
            
            // Calculate scale ratio relative to expected nominal 1:1 parity in WAD18
            delta_count = (sys_counter > ref_counter) ? (sys_counter - ref_counter) : (ref_counter - sys_counter);
            ratio_scaled = delta_count * WAD;
            drift_wad   = logic' (ratio_scaled / 128'sd100); // Normalized jitter step
        end
    end

    // Combinational drift threshold assertion
    always_comb begin
        temporal_drift_exception = (drift_wad > DRIFT_TOLERANCE_MAX);
    end

endmodule
