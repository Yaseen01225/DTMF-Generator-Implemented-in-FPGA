
`timescale 1ns / 1ps

/*
===============================================================================
 Project       : FPGA-Based DTMF Generator
 Reference IC  : UM95089
 Testbench     : tb_dtmf_generator
 Developer     : Ghulam Yaseen Nangraj
 Date          : 31 October 2026
 Tool          : Xilinx Vivado 2025.2.1
 Language      : Verilog-2005

 Description:
   Self-checking testbench for the FPGA-based DTMF generator.

 Purpose:
   This testbench verifies the frequency decoder, tone generation,
   silence timing, audio output, busy/done signals and recorded samples.

 Reference:
   The UM95089 DTMF generator IC is used as the functional reference
   for the FPGA implementation.

 Tests:
   1. All 12 telephone keypad frequency assignments.
   2. Invalid keypad inputs.
   3. Tone generation for all 12 keys.
   4. Tone duration: 100 ms.
   5. Silence duration: 50 ms.
   6. Total sample count: 4800 per digit.
   7. Audio output activity.
   8. busy and done signals.
   9. Audio recording into a text file.

 Audio recording:
   File       : D:/dtmf_audio.pcm
   Sample rate: 32 kHz
   Format     : Signed decimal samples
===============================================================================
*/

module tb_dtmf_generator;

    // ------------------------------------------------------------
    // SIMULATION PARAMETERS
    // ------------------------------------------------------------

    // Clock frequency used by the testbench.
    // The DUT receives this clock through its clk input.
    localparam integer SIM_CLK_HZ = 320000;

    // Required audio sample rate: 32,000 samples per second.
    localparam integer SAMPLE_HZ = 32000;

    // Duration of each generated DTMF tone in milliseconds.
    localparam integer TONE_MS = 100;

    // Silence duration between consecutive DTMF tones.
    localparam integer GAP_MS = 50;

    // Calculate the number of samples required for a 100 ms tone.
    // Formula: samples = sample rate * duration / 1000.
    // Result: 32000 * 100 / 1000 = 3200 samples.
    localparam integer EXPECTED_TONE_SAMPLES =
        (SAMPLE_HZ * TONE_MS) / 1000;

    // Calculate the number of samples required for 50 ms silence.
    // Result: 32000 * 50 / 1000 = 1600 samples.
    localparam integer EXPECTED_GAP_SAMPLES =
        (SAMPLE_HZ * GAP_MS) / 1000;

    // Calculate the total samples for one complete digit operation.
    // Result: 3200 tone samples + 1600 silence samples = 4800.
    localparam integer EXPECTED_TOTAL_SAMPLES =
        EXPECTED_TONE_SAMPLES + EXPECTED_GAP_SAMPLES;


    // ------------------------------------------------------------
    // TESTBENCH SIGNALS
    // ------------------------------------------------------------

    // reg is used because the testbench drives these signals.
    reg clk;                  // Clock signal connected to the DUT.
    reg reset;                // Reset signal connected to the DUT.
    reg digit_valid;          // Request signal indicating a valid digit.
    reg [3:0] digit;           // 4-bit keypad input.

    // wire is used because these signals are driven by the DUT.
    wire signed [15:0] audio_out; // Signed 16-bit audio sample output.
    wire sample_valid;             // Indicates that audio_out has a new sample.
    wire busy;                     // High while the generator is processing.
    wire done;                     // Indicates completion of one digit.

    // Variables used to maintain the overall test results.
    integer total_passed;     // Number of successful checks.
    integer total_failed;    // Number of unsuccessful checks.
    integer test_number;      // Identifies the current digit test.

    // Variables used to count samples for the current digit.
    integer sample_count;    // Total valid samples for this digit.
    integer active_samples;  // Number of samples generated during the tone.
    integer silent_samples;  // Number of samples generated during silence.

    // File-handling variables.
    integer audio_file;         // File descriptor returned by $fopen.
    integer audio_sample_count; // Total samples written to the audio file.

    // Becomes 1 if at least one non-zero audio sample is detected.
    reg audio_activity;


    // ------------------------------------------------------------
    // DUT INSTANTIATION
    // ------------------------------------------------------------

    // Instantiate the actual DTMF generator module.
    // The testbench supplies its clock, reset and keypad inputs.
    // The DUT produces audio samples and status signals.

    dtmf_generator
    #(
        // Override the DUT clock frequency for this simulation.
        .CLK_HZ    (SIM_CLK_HZ),

        // Set the audio sample rate to 32 kHz.
        .SAMPLE_HZ (SAMPLE_HZ),

        // Set the DTMF tone duration to 100 ms.
        .TONE_MS   (TONE_MS),

        // Set the silence duration to 50 ms.
        .GAP_MS    (GAP_MS)
    )

    DUT

    (
        // Connect testbench clock to DUT clock.
        .clk          (clk),

        // Connect testbench reset to DUT reset.
        .reset        (reset),

        // Connect digit request signal.
        .digit_valid  (digit_valid),

        // Connect 4-bit keypad input.
        .digit        (digit),

        // Receive the generated signed audio sample.
        .audio_out    (audio_out),

        // Receive the audio sample-valid indication.
        .sample_valid (sample_valid),

        // Receive the generator busy indication.
        .busy         (busy),

        // Receive the generator completion indication.
        .done         (done)
    );


    // ------------------------------------------------------------
    // AUDIO FILE INITIALIZATION
    // ------------------------------------------------------------

    initial begin

        // Open the output file in write mode.
        // "w" creates a new file or overwrites an existing file.
        audio_file = $fopen("D:/dtmf_audio.pcm", "w");

        // Initialize the total recorded sample counter.
        audio_sample_count = 0;

        // A file descriptor of zero indicates that opening failed.
        if (audio_file == 0) begin

            // Display the file-opening error.
            $display("ERROR: Cannot open audio file!");

            // Suggest checking the drive and permissions.
            $display("Check the D:/ drive and file permissions.");

            // Stop simulation because recording cannot continue.
            $finish;

        end

        else begin

            // Confirm successful file opening.
            $display("Audio file opened successfully.");

            // Inform the user that recording is starting.
            $display("Recording audio samples...");

        end

    end


    // ------------------------------------------------------------
    // AUDIO RECORDING
    //
    // Purpose:
    // Record every valid audio sample into the output file.
    // Keep the file open while all twelve keypad digits are tested.
    // ------------------------------------------------------------

    always @(posedge clk) begin

        // Record only when the DUT indicates that audio_out is valid.
        // Also ensure that the audio file was successfully opened.
        if ((sample_valid == 1'b1) && (audio_file != 0)) begin

            // Convert the 16-bit audio value to a signed decimal number.
            // %0d writes the value without unnecessary leading spaces.
            $fdisplay(audio_file, "%0d", $signed(audio_out));

            // Increase the total number of recorded samples.
            audio_sample_count = audio_sample_count + 1;

        end

    end


    // ------------------------------------------------------------
    // CLOCK GENERATION
    // ------------------------------------------------------------

    // Generate a continuous clock for the DUT.
    // Clock period = 1 / 320000 = 3.125 microseconds.
    // Half period = 1.5625 microseconds = 1562.5 ns.
    // Therefore, the clock frequency is 320 kHz.

    initial begin

        // Initialize clock to logic LOW.
        clk = 1'b0;

        // Toggle the clock every 1562.5 ns forever.
        // This creates a continuous 320 kHz clock.
        forever #1562.5 clk = ~clk;

    end


    // ------------------------------------------------------------
    // TASK 1: CHECK FREQUENCY DECODER
    // ------------------------------------------------------------

    // Purpose:
    // Check whether the DUT assigns the correct low and high
    // frequency phase increments to a given keypad digit.

    task check_decoder;

        // Keypad digit to be tested.
        input [3:0] test_digit;

        // Expected phase increment for the low-frequency oscillator.
        input [31:0] expected_low;

        // Expected phase increment for the high-frequency oscillator.
        input [31:0] expected_high;

        begin

            // Apply the test digit to the DUT input.
            digit = test_digit;

            // Allow one nanosecond for combinational logic to settle.
            // This lets the decoder outputs update before comparison.
            #1;

            // Check both frequency increments and key validity.
            if ((DUT.low_increment == expected_low) &&
                (DUT.high_increment == expected_high) &&
                (DUT.key_valid == 1'b1)) begin

                // Display a successful decoder test.
                $display("PASS: Decoder key %h", test_digit);

                // Increase the overall successful test count.
                total_passed = total_passed + 1;

            end

            else begin

                // Display a failed decoder test.
                $display("FAIL: Decoder key %h", test_digit);

                // Display the expected and actual low-frequency values.
                $display("  Low expected  = %0d", expected_low);
                $display("  Low actual    = %0d", DUT.low_increment);

                // Display the expected and actual high-frequency values.
                $display("  High expected = %0d", expected_high);
                $display("  High actual   = %0d", DUT.high_increment);

                // Increase the overall failure count.
                total_failed = total_failed + 1;

            end

        end

    endtask


    // ------------------------------------------------------------
    // TASK 2: CHECK INVALID KEYPAD INPUT
    // ------------------------------------------------------------

    // Purpose:
    // Verify that unsupported keypad values are rejected
    // by the DUT frequency decoder.

    task check_invalid_key;

        // Four-bit invalid keypad value to be tested.
        input [3:0] invalid_digit;

        begin

            // Apply the invalid keypad value.
            digit = invalid_digit;

            // Wait for combinational decoder logic to settle.
            #1;

            // The DUT should set key_valid LOW for an invalid key.
            if (DUT.key_valid == 1'b0) begin

                // Display successful rejection.
                $display("PASS: Invalid key %h rejected",
                         invalid_digit);

                // Increase successful test count.
                total_passed = total_passed + 1;

            end

            else begin

                // Display an error if the invalid key was accepted.
                $display("FAIL: Invalid key %h accepted",
                         invalid_digit);

                // Increase failure count.
                total_failed = total_failed + 1;

            end

        end

    endtask


    // ------------------------------------------------------------
    // TASK 3: GENERATE AND VERIFY ONE COMPLETE DTMF DIGIT
    // ------------------------------------------------------------

    // Purpose:
    // Send one keypad request to the DUT.
    // Wait for tone and silence generation to finish.
    // Count samples and verify timing and output activity.

    task test_digit;

        // Four-bit keypad value to be generated.
        input [3:0] test_digit_value;

        begin

            // Increment the number of digit-generation tests.
            test_number = test_number + 1;

            // Print a heading for the current digit test.
            $display("");
            $display("================================================");
            $display("TONE TEST %0d: Key = %h",
                     test_number, test_digit_value);
            $display("================================================");

            // Wait until the DUT is idle.
            // A new digit request should not be sent while busy.
            wait (busy == 1'b0);

            // Wait for a falling clock edge before changing inputs.
            // This avoids changing the request at the DUT sampling edge.
            @(negedge clk);

            // Apply the keypad value.
            digit = test_digit_value;

            // Assert digit_valid to request generation of this digit.
            digit_valid = 1'b1;

            // Wait for the next falling clock edge.
            @(negedge clk);

            // Deassert digit_valid.
            // The DUT has received a one-clock request pulse.
            digit_valid = 1'b0;

            // Wait until the DUT starts processing the digit.
            wait (busy == 1'b1);

            // ----------------------------------------------------
            // INITIALIZE INDIVIDUAL DIGIT COUNTERS
            // ----------------------------------------------------

            // Reset the sample count for this digit only.
            // Do not reset audio_sample_count because it tracks
            // the complete recording of all twelve digits.
            sample_count = 0;

            // Reset the tone sample counter.
            active_samples = 0;

            // Reset the silence sample counter.
            silent_samples = 0;

            // Clear the audio activity flag before this test.
            audio_activity = 1'b0;

            // ----------------------------------------------------
            // COUNT VALID AUDIO SAMPLES
            // ----------------------------------------------------

            // Continue monitoring while the DUT has not completed
            // the current digit operation.
            while (done == 1'b0) begin

                // Examine the signals at each falling clock edge.
                @(negedge clk);

                // Count only samples marked valid by the DUT.
                if (sample_valid == 1'b1) begin

                    // Increase the total sample count for this digit.
                    sample_count = sample_count + 1;

                    // Check whether the DUT is currently generating tone.
                    if (DUT.tone_enable == 1'b1) begin

                        // Count this sample as an active tone sample.
                        active_samples = active_samples + 1;

                        // Check that the audio output is not zero.
                        if (audio_out != 16'sd0)

                            // Record that actual audio activity occurred.
                            audio_activity = 1'b1;

                    end

                    else begin

                        // Count this sample as a silence sample.
                        silent_samples = silent_samples + 1;

                    end

                end

            end

            // ----------------------------------------------------
            // CHECK 1: TOTAL SAMPLE COUNT
            // ----------------------------------------------------

            // Verify that tone plus silence equals 4800 samples.
            if (sample_count == EXPECTED_TOTAL_SAMPLES) begin

                // Report successful total sample count.
                $display("PASS: Total samples = %0d",
                         sample_count);

                // Increase successful test count.
                total_passed = total_passed + 1;

            end

            else begin

                // Report actual and expected total sample counts.
                $display("FAIL: Total samples = %0d, Expected = %0d",
                         sample_count, EXPECTED_TOTAL_SAMPLES);

                // Increase failure count.
                total_failed = total_failed + 1;

            end

            // ----------------------------------------------------
            // CHECK 2: TONE SAMPLE COUNT
            // ----------------------------------------------------

            // Verify that the tone lasts exactly 3200 samples.
            if (active_samples == EXPECTED_TONE_SAMPLES) begin

                // Report successful tone sample count.
                $display("PASS: Tone samples = %0d",
                         active_samples);

                // Increase successful test count.
                total_passed = total_passed + 1;

            end

            else begin

                // Report actual and expected tone sample counts.
                $display("FAIL: Tone samples = %0d, Expected = %0d",
                         active_samples, EXPECTED_TONE_SAMPLES);

                // Increase failure count.
                total_failed = total_failed + 1;

            end

            // ----------------------------------------------------
            // CHECK 3: SILENCE SAMPLE COUNT
            // ----------------------------------------------------

            // Verify that the silence lasts exactly 1600 samples.
            if (silent_samples == EXPECTED_GAP_SAMPLES) begin

                // Report successful silence sample count.
                $display("PASS: Silence samples = %0d",
                         silent_samples);

                // Increase successful test count.
                total_passed = total_passed + 1;

            end

            else begin

                // Report actual and expected silence sample counts.
                $display("FAIL: Silence samples = %0d, Expected = %0d",
                         silent_samples, EXPECTED_GAP_SAMPLES);

                // Increase failure count.
                total_failed = total_failed + 1;

            end

            // ----------------------------------------------------
            // CHECK 4: AUDIO OUTPUT ACTIVITY
            // ----------------------------------------------------

            // Verify that at least one non-zero audio sample
            // was generated during the tone.
            if (audio_activity == 1'b1) begin

                // Report successful audio activity.
                $display("PASS: Audio output activity detected");

                // Increase successful test count.
                total_passed = total_passed + 1;

            end

            else begin

                // Report failure if no non-zero sample was detected.
                $display("FAIL: No audio output activity");

                // Increase failure count.
                total_failed = total_failed + 1;

            end

            // ----------------------------------------------------
            // CHECK 5: BUSY AND DONE SIGNALS
            // ----------------------------------------------------

            // At completion, the DUT is expected to be idle
            // and done should indicate that the operation finished.
            if ((busy == 1'b0) && (done == 1'b1)) begin

                // Report successful status signal check.
                $display("PASS: busy = 0, done = 1");

                // Increase successful test count.
                total_passed = total_passed + 1;

            end

            else begin

                // Report an incorrect completion status.
                $display("FAIL: Incorrect busy/done signals");

                // Increase failure count.
                total_failed = total_failed + 1;

            end

            // Wait for the next falling edge.
            // This allows the done pulse to clear before the next request.
            @(negedge clk);

        end

    endtask


    // ------------------------------------------------------------
    // MAIN TEST SEQUENCE
    // ------------------------------------------------------------

    // This initial block controls the complete simulation.
    // It initializes signals, releases reset, runs all tests,
    // prints the final results and closes the audio file.

    initial begin

        // --------------------------------------------------------
        // INITIALIZE TESTBENCH INPUTS
        // --------------------------------------------------------

        // Assert reset initially.
        reset = 1'b1;

        // Keep the digit request inactive during initialization.
        digit_valid = 1'b0;

        // Initialize keypad input to zero.
        digit = 4'h0;

        // Initialize the overall test counters.
        total_passed = 0;
        total_failed = 0;

        // Initialize the digit test number.
        test_number = 0;

        // Initialize all sample counters.
        sample_count = 0;
        active_samples = 0;
        silent_samples = 0;

        // Clear the audio activity flag.
        audio_activity = 1'b0;

        // --------------------------------------------------------
        // APPLY RESET
        // --------------------------------------------------------

        // Hold reset for five falling clock edges.
        // This gives the DUT time to initialize its internal registers.
        repeat (5) @(negedge clk);

        // Release reset and allow normal operation.
        reset = 1'b0;

        // Print the testbench heading.
        $display("");
        $display("================================================");
        $display("       DTMF GENERATOR SELF-CHECKING TESTBENCH");
        $display("================================================");


        // --------------------------------------------------------
        // TEST GROUP 1: FREQUENCY DECODER
        // --------------------------------------------------------

        // Verify that all twelve valid keypad values
        // produce their expected low and high phase increments.
        $display("");
        $display("TEST GROUP 1: FREQUENCY DECODER");

        // Row 1: Keys 1, 2 and 3 use 697 Hz as the low frequency.
        check_decoder(4'h1, 32'd93549756,  32'd162269233);
        check_decoder(4'h2, 32'd93549756,  32'd179314885);
        check_decoder(4'h3, 32'd93549756,  32'd198239584);

        // Row 2: Keys 4, 5 and 6 use 770 Hz as the low frequency.
        check_decoder(4'h4, 32'd103347651, 32'd162269233);
        check_decoder(4'h5, 32'd103347651, 32'd179314885);
        check_decoder(4'h6, 32'd103347651, 32'd198239584);

        // Row 3: Keys 7, 8 and 9 use 852 Hz as the low frequency.
        check_decoder(4'h7, 32'd114353504, 32'd162269233);
        check_decoder(4'h8, 32'd114353504, 32'd179314885);
        check_decoder(4'h9, 32'd114353504, 32'd198239584);

        // Row 4: Keys *, 0 and # use 941 Hz as the low frequency.
        // A represents * and B represents # in this keypad encoding.
        check_decoder(4'hA, 32'd126298882, 32'd162269233);
        check_decoder(4'h0, 32'd126298882, 32'd179314885);
        check_decoder(4'hB, 32'd126298882, 32'd198239584);


        // --------------------------------------------------------
        // TEST GROUP 2: INVALID KEYPAD INPUTS
        // --------------------------------------------------------

        // Check that unsupported values C, D, E and F
        // are rejected by the frequency decoder.
        $display("");
        $display("TEST GROUP 2: INVALID KEYS");

        check_invalid_key(4'hC);
        check_invalid_key(4'hD);
        check_invalid_key(4'hE);
        check_invalid_key(4'hF);


        // --------------------------------------------------------
        // TEST GROUP 3: TONE GENERATION
        // --------------------------------------------------------

        // Generate all twelve standard DTMF keypad tones.
        // Each call sends one digit request and checks its output.
        $display("");
        $display("TEST GROUP 3: TONE GENERATION");

        // First keypad row.
        test_digit(4'h1);
        test_digit(4'h2);
        test_digit(4'h3);

        // Second keypad row.
        test_digit(4'h4);
        test_digit(4'h5);
        test_digit(4'h6);

        // Third keypad row.
        test_digit(4'h7);
        test_digit(4'h8);
        test_digit(4'h9);

        // Fourth keypad row.
        test_digit(4'hA);  // Represents *
        test_digit(4'h0);  // Represents 0
        test_digit(4'hB);  // Represents #


        // --------------------------------------------------------
        // FINAL TEST SUMMARY
        // --------------------------------------------------------

        // Print the overall simulation test results.
        $display("");
        $display("================================================");
        $display("                 TEST SUMMARY");
        $display("================================================");

        // Display the number of successful checks.
        $display("Total passed : %0d", total_passed);

        // Display the number of failed checks.
        $display("Total failed : %0d", total_failed);

        // If no check failed, report complete success.
        if (total_failed == 0)
            $display("RESULT: ALL TESTS PASSED");

        // Otherwise, report that one or more checks failed.
        else
            $display("RESULT: TESTS FAILED");

        $display("================================================");


        // --------------------------------------------------------
        // CLOSE AUDIO FILE
        // --------------------------------------------------------

        // Close the file only if it was opened successfully.
        // Closing it after all twelve digits ensures that
        // the complete recording is saved.
        if (audio_file != 0) begin

            // Close the audio output file.
            $fclose(audio_file);

            // Display recording completion information.
            $display("");
            $display("AUDIO RECORDING COMPLETED");

            // Display the total number of samples written.
            $display("Total recorded samples: %0d",
                     audio_sample_count);

            // Display the location of the recorded file.
            $display("Audio file: D:/dtmf_audio.pcm");

        end

        // End the simulation.
        $finish;

    end

endmodule
