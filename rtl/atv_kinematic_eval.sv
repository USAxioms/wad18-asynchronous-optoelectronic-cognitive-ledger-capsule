// ============================================================================
// Module: atv_kinematic_eval
// Project: USAxioms Axiomatic Telemetry Verifier (ATV)
// Description: Pure WAD18 Newtonian Kinematic Invariant Filter. Verifies spatial 
//              continuity and bounds acceleration / positional delta jumps.
// ============================================================================
module atv_kinematic_eval (
    input  logic clk,
    input  logic rst_n,
    input  logic signed [127:0] pos_curr,      // Position in WAD18
    input  logic signed [127:0] vel_curr,      // Velocity in WAD18
    input  logic signed [127:0] dt_wad,        // Time delta (dt) in WAD18
    output logic                kinematic_fault
);

    localparam bit signed [127:0] WAD = 128'd1_000_000_000_000_000_000;
    
    // Kinematic Thresholds (Hardcoded in WAD18)
    // Max allowable delta-position jump per step (e.g., 50.0 WAD)
    localparam bit signed [127:0] MAX_POS_DELTA = 128'sd50 * WAD; 
    // Max allowable acceleration limit (e.g., 20.0 WAD m/s^2)
    localparam bit signed [127:0] MAX_ACCEL     = 128'sd20 * WAD;

    // Registers for historical delta evaluation
    logic signed [127:0] pos_prev;
    logic signed [127:0] vel_prev;
    
    // Internal WAD calculation wires
    logic signed [127:0] pos_delta;
    logic signed [127:0] vel_delta;
    logic signed [255:0] accel_full;
    logic signed [127:0] accel_wad;

    // Registered tracking of state space
    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            pos_prev <= 128'sd0;
            vel_prev <= 128'sd0;
        end else begin
            pos_prev <= pos_curr;
            vel_prev <= vel_curr;
        end
    end

    // Combinational Physics Checks
    always_comb begin
        // 1. Calculate Spatial Delta (Absolute magnitude)
        pos_delta = pos_curr - pos_prev;
        if (pos_delta < 128'sd0) pos_delta = -pos_delta;

        // 2. Calculate Velocity Delta (Absolute magnitude)
        vel_delta = vel_curr - vel_prev;
        if (vel_delta < 128'sd0) vel_delta = -vel_delta;

        // 3. Compute Acceleration in WAD18: (vel_delta * WAD) / dt_wad
        if (dt_wad > 128'sd0) begin
            accel_full = vel_delta * WAD;
            accel_wad  = logic' (accel_full / dt_wad);
        end else begin
            accel_wad  = 128'sd0; // Division by zero / zero dt guard
        end

        // 4. Evaluate Newtonian Invariant Breaches
        kinematic_fault = (pos_delta > MAX_POS_DELTA) || 
                          (accel_wad > MAX_ACCEL)     || 
                          (dt_wad <= 128'sd0);
    end

endmodule
