# FPGA-Based DTMF Generator for EPABX

**Project:** Digital DTMF Tone Generator Using Verilog HDL  
**Developer:** Ghulam Yaseen Nangraj  
**Target FPGA:** Xilinx Artix-7 XC7A100T  
**Development Board:** Digilent Arty A7-100T  
**Development Tool:** Xilinx Vivado 2025.2.1  
**HDL:** Verilog-2005  
**System Clock:** 100 MHz  
**Audio Sample Rate:** 32 kHz  

---

## 1. Project Overview

This project implements a Dual-Tone Multi-Frequency (DTMF) generator using Verilog HDL and an FPGA.

DTMF is the signaling method commonly used by telephone keypads. When a user presses a telephone key, two different audio frequencies are generated simultaneously:

- One frequency from the low-frequency group.
- One frequency from the high-frequency group.

The combination of these two frequencies represents a particular telephone key.

The purpose of this project is to develop an FPGA-based alternative to the DTMF generation function of the UM95089 integrated circuit used in an EPABX system.

The design generates digital audio samples that can be supplied to an external DAC or audio codec.

**Important:** The FPGA produces digital samples, not a direct analog telephone signal. An appropriate DAC, reconstruction filter, level-control circuit and protected telephone interface are required.

---

## 2. Project Objectives

The main objectives are:

1. Generate all 12 standard telephone DTMF tones.
2. Generate two frequencies simultaneously.
3. Use independent Numerically Controlled Oscillators (NCOs).
4. Generate accurate digital sine-wave samples.
5. Provide configurable tone and silence durations.
6. Implement a modular and reusable Verilog design.
7. Verify all telephone keys through a self-checking testbench.
8. Provide an FPGA implementation suitable for further EPABX integration.

---

## 3. Supported Telephone Keys

The design supports the standard 12-key telephone keypad.

| Telephone Key | Verilog Input | Low Frequency | High Frequency |
|---|---|---:|---:|
| 1 | 4'h1 | 697 Hz | 1209 Hz |
| 2 | 4'h2 | 697 Hz | 1336 Hz |
| 3 | 4'h3 | 697 Hz | 1477 Hz |
| 4 | 4'h4 | 770 Hz | 1209 Hz |
| 5 | 4'h5 | 770 Hz | 1336 Hz |
| 6 | 4'h6 | 770 Hz | 1477 Hz |
| 7 | 4'h7 | 852 Hz | 1209 Hz |
| 8 | 4'h8 | 852 Hz | 1336 Hz |
| 9 | 4'h9 | 852 Hz | 1477 Hz |
| * | 4'hA | 941 Hz | 1209 Hz |
| 0 | 4'h0 | 941 Hz | 1336 Hz |
| # | 4'hB | 941 Hz | 1477 Hz |

Inputs from `4'hC` through `4'hF` are invalid.

---

## 4. DTMF Frequency Groups

### Low-frequency group

| Frequency | Application |
|---:|---|
| 697 Hz | First low-group frequency |
| 770 Hz | Second low-group frequency |
| 852 Hz | Third low-group frequency |
| 941 Hz | Fourth low-group frequency |

### High-frequency group

| Frequency | Application |
|---:|---|
| 1209 Hz | First high-group frequency |
| 1336 Hz | Second high-group frequency |
| 1477 Hz | Third high-group frequency |

Each valid key selects one frequency from each group.

For example, pressing key **5** generates:

- Low frequency: 770 Hz
- High frequency: 1336 Hz

Both frequencies are generated simultaneously and combined into one digital audio signal.

---

## 5. System Architecture

The design is divided into seven functional modules.

```text
                  DTMF GENERATOR
                         |
                         |
                 +----------------+
                 | Key Decoder    |
                 +----------------+
                         |
                 Low/High Frequency
                    Increments
                         |
              +----------+----------+
              |                     |
              v                     v
       +--------------+      +--------------+
       | Low NCO      |      | High NCO     |
       | Phase Acc.   |      | Phase Acc.   |
       +--------------+      +--------------+
              |                     |
              v                     v
       +--------------+      +--------------+
       | Sine LUT     |      | Sine LUT     |
       +--------------+      +--------------+
              |                     |
              +----------+----------+
                         |
                         v
                 +---------------+
                 | Audio Mixer   |
                 +---------------+
                         |
                         v
                 +---------------+
                 | Audio Samples |
                 | 16-bit Output |
                 +---------------+
                         |
                         v
                 External DAC
                         |
                         v
                Reconstruction Filter
                         |
                         v
                EPABX Audio Interface
```

