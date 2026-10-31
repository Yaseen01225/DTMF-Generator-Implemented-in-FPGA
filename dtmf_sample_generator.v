/*
===============================================================================
 Project       : FPGA-Based DTMF Generator
 Reference IC  : UM95089
 Module        : dtmf_sample_generator
 Developer     : Ghulam Yaseen Nangraj
 Date          : 31 October 2026
 Tool          : Xilinx Vivado 2025.2.1
 Language      : Verilog-2005

 Description:
   Generates a periodic sample enable pulse for the DTMF audio generator.

 Purpose:
   Converts the high-frequency FPGA system clock into a lower-frequency
   sampling enable signal.

   The default system clock is 100 MHz, while the required audio sampling
   frequency is 32 kHz.

 Operation:
   1. Counts incoming system clock cycles.
   2. Compares the counter with the calculated divisor.
   3. Generates a one-clock-cycle sample_tick pulse.
   4. Resets the counter and repeats the process.

 Example:
   CLK_HZ    = 100,000,000 Hz
   SAMPLE_HZ = 32,000 Hz
   DIVISOR   = 3,125 clock cycles

===============================================================================
*/

module dtmf_sample_generator #(

    // Frequency of the FPGA system clock in Hz.
    // Default: 100 MHz for the Arty A7-100T board.
    parameter CLK_HZ = 100000000,

    // Required audio sampling frequency in Hz.
    // Default: 32 kHz or 32,000 samples per second.
    parameter SAMPLE_HZ = 32000

)(

    // --------------------------------------------------------
    // Input and output ports
    // --------------------------------------------------------

    input wire clk,             // Main FPGA system clock.
    input wire reset,           // Active-high synchronous reset.

    output reg sample_tick      // One-clock-cycle sample enable pulse.

);


// ============================================================
// 1. Clock Division Calculation
// ============================================================

// Calculates how many system clock cycles are required
// to generate one audio sampling pulse.
//
// Formula:
//
// DIVISOR = CLK_HZ / SAMPLE_HZ
//
// Example:
//
// DIVISOR = 100,000,000 / 32,000
//         = 3,125
//
// Therefore, one sample_tick pulse is generated after
// every 3,125 system clock cycles.
//
// Note:
// Integer division is used. Exact sample frequency is obtained
// only when CLK_HZ is evenly divisible by SAMPLE_HZ.

localparam DIVISOR = CLK_HZ / SAMPLE_HZ;


// ============================================================
// 2. Counter Declaration
// ============================================================

// This 32-bit register counts the incoming system clock cycles.
//
// It increases by one on every rising edge of clk until it
// reaches DIVISOR - 1.
//
// When the terminal count is reached, the counter is cleared
// and the next sampling interval begins.

reg [31:0] counter;


// ============================================================
// 3. Sequential Clock Divider Logic
// ============================================================

// This always block executes on every rising edge of the
// FPGA system clock.
//
// Non-blocking assignments (<=) are used because counter
// and sample_tick are sequential registers.

always @(posedge clk) begin

    // --------------------------------------------------------
    // Reset Operation
    // --------------------------------------------------------

    // When reset is high:
    // 1. Clear the clock counter.
    // 2. Keep the sample enable output low.
    //
    // This ensures that the sampling process starts from
    // a known state.

    if (reset) begin

        counter     <= 32'd0;   // Clear the clock counter.
        sample_tick <= 1'b0;    // Disable sample pulse.

    end

    // --------------------------------------------------------
    // Normal Sampling Operation
    // --------------------------------------------------------

    else begin

        // Check whether the counter has reached its terminal
        // count (DIVISOR - 1).

        if (counter == DIVISOR - 1) begin

            // Terminal count reached:
            // Clear the counter to start a new sampling period.
            counter <= 32'd0;

            // Generate a HIGH pulse for one system clock cycle.
            // This pulse enables the audio sample update.
            sample_tick <= 1'b1;

        end

        // ----------------------------------------------------
        // Counter Has Not Reached Terminal Count
        // ----------------------------------------------------

        else begin

            // Increment the counter by one on each rising edge.
            counter <= counter + 1'b1;

            // Keep sample_tick LOW between sampling events.
            // This makes the output pulse one clock cycle wide.
            sample_tick <= 1'b0;

        end

    end

end


// ============================================================
// End of Module
// ============================================================

endmodule