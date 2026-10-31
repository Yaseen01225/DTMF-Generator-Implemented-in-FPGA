
/*
===============================================================================
 Project   : FPGA-Based DTMF Generator for EPABX
 Developer : Ghulam Yaseen Nangraj
 Date      : 31 October 2026
 Platform  : Arty A7-100T / Artix-7
 Tool      : Vivado 2025.2.1
 Language  : Verilog-2005

 Architecture:
   1. dtmf_key_decoder
   2. dtmf_sample_generator
   3. dtmf_phase_accumulator
   4. dtmf_sine_lut
   5. dtmf_audio_mixer
   6. dtmf_tone_controller
   7. dtmf_generator_epabx (Top Module)

 Output:
   16-bit signed digital audio at 32 kHz.
===============================================================================
*/


// ============================================================================
// MODULE 1: DTMF KEY DECODER
// Converts a telephone key into two NCO frequency increments.
// ============================================================================

module dtmf_key_decoder
(
    input  wire [3:0] digit,

    output reg  [31:0] low_increment,
    output reg  [31:0] high_increment,

    output reg         key_valid
);

    always @(*) begin

        low_increment  = 32'd0;
        high_increment = 32'd0;
        key_valid      = 1'b1;

        case (digit)

            4'h1: begin
                low_increment  = 32'd93549756;
                high_increment = 32'd162269233;
            end

            4'h2: begin
                low_increment  = 32'd93549756;
                high_increment = 32'd179314885;
            end

            4'h3: begin
                low_increment  = 32'd93549756;
                high_increment = 32'd198239584;
            end

            4'h4: begin
                low_increment  = 32'd103347651;
                high_increment = 32'd162269233;
            end

            4'h5: begin
                low_increment  = 32'd103347651;
                high_increment = 32'd179314885;
            end

            4'h6: begin
                low_increment  = 32'd103347651;
                high_increment = 32'd198239584;
            end

            4'h7: begin
                low_increment  = 32'd114353504;
                high_increment = 32'd162269233;
            end

            4'h8: begin
                low_increment  = 32'd114353504;
                high_increment = 32'd179314885;
            end

            4'h9: begin
                low_increment  = 32'd114353504;
                high_increment = 32'd198239584;
            end

            // A represents the * key.
            4'hA: begin
                low_increment  = 32'd126298882;
                high_increment = 32'd162269233;
            end

            4'h0: begin
                low_increment  = 32'd126298882;
                high_increment = 32'd179314885;
            end

            // B represents the # key.
            4'hB: begin
                low_increment  = 32'd126298882;
                high_increment = 32'd198239584;
            end

            default: begin
                low_increment  = 32'd0;
                high_increment = 32'd0;
                key_valid      = 1'b0;
            end

        endcase

    end

endmodule


// ============================================================================
// MODULE 2: SAMPLE-RATE GENERATOR
// Generates a one-clock enable pulse at 32 kHz.
// ============================================================================

module dtmf_sample_generator
#(
    parameter integer CLK_HZ    = 100000000,
    parameter integer SAMPLE_HZ = 32000
)
(
    input  wire clk,
    input  wire reset,

    output reg  sample_tick
);

    localparam integer DIV_COUNT = CLK_HZ / SAMPLE_HZ;

    reg [31:0] counter;

    always @(posedge clk) begin

        if (reset) begin

            counter     <= 32'd0;
            sample_tick <= 1'b0;

        end

        else begin

            sample_tick <= 1'b0;

            if (counter == DIV_COUNT - 1) begin

                counter     <= 32'd0;
                sample_tick <= 1'b1;

            end

            else begin

                counter <= counter + 1'b1;

            end

        end

    end

endmodule


// ============================================================================
// MODULE 3: PHASE ACCUMULATOR / NCO
// Generates the digital phase for one selected frequency.
// Two instances are used: low-frequency and high-frequency.
// ============================================================================