### Module descriptions

#### 5.1 dtmf_key_decoder

Converts the selected telephone key into two NCO phase increments.

It determines the low- and high-frequency components.

#### 5.2 dtmf_sample_generator

Generates the sample enable signal at the configured sample rate.

Default sample rate: 32 kHz.

#### 5.3 dtmf_phase_accumulator

Implements the Numerically Controlled Oscillator.

Two independent instances are used:

- Low-frequency NCO.
- High-frequency NCO.

Each NCO accumulates its phase increment to generate the required frequency.

#### 5.4 dtmf_sine_lut

Generates digital sine-wave values using a quarter-wave lookup table.

The design uses a 64-entry quarter-wave table and quadrant mirroring to represent a 256-point sine cycle.

#### 5.5 dtmf_audio_mixer

Combines the low- and high-frequency sine-wave samples.

The resulting output represents the selected DTMF tone.

#### 5.6 dtmf_tone_controller

Controls:

- Tone generation duration.
- Inter-digit silence duration.
- Busy indication.
- Completion indication.

#### 5.7 dtmf_generator_epabx

The top-level module connects all functional modules and provides the external interface.

---

## 6. Important Design Parameters

The top module uses configurable parameters.

| Parameter | Default Value | Description |
|---|---:|---|
| CLK_HZ | 100000000 | FPGA clock frequency |
| SAMPLE_HZ | 32000 | Audio sample frequency |
| TONE_MS | 100 | Tone duration in milliseconds |
| GAP_MS | 50 | Silence duration in milliseconds |

### Sample calculations

For a sample rate of 32 kHz:

\[
T_s=\frac{1}{32000}=31.25\ \mu s
\]

For a 100 ms tone:

\[
N_{tone}=\frac{32000 \times 100}{1000}
\]

\[
N_{tone}=3200
\]

For a 50 ms silence:

\[
N_{gap}=\frac{32000 \times 50}{1000}
\]

\[
N_{gap}=1600
\]

Therefore, each complete digit-generation cycle contains:

\[
N_{total}=3200+1600=4800
\]

sample periods.

---

## 7. Numerically Controlled Oscillator (NCO)

The NCO generates the required frequencies using a 32-bit phase accumulator.

The phase accumulator equation is:

\[
Phase_{next}=Phase_{current}+Increment
\]

The output frequency is:

\[
f_{out}=\frac{Increment \times f_s}{2^{32}}
\]

Where:

- \(f_{out}\) = generated frequency.
- \(Increment\) = phase increment.
- \(f_s\) = sample frequency.
- \(2^{32}\) = accumulator modulus.

The phase increment is calculated using:

\[
Increment=\frac{f_{out}\times 2^{32}}{f_s}
\]

The design uses separate phase accumulators for both DTMF frequencies.

This allows both sine waves to be generated simultaneously.

---

## 8. Frequency Increment Values

The following values are used at a 32 kHz sample rate.

| Frequency | Phase Increment |
|---:|---:|
| 697 Hz | 93549756 |
| 770 Hz | 103347651 |
| 852 Hz | 114353504 |
| 941 Hz | 126298882 |
| 1209 Hz | 162269233 |
| 1336 Hz | 179314885 |
| 1477 Hz | 198239584 |

These constants are used by the key decoder.

If the sample rate changes, the increment constants must also be recalculated.

---

## 9. Top-Level Module Interface

Module name:

`dtmf_generator_epabx`

### Inputs

| Signal | Width | Description |
|---|---:|---|
| clk | 1 bit | FPGA clock |
| reset | 1 bit | Synchronous active-high reset |
| digit_valid | 1 bit | One-clock digit request |
| digit | 4 bits | Telephone key code |

### Outputs

| Signal | Width | Description |
|---|---:|---|
| audio_out | 16 bits | Signed digital audio sample |
| sample_valid | 1 bit | Indicates a new audio sample |
| busy | 1 bit | Generator is processing a digit |
| done | 1 bit | Digit-generation cycle completed |

### Input encoding

