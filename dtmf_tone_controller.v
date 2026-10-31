//==============================================================
// Project      : FPGA DTMF Generator
// Module       : dtmf_tone_controller
// Developer    : Ghulam Yaseen Nangraj
// Reference IC : UM95089 (Functional Reference Only)
// Date         : 31 October 2026
// Description  : Controls DTMF tone and silence intervals
// Platform     : Digilent Arty A7-100T
// FPGA         : Artix-7 XC7A100T
// Tool         : Xilinx Vivado 2025.2.1
// Language     : Verilog-2005
//==============================================================

module dtmf_tone_controller #(

    // Number of audio samples generated per second.
    // Default: 32,000 samples per second.
    parameter SAMPLE_HZ = 32000,

    // Duration of each DTMF tone in milliseconds.
    // Default: 100 ms.
    parameter TONE_MS = 100,

    // Silence duration after each DTMF tone in milliseconds.
    // Default: 50 ms.
    parameter GAP_MS = 50

)(
    // ---------------------------------------------------------
    // Input Signals
    // ---------------------------------------------------------

    input wire clk,          // Main FPGA clock (100 MHz).
    input wire reset,        // Synchronous active-high reset.
    input wire start,        // Requests generation of a new tone.
    input wire sample_tick,  // One-clock pulse for each audio sample.

    // ---------------------------------------------------------
    // Output Signals
    // ---------------------------------------------------------

    output reg tone_enable,  // 1 = Generate tone, 0 = Silence.
    output reg busy,         // 1 = Tone generation is in progress.
    output reg done          // One-clock pulse when the operation ends.

);


    // ---------------------------------------------------------
    // Calculate Required Sample Counts
    // ---------------------------------------------------------
    //
    // Number of samples = Sampling frequency x Duration.
    //
    // Tone duration:
    // 32,000 x 100 / 1000 = 3,200 samples.
    //
    // Silence duration:
    // 32,000 x 50 / 1000 = 1,600 samples.
    //
    // Therefore:
    // Total samples per digit = 3,200 + 1,600
    //                         = 4,800 samples.
    // ---------------------------------------------------------

    localparam TONE_SAMPLES =
        (SAMPLE_HZ * TONE_MS) / 1000;

    localparam GAP_SAMPLES =
        (SAMPLE_HZ * GAP_MS) / 1000;


    // ---------------------------------------------------------
    // Sample Counter
    // ---------------------------------------------------------
    //
    // Counts the samples during the tone or silence interval.
    //
    // The same counter is reused for both intervals.
    //
    // It resets when the tone interval finishes and starts
    // counting again for the silence interval.
    // ---------------------------------------------------------

    reg [31:0] sample_count;


    // ---------------------------------------------------------
    // Main Sequential Control Logic
    // ---------------------------------------------------------
    //
    // All control operations are synchronized with the
    // rising edge of the main FPGA clock.
    //
    // sample_tick acts as a clock enable. The counter advances
    // only when sample_tick is high.
    // ---------------------------------------------------------

    always @(posedge clk) begin


        // -----------------------------------------------------
        // Synchronous Reset
        // -----------------------------------------------------
        //
        // Reset all internal control signals.
        //
        // tone_enable = 0 : No audio tone.
        // busy        = 0 : Controller is idle.
        // done        = 0 : No completion indication.
        // -----------------------------------------------------

        if (reset) begin

            sample_count <= 32'd0;

            tone_enable  <= 1'b0;

            busy         <= 1'b0;

            done         <= 1'b0;

        end


        else begin

            // -------------------------------------------------
            // Clear done by default.
            // -------------------------------------------------
            //
            // done is designed as a one-clock-cycle pulse.
            //
            // It becomes high only when the complete tone
            // and silence sequence finishes.
            //
            // Clearing it here ensures that it does not
            // remain high during the next operation.
            // -------------------------------------------------

            done <= 1'b0;


            // -------------------------------------------------
            // Start a New DTMF Tone
            // -------------------------------------------------
            //
            // A new operation starts when:
            //
            // start = 1
            // busy  = 0
            //
            // The controller must be idle before accepting
            // another start request.
            //
            // Actions:
            // 1. Clear the sample counter.
            // 2. Enable the tone output.
            // 3. Set busy to indicate an active operation.
            // -------------------------------------------------

            if (start && !busy) begin

                sample_count <= 32'd0;

                tone_enable  <= 1'b1;

                busy         <= 1'b1;

            end


            // -------------------------------------------------
            // Process Samples While Busy
            // -------------------------------------------------
            //
            // The controller advances only when:
            //
            // busy        = 1
            // sample_tick = 1
            //
            // This ensures that the timing is based on the
            // configured audio sampling frequency rather
            // than the 100 MHz FPGA clock.
            // -------------------------------------------------

            else if (busy && sample_tick) begin


                // =============================================
                // TONE GENERATION INTERVAL
                // =============================================
                //
                // tone_enable = 1 means the DTMF tone is active.
                //
                // Count the required number of tone samples.
                // =============================================

                if (tone_enable) begin


                    // -----------------------------------------
                    // Check Whether Tone Duration Is Complete
                    // -----------------------------------------
                    //
                    // Counter starts at zero.
                    //
                    // For 3,200 samples, the final count is:
                    //
                    // 3,200 - 1 = 3,199
                    //
                    // When this value is reached:
                    // 1. Clear the counter.
                    // 2. Disable the tone.
                    // 3. Move to the silence interval.
                    // -----------------------------------------

                    if (sample_count == TONE_SAMPLES - 1) begin

                        sample_count <= 32'd0;

                        tone_enable  <= 1'b0;

                    end


                    // -----------------------------------------
                    // Tone Interval Is Still Active
                    // -----------------------------------------
                    //
                    // Increment the counter by one sample.
                    // The tone remains enabled.
                    // -----------------------------------------

                    else begin

                        sample_count <= sample_count + 1'b1;

                    end

                end


                // =============================================
                // SILENCE GENERATION INTERVAL
                // =============================================
                //
                // tone_enable = 0 means the tone is disabled.
                //
                // The controller now counts the silence samples.
                // =============================================

                else begin


                    // -----------------------------------------
                    // Check Whether Silence Duration Is Complete
                    // -----------------------------------------
                    //
                    // For 1,600 silence samples, the final
                    // counter value is:
                    //
                    // 1,600 - 1 = 1,599
                    //
                    // When this value is reached:
                    // 1. Clear the counter.
                    // 2. Keep the tone disabled.
                    // 3. Clear busy.
                    // 4. Generate the done pulse.
                    // -----------------------------------------

                    if (sample_count == GAP_SAMPLES - 1) begin

                        sample_count <= 32'd0;

                        tone_enable  <= 1'b0;

                        busy         <= 1'b0;

                        done         <= 1'b1;

                    end


                    // -----------------------------------------
                    // Silence Interval Is Still Active
                    // -----------------------------------------
                    //
                    // Increment the counter by one sample.
                    // The tone remains disabled.
                    // -----------------------------------------

                    else begin

                        sample_count <= sample_count + 1'b1;

                    end

                end

            end

        end

    end

endmodule