module dtmf_phase_accumulator
(
    input  wire clk,
    input  wire reset,
    input  wire start,
    input  wire sample_tick,

    input  wire [31:0] phase_increment,

    output reg  [31:0] phase
);

    always @(posedge clk) begin

        if (reset || start) begin

            phase <= 32'd0;

        end

        else if (sample_tick) begin

            phase <= phase + phase_increment;

        end

    end

endmodule


// ============================================================================
// MODULE 4: SINE LUT
// Generates a 256-point sine waveform using 64 quarter-wave entries.
// The phase address is 8 bits.
// ============================================================================

module dtmf_sine_lut
(
    input  wire [7:0] phase_address,

    output reg signed [15:0] sine_value
);

    reg [5:0] index;
    reg negative;
    reg signed [15:0] magnitude;

    always @(*) begin

        // Mirror the quarter-wave table in the second quadrant.
        if (phase_address[6])
            index = 6'd63 - phase_address[5:0];
        else
            index = phase_address[5:0];

        // Determine the negative half of the sine wave.
        negative = phase_address[7];

        case (index)

             0: magnitude = 16'sd0;
             1: magnitude = 16'sd804;
             2: magnitude = 16'sd1608;
             3: magnitude = 16'sd2410;
             4: magnitude = 16'sd3212;
             5: magnitude = 16'sd4011;
             6: magnitude = 16'sd4808;
             7: magnitude = 16'sd5602;
             8: magnitude = 16'sd6393;
             9: magnitude = 16'sd7179;
            10: magnitude = 16'sd7962;
            11: magnitude = 16'sd8739;
            12: magnitude = 16'sd9512;
            13: magnitude = 16'sd10278;
            14: magnitude = 16'sd11039;
            15: magnitude = 16'sd11793;
            16: magnitude = 16'sd12539;
            17: magnitude = 16'sd13279;
            18: magnitude = 16'sd14010;
            19: magnitude = 16'sd14732;
            20: magnitude = 16'sd15446;
            21: magnitude = 16'sd16151;
            22: magnitude = 16'sd16846;
            23: magnitude = 16'sd17530;
            24: magnitude = 16'sd18204;
            25: magnitude = 16'sd18868;
            26: magnitude = 16'sd19519;
            27: magnitude = 16'sd20159;
            28: magnitude = 16'sd20787;
            29: magnitude = 16'sd21403;
            30: magnitude = 16'sd22005;
            31: magnitude = 16'sd22594;
            32: magnitude = 16'sd23170;
            33: magnitude = 16'sd23731;
            34: magnitude = 16'sd24279;
            35: magnitude = 16'sd24811;
            36: magnitude = 16'sd25329;
            37: magnitude = 16'sd25832;
            38: magnitude = 16'sd26319;
            39: magnitude = 16'sd26790;
            40: magnitude = 16'sd27245;
            41: magnitude = 16'sd27683;
            42: magnitude = 16'sd28105;
            43: magnitude = 16'sd28510;
            44: magnitude = 16'sd28898;
            45: magnitude = 16'sd29268;
            46: magnitude = 16'sd29621;
            47: magnitude = 16'sd29956;
            48: magnitude = 16'sd30273;
            49: magnitude = 16'sd30571;
            50: magnitude = 16'sd30852;
            51: magnitude = 16'sd31113;
            52: magnitude = 16'sd31356;
            53: magnitude = 16'sd31580;
            54: magnitude = 16'sd31785;
            55: magnitude = 16'sd31971;
            56: magnitude = 16'sd32137;
            57: magnitude = 16'sd32285;
            58: magnitude = 16'sd32412;
            59: magnitude = 16'sd32521;
            60: magnitude = 16'sd32609;
            61: magnitude = 16'sd32678;
            62: magnitude = 16'sd32728;
            63: magnitude = 16'sd32757;

            default: magnitude = 16'sd0;

        endcase

        if (negative)
            sine_value = -magnitude;
        else
            sine_value = magnitude;

    end

