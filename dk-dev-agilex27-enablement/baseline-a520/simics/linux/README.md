# Simics HPS Linux Boot for Agilex72 Development Kit

## Description

The `runsimics.sh` script is used to set up and launch a Simics simulation of HPS Linux boot on the Agilex72 development kit. It takes a boot mode (`sdmmc` or `backdoor`) and a path to the Yocto-built binaries, updates the corresponding Simics scenario with those image paths, deploys the `agilex27-universal` Simics project if not already deployed, and starts the simulation. Use `./runsimics.sh clean` to remove generated Simics project files.

## Instructions
1. Build all Yocto-built binaries
   - SDMMC binaries include:
     - `gsrd-console-image-agilex27.rootfs.wic`
     - `u-boot-spl-dtb.bin`
   - Backdoor binaries include:
     - `u-boot-spl-dtb.bin`
     - `u-boot.itb`
     - `Image`
     - `socfpga_agilex27_socdk.dtb`
     - `console-image-minimal-agilex27.rootfs.cpio.gz.u-boot`
2. `cd` into the simics/linux directory
3. `./runsimics.sh sdmmc path/to/binaries` or `./runsimics.sh backdoor path/to/binaries`
4. `run` in simics cli
