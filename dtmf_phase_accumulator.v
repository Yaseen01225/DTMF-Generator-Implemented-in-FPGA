/*
===============================================================================
 Project       : FPGA-Based DTMF Generator
 Reference IC  : UM95089
 Module        : dtmf_phase_accumulator
 Developer     : Ghulam Yaseen Nangraj
 Date          : 31 October 2026
 Board         : Digilent Arty A7-100T
 Tool          : Xilinx Vivado 2025.2.1
 Language      : Verilog-2005

 Description:
   Implements a 32-bit phase accumulator used as a Numerically
   Controlled Oscillator (NCO).

 Purpose:
   Generates the digital phase progression required to produce
   a sine wave at a selected DTMF frequency.

 Operation:
   1. Reset clears the phase accumulator.
   2. Start clears the phase for a new DTMF digit.
   3. sample_tick enables phase advancement.
   4. The frequency increment controls the output frequency.
   5. The accumulated phase is supplied to the sine lookup table.

 Formula:
   Phase_next = Phase_current + Frequency_increment

   Output Frequency = (Increment × SAMPLE_HZ) / 2^32

===============================================================================
*/

// Defines simulation time units and precision.
// Time unit: 1 ns
// Time precision: 1 ps
`timescale 1ns / 1ps


// ============================================================
// Module Declaration and Port Definitions
// ============================================================

module dtmf_phase_accumulator (

    // --------------------------------------------------------
    // Input Signals
    // --------------------------------------------------------

    input wire clk,              // Main FPGA system clock (100 MHz).

    input wire reset,            // Active-high synchronous reset.
                                 // Clears the phase accumulator.

    input wire sample_tick,      // Sampling enable pulse.
                                 // Allows one phase update per audio sample.

    input wire start,            // Start signal for a new DTMF digit.
                                 // Clears the previous phase value.

    input wire [31:0] increment, // 32-bit phase increment.
                                 // Determines the generated sine-wave frequency.


    // --------------------------------------------------------
    // Output Signal
    // --------------------------------------------------------

    output reg [31:0] phase      // Current 32-bit accumulated phase.
                                 // Its upper 8 bits address the sine LUT.

);


// ============================================================
// Sequential Phase Accumulator Logic
// ============================================================

// This always block executes on every rising edge of clk.
//
// The phase register changes only when one of the following
// conditions occurs:
//   1. reset is HIGH.
//   2. start is HIGH.
//   3. sample_tick is HIGH.
//
// Non-blocking assignments (<=) are used for sequential logic.

always @(posedge clk) begin


    // --------------------------------------------------------
    // 1. Reset Operation
    // --------------------------------------------------------

    // Check whether the reset signal is asserted.
    //
    // If reset is HIGH:
    //   - Clear the phase register.
    //   - Set the oscillator phase to zero.
    //
    // Reset has the highest priority.

    if (reset)

        phase <= 32'd0;


    // --------------------------------------------------------
    // 2. Start Operation
    // --------------------------------------------------------

    // Check whether a new DTMF digit is starting.
    //
    // If start is HIGH:
    //   - Clear the previous phase value.
    //   - Begin the new digit from phase zero.
    //
    // Start has priority over sample_tick.

    else if (start)

        phase <= 32'd0;


    // --------------------------------------------------------
    // 3. Normal Phase Accumulation
    // --------------------------------------------------------

    // Update the phase only when a new audio sample
    // timing pulse is received.
    //
    // The selected frequency increment is added to
    // the current phase value.

    else if (sample_tick)

        // Phase_next = Phase_current + Increment
        //
        // A larger increment produces a higher frequency.
        // A smaller increment produces a lower frequency.
        //
        // The result is stored in the 32-bit phase register.
        //
        // Any carry beyond bit 31 is discarded.
        // This creates natural modulo-2^32 phase wraparound.
        phase <= phase + increment;


    // --------------------------------------------------------
    // 4. Hold Operation
    // --------------------------------------------------------

    // If reset, start and sample_tick are all LOW:
    //   - No new value is assigned to phase.
    //   - The previous phase value is retained.
    //
    // This prevents the phase from changing between
    // audio sampling events.

end


// ============================================================
// End of Module
// ============================================================

endmodule