endmodule


// ============================================================================
// MODULE 5: AUDIO MIXER
// Combines low and high DTMF sine waves.
// High-frequency amplitude is approximately 1.25 times low-frequency
// amplitude, giving approximately 1.94 dB pre-emphasis.
// ============================================================================

module dtmf_audio_mixer
(
    input  wire signed [15:0] low_sine,
    input  wire signed [15:0] high_sine,

    output wire signed [15:0] mixed_audio
);

    wire signed [15:0] low_component;
    wire signed [15:0] high_component;

    assign low_component = low_sine >>> 2;

    assign high_component =
        (high_sine >>> 2) + (high_sine >>> 4);

    assign mixed_audio = low_component + high_component;

endmodule


// ============================================================================
// MODULE 6: TONE CONTROLLER
// Controls tone duration, silence duration, busy and done signals.
// ============================================================================

module dtmf_tone_controller
#(
    parameter integer SAMPLE_HZ = 32000,
    parameter integer TONE_MS   = 100,
    parameter integer GAP_MS    = 50
)
(
    input  wire clk,
    input  wire reset,
    input  wire start,
    input  wire sample_tick,

    output reg tone_enable,
    output reg busy,
    output reg done
);

    localparam integer TONE_SAMPLES =
        (SAMPLE_HZ * TONE_MS) / 1000;

    localparam integer GAP_SAMPLES =
        (SAMPLE_HZ * GAP_MS) / 1000;

    reg [31:0] tone_count;
    reg [31:0] gap_count;

    always @(posedge clk) begin

        if (reset) begin

            tone_enable <= 1'b0;
            busy        <= 1'b0;
            done        <= 1'b0;

            tone_count  <= 32'd0;
            gap_count   <= 32'd0;

        end

        else begin

            done <= 1'b0;

            // Start a new digit cycle.
            if (start && !busy) begin

                tone_enable <= 1'b1;
                busy        <= 1'b1;

                tone_count  <= 32'd0;
                gap_count   <= 32'd0;

            end

            else if (sample_tick && tone_enable) begin

                // Count the active tone samples.
                if (tone_count == TONE_SAMPLES - 1) begin

                    tone_enable <= 1'b0;
                    tone_count  <= 32'd0;
                    gap_count   <= 32'd0;

                end

                else begin

                    tone_count <= tone_count + 1'b1;

                end

            end

            else if (sample_tick && busy) begin

                // Count the silence samples.
                if (gap_count == GAP_SAMPLES - 1) begin

                    gap_count <= 32'd0;

                    busy <= 1'b0;
                    done <= 1'b1;

                end

                else begin

                    gap_count <= gap_count + 1'b1;

                end

            end

        end

    end

endmodule


// ============================================================================
// MODULE 7: TOP MODULE
// Connects all DTMF generator modules.
// ============================================================================