| Input | Telephone key |
|---|---|
| 4'h0 | 0 |
| 4'h1 | 1 |
| 4'h2 | 2 |
| 4'h3 | 3 |
| 4'h4 | 4 |
| 4'h5 | 5 |
| 4'h6 | 6 |
| 4'h7 | 7 |
| 4'h8 | 8 |
| 4'h9 | 9 |
| 4'hA | * |
| 4'hB | # |

The `digit_valid` signal should be a one-clock pulse synchronized to the FPGA clock.

A new digit request is accepted only when the generator is idle and the key is valid.

---

## 10. Project Directory Structure

Recommended project organization:

```text
DTMF_Generator_EPABX/
|
+-- RTL/
|   |
|   +-- dtmf_generator_epabx.v
|
+-- SIM/
|   |
|   +-- tb_dtmf_generator_epabx.v
|
+-- CONSTRAINTS/
|   |
|   +-- arty_a7_dtmf.xdc
|
+-- README.md
|
+-- LICENSE.txt
```

The RTL file contains the seven modular Verilog modules.

The testbench verifies the design through simulation.

The XDC file provides the FPGA clock constraint and placeholders for hardware-specific external connections.

---

## 11. Vivado 2025.2.1 Project Setup

### Step 1: Create a new project

Open Xilinx Vivado 2025.2.1.

Select:

**Create Project → Next**

Enter the project name:

`DTMF_Generator_EPABX`

Select RTL Project and proceed.

### Step 2: Select the FPGA

Choose the following FPGA:

- Family: Artix-7
- Device: XC7A100T
- Package: CSG324
- Speed grade: -1

Target board:

Digilent Arty A7-100T.

### Step 3: Add RTL source

Add:

`RTL/dtmf_generator_epabx.v`

### Step 4: Add constraints

Add:

`CONSTRAINTS/arty_a7_dtmf.xdc`

Review all physical pin assignments before implementation.

### Step 5: Add simulation source

Add:

`SIM/tb_dtmf_generator_epabx.v`

Select:

`tb_dtmf_generator_epabx`

as the simulation top module.

### Step 6: Run simulation

Select:

**Run Simulation → Run Behavioral Simulation**

Inspect the simulation waveform and testbench console.

---

## 12. Testbench Verification

The self-checking testbench verifies all 12 telephone keys.

### Test groups

| Test Group | Verification |
|---|---|
| 1 | Frequency decoder |
| 2 | Key 1 tone generation |
| 3 | Key 2 tone generation |
| 4 | Key 3 tone generation |
| 5 | Key 4 tone generation |
| 6 | Key 5 tone generation |
| 7 | Key 6 tone generation |
| 8 | Key 7 tone generation |
| 9 | Key 8 tone generation |
| 10 | Key 9 tone generation |
| 11 | * tone generation |
| 12 | 0 tone generation |
| 13 | # tone generation |

The testbench checks:

- Correct frequency increment selection.
- Total sample count.
- Tone and silence sample counts.
- Non-zero audio output activity.
- Busy and done signal behavior.

The testbench uses a reduced simulation clock of 320 kHz to make simulation faster. The sample rate remains 32 kHz.

The simulation clock parameters must match the parameters supplied to the DUT.

**Note:** Passing this testbench does not establish spectral purity, frequency tolerance, output level, distortion or telephone-interface compliance. Those require additional measurements and hardware testing.

---

## 13. FPGA Clock Constraints

The Arty A7-100T provides a 100 MHz onboard clock.

The XDC file includes:

```tcl
set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports clk]

create_clock -add -name sys_clk_pin -period 10.000 \
    -waveform {0 5} [get_ports clk]
```

The clock period is:

\[
T=\frac{1}{100MHz}=10ns
\]

The external DAC pin assignments are not included because they depend on the selected DAC or audio codec.

Do not use placeholder pin assignments during FPGA implementation.

---

## 14. Hardware Integration with EPABX

The intended hardware signal path is:

```text
       Artix-7 FPGA
             |
             | 16-bit digital samples
             |
             v
        External DAC
             |
             v
     Reconstruction Filter
             |
             v
      Audio Level Control
             |
             v
   Protected Interface Circuit
             |
             v
            EPABX
```

### Required external hardware

1. Digital-to-Analog Converter (DAC) or audio codec.
2. Reconstruction low-pass filter.
3. Appropriate audio-level control.
4. Required buffering and impedance matching.
5. Protected interface circuitry compatible with the EPABX.

