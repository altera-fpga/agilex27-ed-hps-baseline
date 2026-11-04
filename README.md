# Agilex 27 Baseline Hardware Reference Designs

This repository contains Baseline Hardware Reference Designs for Agilex 27 System On Chip (SoC) FPGA.
This repository is part of the Baseline System Example Design, which provides a complete solution, including exercising soft IP in the fabric, booting to U-Boot, then Linux, and running sample Linux applications.

The [designs](#designs) are stored in individual folders. Each design can be opened, modified and compiled by using Quartus Prime software.
Repository releases are tagged for each version of Quartus Prime Software. It is recommended to use the release for your version of Quartus Prime.
These designs demonstrate the system integration between Hard Processor System (HPS) and FPGA IPs.

## Baseline feature

This is applicable to all designs.

- Hard Processor System (HPS) enablement and configuration
  - Enable dual core Arm Cortex-A520 processor
  - Enable dual core Arm Cortex-A720 processor
  - HPS Peripheral and I/O (for example SD/MMC, EMAC, USB, UART, I3C, and GPIO; depends on daughter card)
  - HPS Clock and Reset
  - HPS FPGA Bridge and Interrupt
    - Note: The System MMU port in F2H and F2SDRAM bridges are disabled by default in baseline design, unless otherwise specified.
- HPS EMIF configuration
- System integration with FPGA IPs
  - Peripheral subsystem that consists of System ID, Programmable I/O (PIO) IP for controlling DIPSW, PushButton, and LEDs
  - Debug subsystem that consists of JTAG-to-Avalon Master IP to allow System-Console debug activity and FPGA content access through JTAG
  - 256KB of FPGA On-Chip Memory
  - NiosV subsystem with Address Span Extender IP for F2SDRAM / F2H / LWF2H access

## Dependency

* Altera Quartus Prime 26.3

## Tested Platform for the hardware Build Flow

* SUSE Linux Enterprise Server 15 SP4

## Setup

Several tools are required to be in the path.

* Altera Quartus Prime 26.3
* Python 3.11.5 (only required when using command line to build)

### Example Setup for Altera Quartus Prime tools

This is recommended, when using command line to build.

```bash
export QUARTUS_ROOTDIR=~/alteraFPGA_pro/26.3/quartus
```

Note: Adapt the path above to where Quartus Prime is installed.

```bash
export PATH="$QUARTUS_ROOTDIR/bin:$QUARTUS_ROOTDIR/../qsys/bin:$QUARTUS_ROOTDIR/../niosv/bin:$QUARTUS_ROOTDIR/sopc_builder/bin:$QUARTUS_ROOTDIR/../questa_fe/bin:$QUARTUS_ROOTDIR/../syscon/bin:$QUARTUS_ROOTDIR/../riscfree/RiscFree:$PATH"
```

## Quick start

### Using command line

1. Choose a design under [designs](#designs) for your development kit.
2. Change to that design directory. Example:

```bash
cd dk-dev-agilex27-enablement/baseline-a520
```

3. Follow the README in that directory for command-line build, simulation, and software steps.

### Using Quartus GUI

- Launch Quartus.
- Open the project. Example: `dk-dev-agilex27-enablement/baseline-a520/top.qpf`
- Click the play button to compile the design.
- The compiled sof can be found in the `output_files` folder of the project path.

### Notes

- Command line and Quartus GUI should not be used intertwined.
- Mixing both design build flows might not generate some fileset correctly and fail the build.

## Designs

This section lists shipped designs in the repository, grouped by development kit.
Each bullet links to that design's README for build instructions and functional detail;
use the platform index link for devkit context.

### Agilex 27 Development Kit — HPS Enablement (OOBE)

Platform index: [dk-dev-agilex27-enablement](dk-dev-agilex27-enablement/README.md)

- [baseline-a520](dk-dev-agilex27-enablement/baseline-a520/README.md) — Baseline-A520; boots from Arm Cortex-A520 core 0
