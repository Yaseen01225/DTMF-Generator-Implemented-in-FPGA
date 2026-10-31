/*
===============================================================================
 Project       : FPGA-Based DTMF Generator
 Reference IC  : UM95089
 Module        : dtmf_key_decoder
 Developer     : Ghulam Yaseen Nangraj
 Date          : 31 October 2026
 Tool          : Xilinx Vivado 2025.2.1
 Language      : Verilog-2005

 Description:
   Decodes the 12 standard telephone keypad keys and generates
   their corresponding low- and high-frequency phase increments.

 Purpose:
   Every valid DTMF key represents a combination of two frequencies:
   one from the low-frequency group and one from the high-frequency group.

   This module converts the selected keypad digit into the two
   phase increment values required by the DDS phase accumulators.

 Key encoding:
   1 to 9 : Numeric keys 1 to 9
   4'hA   : * (Star)
   0      : Numeric key 0
   4'hB   : # (Hash)

   4'hC to 4'hF are treated as invalid keys.

 Frequency groups:

   Low frequencies:
     697 Hz, 770 Hz, 852 Hz, 941 Hz

   High frequencies:
     1209 Hz, 1336 Hz, 1477 Hz

 Note:
   The phase increment values are calculated for a 32-bit phase
   accumulator operating at a 32 kHz sample rate.

===============================================================================
*/

module dtmf_key_decoder (

    // --------------------------------------------------------
    // Input and output ports
    // --------------------------------------------------------

    input [3:0] digit,              // 4-bit keypad digit code.

    output reg key_valid,           // HIGH for a valid DTMF keypad code.

    output reg [31:0] low_increment,  // Phase increment for low frequency.
    output reg [31:0] high_increment // Phase increment for high frequency.

);


// ============================================================
// Combinational Key Decoding Logic
// ============================================================

// This always block executes whenever the input digit changes.
//
// The decoder does not require a clock because it performs
// combinational logic only.
//
// Blocking assignments (=) are used in combinational logic.

always @(*) begin

    // --------------------------------------------------------
    // Default Assignments
    // --------------------------------------------------------

    // Assume the input is valid initially.
    // The default case will change this to zero for invalid keys.
    key_valid = 1'b1;

    // Clear both frequency increments before decoding.
    //
    // These default assignments ensure that all outputs have
    // defined values for every possible input.
    //
    // They also prevent unintended latch inference.
    low_increment  = 32'd0;
    high_increment = 32'd0;


    // --------------------------------------------------------
    // Keypad Frequency Selection
    // --------------------------------------------------------

    // Select the corresponding low- and high-frequency pair
    // according to the supplied 4-bit keypad code.

    case (digit)


        // ====================================================
        // First Row: Keys 1, 2 and 3
        // Low frequency: 697 Hz
        // ====================================================

        4'd1: begin

            // Key 1 = 697 Hz + 1209 Hz.
            low_increment  = 32'd93549756;
            high_increment = 32'd162269233;

        end


        4'd2: begin

            // Key 2 = 697 Hz + 1336 Hz.
            low_increment  = 32'd93549756;
            high_increment = 32'd179314885;

        end


        4'd3: begin

            // Key 3 = 697 Hz + 1477 Hz.
            low_increment  = 32'd93549756;
            high_increment = 32'd198239584;

        end


        // ====================================================
        // Second Row: Keys 4, 5 and 6
        // Low frequency: 770 Hz
        // ====================================================

        4'd4: begin

            // Key 4 = 770 Hz + 1209 Hz.
            low_increment  = 32'd103347651;
            high_increment = 32'd162269233;

        end


        4'd5: begin

            // Key 5 = 770 Hz + 1336 Hz.
            low_increment  = 32'd103347651;
            high_increment = 32'd179314885;

        end


        4'd6: begin

            // Key 6 = 770 Hz + 1477 Hz.
            low_increment  = 32'd103347651;
            high_increment = 32'd198239584;

        end


        // ====================================================
        // Third Row: Keys 7, 8 and 9
        // Low frequency: 852 Hz
        // ====================================================

        4'd7: begin

            // Key 7 = 852 Hz + 1209 Hz.
            low_increment  = 32'd114353504;
            high_increment = 32'd162269233;

        end


        4'd8: begin

            // Key 8 = 852 Hz + 1336 Hz.
            low_increment  = 32'd114353504;
            high_increment = 32'd179314885;

        end


        4'd9: begin

            // Key 9 = 852 Hz + 1477 Hz.
            low_increment  = 32'd114353504;
            high_increment = 32'd198239584;

        end


        // ====================================================
        // Fourth Row: Keys *, 0 and #
        // Low frequency: 941 Hz
        // ====================================================

        4'hA: begin

            // Key * = 941 Hz + 1209 Hz.
            low_increment  = 32'd126298882;
            high_increment = 32'd162269233;

        end


        4'd0: begin

            // Key 0 = 941 Hz + 1336 Hz.
            low_increment  = 32'd126298882;
            high_increment = 32'd179314885;

        end


        4'hB: begin

            // Key # = 941 Hz + 1477 Hz.
            low_increment  = 32'd126298882;
            high_increment = 32'd198239584;

        end


        // ====================================================
        // Invalid Key Handling
        // ====================================================

        default: begin

            // Mark the supplied keypad code as invalid.
            key_valid = 1'b0;

            // Clear both frequency increments.
            // No valid DTMF frequency pair is selected.
            low_increment  = 32'd0;
            high_increment = 32'd0;

        end

    endcase

end


// ============================================================
// End of Module
// ============================================================

endmodule