module dtmf_generator_epabx
#(
    parameter integer CLK_HZ    = 100000000,
    parameter integer SAMPLE_HZ = 32000,
    parameter integer TONE_MS   = 100,
    parameter integer GAP_MS    = 50
)
(
    input  wire clk,
    input  wire reset,

    input  wire digit_valid,
    input  wire [3:0] digit,

    output reg signed [15:0] audio_out,

    output reg sample_valid,
    output wire busy,
    output wire done
);

    // ------------------------------------------------------------------------
    // Key decoder connections
    // ------------------------------------------------------------------------

    wire [31:0] decoded_low_increment;
    wire [31:0] decoded_high_increment;
    wire key_valid;

    dtmf_key_decoder U_KEY_DECODER
    (
        .digit          (digit),
        .low_increment  (decoded_low_increment),
        .high_increment (decoded_high_increment),
        .key_valid      (key_valid)
    );

    // ------------------------------------------------------------------------
    // Sample generator connections
    // ------------------------------------------------------------------------

    wire sample_tick;

    dtmf_sample_generator
    #(
        .CLK_HZ    (CLK_HZ),
        .SAMPLE_HZ (SAMPLE_HZ)
    )
    U_SAMPLE_GENERATOR
    (
        .clk         (clk),
        .reset       (reset),
        .sample_tick (sample_tick)
    );

    // ------------------------------------------------------------------------
    // Accept a digit only when idle and the key is valid.
    // ------------------------------------------------------------------------

    wire start_digit;

    assign start_digit =
        digit_valid && !busy && key_valid && !reset;

    // Store frequency increments for the accepted digit.
    reg [31:0] low_increment_reg;
    reg [31:0] high_increment_reg;

    always @(posedge clk) begin

        if (reset) begin

            low_increment_reg  <= 32'd0;
            high_increment_reg <= 32'd0;

        end

        else if (start_digit) begin

            low_increment_reg  <= decoded_low_increment;
            high_increment_reg <= decoded_high_increment;

        end

    end

    // ------------------------------------------------------------------------
    // Tone controller connections
    // ------------------------------------------------------------------------

    wire tone_enable;

    dtmf_tone_controller
    #(
        .SAMPLE_HZ (SAMPLE_HZ),
        .TONE_MS   (TONE_MS),
        .GAP_MS    (GAP_MS)
    )
    U_TONE_CONTROLLER
    (
        .clk         (clk),
        .reset       (reset),
        .start       (start_digit),
        .sample_tick (sample_tick),
        .tone_enable (tone_enable),
        .busy        (busy),
        .done        (done)
    );

    // ------------------------------------------------------------------------
    // Low-frequency phase accumulator
    // ------------------------------------------------------------------------

    wire [31:0] low_phase;

    dtmf_phase_accumulator U_LOW_NCO
    (
        .clk             (clk),
        .reset           (reset),
        .start           (start_digit),
        .sample_tick     (sample_tick),
        .phase_increment (low_increment_reg),
        .phase           (low_phase)
    );

    // ------------------------------------------------------------------------
    // High-frequency phase accumulator
    // ------------------------------------------------------------------------

    wire [31:0] high_phase;

    dtmf_phase_accumulator U_HIGH_NCO
    (
        .clk             (clk),
        .reset           (reset),
        .start           (start_digit),
        .sample_tick     (sample_tick),
        .phase_increment (high_increment_reg),
        .phase           (high_phase)
    );

    // ------------------------------------------------------------------------
    // Low-frequency sine LUT
    // ------------------------------------------------------------------------

    wire signed [15:0] low_sine;

    dtmf_sine_lut U_LOW_SINE
    (
        .phase_address (low_phase[31:24]),
        .sine_value    (low_sine)
    );

    // ------------------------------------------------------------------------
    // High-frequency sine LUT
    // ------------------------------------------------------------------------

    wire signed [15:0] high_sine;

    dtmf_sine_lut U_HIGH_SINE
    (
        .phase_address (high_phase[31:24]),
        .sine_value    (high_sine)
    );

    // ------------------------------------------------------------------------
    // Audio mixer
    // ------------------------------------------------------------------------

    wire signed [15:0] mixed_audio;

    dtmf_audio_mixer U_AUDIO_MIXER
    (
        .low_sine    (low_sine),
        .high_sine   (high_sine),
        .mixed_audio (mixed_audio)
    );

    // ------------------------------------------------------------------------
    // Final audio sample output
    // ------------------------------------------------------------------------

    always @(posedge clk) begin

        if (reset) begin

            audio_out    <= 16'sd0;
            sample_valid <= 1'b0;

        end

        else begin

            sample_valid <= 1'b0;

            if (sample_tick) begin

                sample_valid <= 1'b1;

                if (tone_enable)
                    audio_out <= mixed_audio;
                else
                    audio_out <= 16'sd0;

            end

        end

    end

endmodule
