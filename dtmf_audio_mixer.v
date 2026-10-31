//==============================================================
// Project      : FPGA DTMF Generator
// Module       : dtmf_audio_mixer
// Developer    : Ghulam Yaseen Nangraj
// Reference IC : UM95089 (Functional Reference Only)
// Date         : 31 October 2026
// Description  : DTMF mixer with 30% amplitude per component
// Platform     : Digilent Arty A7-100T
// FPGA         : Artix-7 XC7A100T
// Tool         : Xilinx Vivado 2025.2.1
// Language     : Verilog-2005
//==============================================================

module dtmf_audio_mixer (

    // ---------------------------------------------------------
    // Input Signals
    // ---------------------------------------------------------

    // Low-frequency sine-wave component.
    // DTMF low-group frequencies:
    // 697 Hz, 770 Hz, 852 Hz and 941 Hz.
    input wire signed [15:0] low_sine,

    // High-frequency sine-wave component.
    // DTMF high-group frequencies:
    // 1209 Hz, 1336 Hz and 1477 Hz.
    input wire signed [15:0] high_sine,

    // Enables or disables the complete DTMF audio output.
    // 1 = Output the mixed tone.
    // 0 = Force audio output to zero.
    input wire tone_enable,


    // ---------------------------------------------------------
    // Output Signal
    // ---------------------------------------------------------

    // Final signed 16-bit audio sample.
    // Positive and negative values represent waveform amplitude.
    output reg signed [15:0] audio_out

);


    // ---------------------------------------------------------
    // Sign Extension: 16 Bits to 17 Bits
    // ---------------------------------------------------------
    //
    // Both sine-wave inputs are signed 16-bit numbers.
    //
    // Before scaling, they are extended to 17 bits.
    //
    // The most significant bit (sign bit) is copied into
    // the new bit position.
    //
    // This preserves the original positive or negative value.
    //
    // Example:
    // 16-bit input = 0000 0000 0000 1010
    // 17-bit value = 0 0000 0000 0000 1010
    //
    // For a negative input, the new bit is also 1.
    // ---------------------------------------------------------

    wire signed [16:0] low_extended;
    wire signed [16:0] high_extended;

    assign low_extended  = {low_sine[15], low_sine};
    assign high_extended = {high_sine[15], high_sine};


    // ---------------------------------------------------------
    // Amplitude Scaling
    // ---------------------------------------------------------
    //
    // Each frequency component is scaled independently.
    //
    // Current scaling formula:
    //
    // Scaled amplitude = Original amplitude x 3 / 10
    //
    // Therefore:
    //
    // 3 / 10 = 0.30 = 30%
    //
    // Each sine-wave component contributes approximately
    // 30% of its original amplitude to the mixer.
    //
    // The final output is the sum of both scaled components.
    //
    // Previous scaling alternatives:
    //
    // / 5  = 20%
    // / 10 = 10%
    //
    // These alternatives are kept commented as in the
    // original design.
    // ---------------------------------------------------------

    wire signed [16:0] low_scaled;
    wire signed [16:0] high_scaled;

    // Previous scaling options:
    // assign low_scaled  = low_extended / 5;
    // assign high_scaled = high_extended / 5;

    // Apply 30% amplitude scaling to the low-frequency signal.
    assign low_scaled = (low_extended * 3) / 10;

    // Apply 30% amplitude scaling to the high-frequency signal.
    assign high_scaled = (high_extended * 3) / 10;


    // ---------------------------------------------------------
    // Add the Two Frequency Components
    // ---------------------------------------------------------
    //
    // A DTMF signal consists of two simultaneous frequencies:
    //
    // 1. One low-frequency component.
    // 2. One high-frequency component.
    //
    // These two signals must be added to create the final tone.
    //
    // Each scaled signal is 17 bits wide.
    //
    // Both signals are sign-extended to 18 bits before addition.
    //
    // This provides an extra bit for the addition and helps
    // prevent overflow during the mixing operation.
    // ---------------------------------------------------------

    wire signed [17:0] mixed_value;

    assign mixed_value =
        {low_scaled[16], low_scaled} +
        {high_scaled[16], high_scaled};


    // ---------------------------------------------------------
    // Final Audio Output and Saturation
    // ---------------------------------------------------------
    //
    // The final output is a signed 16-bit audio sample.
    //
    // Valid signed 16-bit range:
    //
    // Minimum = -32768
    // Maximum = +32767
    //
    // Saturation prevents the output from wrapping around
    // if the mixed result exceeds this range.
    //
    // tone_enable controls whether the audio is passed
    // to the output or replaced with silence.
    // ---------------------------------------------------------

    always @(*) begin


        // -----------------------------------------------------
        // Silence Condition
        // -----------------------------------------------------
        //
        // When tone_enable is LOW:
        // Force the audio output to zero.
        //
        // This prevents any tone from appearing during
        // the silence interval.
        // -----------------------------------------------------

        if (!tone_enable)

            audio_out = 16'sd0;


        // -----------------------------------------------------
        // Positive Saturation
        // -----------------------------------------------------
        //
        // If the mixed value exceeds +32767:
        // Limit the output to the maximum positive value.
        //
        // This prevents positive overflow.
        // -----------------------------------------------------

        else if (mixed_value > 18'sd32767)

            audio_out = 16'sd32767;


        // -----------------------------------------------------
        // Negative Saturation
        // -----------------------------------------------------
        //
        // If the mixed value is below -32768:
        // Limit the output to the minimum negative value.
        //
        // This prevents negative overflow.
        // -----------------------------------------------------

        else if (mixed_value < -18'sd32768)

            audio_out = -16'sd32768;


        // -----------------------------------------------------
        // Normal Output
        // -----------------------------------------------------
        //
        // If the mixed value is within the valid 16-bit range,
        // copy its lower 16 bits to the audio output.
        //
        // Because the value is already within range,
        // this preserves the correct signed result.
        // -----------------------------------------------------

        else

            audio_out = mixed_value[15:0];

    end

endmodule