### Important electrical warning

Do not connect FPGA GPIO pins directly to a telephone line.

The FPGA output is a digital representation of an audio signal. It is not designed to drive telephone-line voltages, currents or impedances.

Before connecting the generator to an EPABX, verify the original UM95089 circuit and the electrical requirements of the existing DTMF input path.

---

## 15. UM95089 Replacement Considerations

This project is intended to replace the DTMF generation function of the UM95089.

However, a successful replacement requires more than matching the DTMF frequencies.

The following characteristics must be checked against the original circuit:

- Input key encoding.
- Key request and acknowledgement timing.
- Tone duration.
- Inter-digit pause.
- Output signal amplitude.
- Low-to-high group level relationship.
- Frequency accuracy.
- Harmonic distortion.
- Output impedance.
- Interface coupling and protection.
- Reset and power-up behavior.

The FPGA design currently uses a digital audio output interface. It is not a direct pin-for-pin replacement for the UM95089.

The original UM95089 datasheet and circuit schematic are required to finalize the replacement interface.

---

## 16. Standards and Signal Quality

ITU-T Recommendation Q.23 is a relevant reference for DTMF push-button telephone signaling.

For practical deployment, evaluate:

- Frequency accuracy and tolerance.
- Signal level and twist.
- Tone duration and interruption.
- Harmonic and non-harmonic distortion.
- Noise and unwanted spectral components.
- Receiver detection reliability.

The current design uses a 32 kHz sample rate and a 256-point equivalent sine lookup arrangement.

A more detailed implementation may use a larger lookup table, higher-resolution DAC, improved filtering and calibrated output levels.

The final acceptance limits should be selected from the applicable standard and the requirements of the target EPABX.

---

## 17. Possible Future Improvements

The project can be extended with:

1. 256-point or 1024-point full sine lookup table.
2. Higher-resolution audio output.
3. SPI or I2S DAC interface.
4. Configurable tone and silence timing.
5. Keypad matrix scanning.
6. UART-based digit input.
7. EPABX controller interface.
8. Programmable output amplitude.
9. Frequency measurement testbench.
10. FFT-based spectral verification.
11. Automatic gain control.
12. Hardware loopback testing.

---

## 18. Troubleshooting

### Problem: Vivado cannot find the top module

Check that all seven modules are present in the RTL source file.

Check the module name:

`dtmf_generator_epabx`

### Problem: Simulation elaboration fails

Check:

- All module names.
- Module port connections.
- Parameter names.
- Verilog syntax.
- Testbench simulation top.

### Problem: No audio output

Check:

- `digit_valid` pulse.
- Valid digit encoding.
- `busy` and `done` signals.
- `sample_valid` activity.
- NCO frequency increments.
- LUT connections.
- Mixer output.
- DAC clock and interface.

### Problem: FPGA implementation reports NSTD-1 or UCIO-1

Assign valid physical pins and I/O standards to every external FPGA port.

Do not leave placeholder pin assignments in the active XDC file.

### Problem: Incorrect generated frequencies

Check that:

- The sample rate matches the NCO increment calculation.
- The correct phase increment is selected.
- The FPGA clock constraint is correct.
- The sample enable divider is configured correctly.

---

## 19. Important Limitations

This project is an FPGA-based DTMF digital signal generator prototype.

The following items are not established by the RTL and basic simulation alone:

- Compatibility with the original UM95089 pin interface.
- Analog output amplitude.
- Telephone-line electrical compatibility.
- Frequency and spectral compliance.
- EPABX receiver detection performance.
- Electrical isolation and safety.

These must be verified using the actual EPABX circuit, DAC hardware and appropriate measurement equipment.

---

## 20. Conclusion

This project demonstrates how a dedicated DTMF generation IC function can be implemented using modular Verilog HDL and an Artix-7 FPGA.

It uses:

- Frequency decoding.
- Numerically Controlled Oscillators.
- Phase accumulators.
- Sine lookup tables.
- Digital audio mixing.
- Tone-duration control.
- Self-checking simulation.

The modular structure makes the design suitable for learning, testing and further development toward an EPABX-integrated DTMF generator.

**Developer:** Ghulam Yaseen Nangraj  
**Platform:** Xilinx Vivado 2025.2.1  
**Target:** Digilent Arty A7-100T  
**Language:** Verilog-2005

---
