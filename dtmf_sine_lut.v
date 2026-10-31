//==============================================================
// Project      : FPGA DTMF Generator
// Module       : dtmf_sine_lut
// Developer    : Ghulam Yaseen Nangraj
// Reference IC : UM95089 (Functional Reference Only)
// Date         : 31 October 2026
// Description  : 256-point sine lookup table
// Platform     : Digilent Arty A7-100T
// FPGA         : Artix-7 XC7A100T
// Tool         : Xilinx Vivado 2025.2.1
// Language     : Verilog-2005
//==============================================================

module dtmf_sine_lut (

    // 8-bit phase index selects one of 256 sine-wave positions.
    // Range: 0 to 255, representing one complete sine cycle.
    input wire [7:0] phase_index,

    // Signed 16-bit sine-wave amplitude.
    // Positive values represent the positive half-cycle.
    // Negative values represent the negative half-cycle.
    output reg signed [15:0] sine_value
);

    // ---------------------------------------------------------
    // Internal Registers
    // ---------------------------------------------------------

    // Stores the address of the quarter-wave lookup table.
    // Only 65 entries are required because sine symmetry
    // allows us to reconstruct the complete 256-point waveform.
    reg [6:0] quarter_index;

    // Stores the positive amplitude returned by the LUT.
    // Its maximum value is 32767.
    reg [15:0] lut_value;

    // Indicates whether the reconstructed sine value
    // should be positive or negative.
    // 0 = Positive
    // 1 = Negative
    reg negative;


    // ---------------------------------------------------------
    // 65-Entry Quarter-Wave Sine Lookup Table
    // ---------------------------------------------------------
    //
    // A complete sine wave contains four quadrants.
    //
    // However, all four quadrants can be reconstructed
    // using only the first quarter of the sine wave.
    //
    // LUT[i] = round(32767 * sin(pi * i / 128))
    //
    // Index range:
    //     0  = 0 degrees
    //     64 = 90 degrees
    //
    // Amplitude range:
    //     0 to 32767
    //
    // This table stores only positive amplitude values.
    // Negative values are generated separately.
    // ---------------------------------------------------------

    function [15:0] quarter_sine;

        // Seven-bit input selects one of 65 LUT entries.
        input [6:0] index;

        begin

            // Select the sine amplitude according to the index.
            case (index)

                7'd0:  quarter_sine = 16'd0;
                7'd1:  quarter_sine = 16'd804;
                7'd2:  quarter_sine = 16'd1608;
                7'd3:  quarter_sine = 16'd2410;
                7'd4:  quarter_sine = 16'd3212;
                7'd5:  quarter_sine = 16'd4011;
                7'd6:  quarter_sine = 16'd4808;
                7'd7:  quarter_sine = 16'd5602;
                7'd8:  quarter_sine = 16'd6393;
                7'd9:  quarter_sine = 16'd7179;
                7'd10: quarter_sine = 16'd7962;
                7'd11: quarter_sine = 16'd8739;
                7'd12: quarter_sine = 16'd9512;
                7'd13: quarter_sine = 16'd10278;
                7'd14: quarter_sine = 16'd11039;
                7'd15: quarter_sine = 16'd11793;
                7'd16: quarter_sine = 16'd12539;
                7'd17: quarter_sine = 16'd13279;
                7'd18: quarter_sine = 16'd14010;
                7'd19: quarter_sine = 16'd14732;
                7'd20: quarter_sine = 16'd15446;
                7'd21: quarter_sine = 16'd16151;
                7'd22: quarter_sine = 16'd16846;
                7'd23: quarter_sine = 16'd17530;
                7'd24: quarter_sine = 16'd18204;
                7'd25: quarter_sine = 16'd18868;
                7'd26: quarter_sine = 16'd19519;
                7'd27: quarter_sine = 16'd20159;
                7'd28: quarter_sine = 16'd20787;
                7'd29: quarter_sine = 16'd21403;
                7'd30: quarter_sine = 16'd22005;
                7'd31: quarter_sine = 16'd22594;
                7'd32: quarter_sine = 16'd23170;
                7'd33: quarter_sine = 16'd23731;
                7'd34: quarter_sine = 16'd24279;
                7'd35: quarter_sine = 16'd24811;
                7'd36: quarter_sine = 16'd25329;
                7'd37: quarter_sine = 16'd25832;
                7'd38: quarter_sine = 16'd26319;
                7'd39: quarter_sine = 16'd26790;
                7'd40: quarter_sine = 16'd27245;
                7'd41: quarter_sine = 16'd27683;
                7'd42: quarter_sine = 16'd28105;
                7'd43: quarter_sine = 16'd28510;
                7'd44: quarter_sine = 16'd28898;
                7'd45: quarter_sine = 16'd29268;
                7'd46: quarter_sine = 16'd29621;
                7'd47: quarter_sine = 16'd29956;
                7'd48: quarter_sine = 16'd30273;
                7'd49: quarter_sine = 16'd30571;
                7'd50: quarter_sine = 16'd30852;
                7'd51: quarter_sine = 16'd31113;
                7'd52: quarter_sine = 16'd31356;
                7'd53: quarter_sine = 16'd31580;
                7'd54: quarter_sine = 16'd31785;
                7'd55: quarter_sine = 16'd31971;
                7'd56: quarter_sine = 16'd32137;
                7'd57: quarter_sine = 16'd32285;
                7'd58: quarter_sine = 16'd32412;
                7'd59: quarter_sine = 16'd32521;
                7'd60: quarter_sine = 16'd32609;
                7'd61: quarter_sine = 16'd32678;
                7'd62: quarter_sine = 16'd32728;
                7'd63: quarter_sine = 16'd32757;
                7'd64: quarter_sine = 16'd32767;

                // Safety default for an unsupported index.
                default: quarter_sine = 16'd0;

            endcase
        end

    endfunction


    // ---------------------------------------------------------
    // Four-Quadrant Sine-Wave Reconstruction
    // ---------------------------------------------------------
    //
    // The 8-bit phase index is divided into four quadrants.
    //
    // phase_index[7:6] selects the quadrant.
    // phase_index[5:0] selects the position within that quadrant.
    //
    // Quadrant 0:   0 to 90 degrees
    // Quadrant 1:  90 to 180 degrees
    // Quadrant 2: 180 to 270 degrees
    // Quadrant 3: 270 to 360 degrees
    //
    // The sine wave is symmetrical:
    //
    // sin(180 - angle) = sin(angle)
    // sin(180 + angle) = -sin(angle)
    // sin(360 - angle) = -sin(angle)
    //
    // These properties allow us to use the same quarter-wave LUT
    // for all four quadrants.
    // ---------------------------------------------------------

    always @(*) begin

        // Set default values to avoid unintended latch inference.
        quarter_index = 7'd0;
        negative      = 1'b0;


        // -----------------------------------------------------
        // Determine the quadrant and LUT address.
        // -----------------------------------------------------

        case (phase_index[7:6])

            // -------------------------------------------------
            // Quadrant 0: 0 to 90 degrees
            // -------------------------------------------------
            // Use the lower six phase bits directly.
            // Output is positive.
            //
            // Example:
            // phase_index = 8'd32
            // quarter_index = 32
            // -------------------------------------------------

            2'b00: begin
                quarter_index = {1'b0, phase_index[5:0]};
                negative      = 1'b0;
            end


            // -------------------------------------------------
            // Quadrant 1: 90 to 180 degrees
            // -------------------------------------------------
            // The waveform moves backwards through the
            // quarter-wave LUT.
            //
            // Subtract the phase position from 64.
            // Output remains positive.
            //
            // Example:
            // phase_index = 8'd96
            // quarter_index = 64 - 32 = 32
            // -------------------------------------------------

            2'b01: begin
                quarter_index = 7'd64 - {1'b0, phase_index[5:0]};
                negative      = 1'b0;
            end


            // -------------------------------------------------
            // Quadrant 2: 180 to 270 degrees
            // -------------------------------------------------
            // Use the lower six phase bits directly.
            // Output is negative.
            //
            // Example:
            // phase_index = 8'd160
            // quarter_index = 32
            // Output = -LUT[32]
            // -------------------------------------------------

            2'b10: begin
                quarter_index = {1'b0, phase_index[5:0]};
                negative      = 1'b1;
            end


            // -------------------------------------------------
            // Quadrant 3: 270 to 360 degrees
            // -------------------------------------------------
            // The waveform moves backwards through the
            // quarter-wave LUT.
            //
            // Subtract the phase position from 64.
            // Output is negative.
            //
            // Example:
            // phase_index = 8'd224
            // quarter_index = 64 - 32 = 32
            // Output = -LUT[32]
            // -------------------------------------------------

            2'b11: begin
                quarter_index = 7'd64 - {1'b0, phase_index[5:0]};
                negative      = 1'b1;
            end

        endcase


        // -----------------------------------------------------
        // Read the positive amplitude from the quarter-wave LUT.
        // -----------------------------------------------------
        //
        // The function returns a value between 0 and 32767.
        // The selected quadrant determines how this value
        // will be converted into the final signed output.
        // -----------------------------------------------------

        lut_value = quarter_sine(quarter_index);


        // -----------------------------------------------------
        // Apply the correct sign to the LUT amplitude.
        // -----------------------------------------------------
        //
        // {1'b0, lut_value} creates a 17-bit positive value.
        // $signed interprets this value as signed.
        //
        // If negative = 1:
        //     Negate the positive amplitude.
        //
        // If negative = 0:
        //     Keep the positive amplitude.
        //
        // The final result is assigned to the signed 16-bit
        // sine_value output.
        // -----------------------------------------------------

        if (negative)
            sine_value = -$signed({1'b0, lut_value});
        else
            sine_value =  $signed({1'b0, lut_value});

    end

endmodule