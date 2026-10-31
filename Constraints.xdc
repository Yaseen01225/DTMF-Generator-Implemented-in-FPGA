
###############################################################################
# Project   : FPGA DTMF Generator for EPABX
# Board     : Digilent Arty A7-100T
# FPGA      : XC7A100TCSG324-1
# Developer : Ghulam Yaseen Nangraj
# Date      : 31 October 2026
# Tool      : Xilinx Vivado 2025.2.1
###############################################################################

###############################################################################
# 100 MHz onboard clock
# Arty A7 clock pin: E3
###############################################################################

set_property -dict { PACKAGE_PIN E3 IOSTANDARD LVCMOS33 } [get_ports clk]

create_clock -add -name sys_clk_pin -period 10.000 \
    -waveform {0 5} [get_ports clk]

###############################################################################
# Reset input
#
# Uncomment and assign the correct physical pin if using a reset button.
###############################################################################

# set_property -dict { PACKAGE_PIN <RESET_PIN> IOSTANDARD LVCMOS33 } [get_ports reset]

###############################################################################
# DTMF digit input
#
# digit[3:0] encoding:
# 0-9 = numeric keys
# A   = *
# B   = #
#
# Assign actual switch or controller interface pins.
###############################################################################

# set_property -dict { PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33 } [get_ports {digit[0]}]
# set_property -dict { PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33 } [get_ports {digit[1]}]
# set_property -dict { PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33 } [get_ports {digit[2]}]
# set_property -dict { PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33 } [get_ports {digit[3]}]

###############################################################################
# Digit request input
###############################################################################

# set_property -dict { PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33 } [get_ports digit_valid]

###############################################################################
# Audio output interface
#
# audio_out is a signed 16-bit digital sample bus.
# Connect it to an external DAC/audio codec.
# Do not connect this bus directly to a telephone line.
###############################################################################

# set_property -dict { PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33 } [get_ports {audio_out[0]}]
# set_property -dict { PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33 } [get_ports {audio_out[1]}]
# Continue for audio_out[15] if using a parallel DAC.

###############################################################################
# Status outputs (optional)
###############################################################################

# set_property -dict { PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33 } [get_ports busy]
# set_property -dict { PACKAGE_PIN <PIN> IOSTANDARD LVCMOS33 } [get_ports done]

###############################################################################
# End of constraints
###############################################################################
