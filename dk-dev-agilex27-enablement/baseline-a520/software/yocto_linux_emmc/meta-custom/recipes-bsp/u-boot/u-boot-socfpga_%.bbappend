SUMMARY = "U-boot"
DESCRIPTION = "This receipe enables u-boot customizations(device tree, configs and patches)"

# Prepare the path of the device tree file location
UBOOT_DEVICE_TREE_SRC_PATH := "${THISDIR}/files/dts"

# Set path for configs and source patches
FILESEXTRAPATHS:prepend := "${THISDIR}/files/configs:${THISDIR}/files/patches:"

# Conditionally disable FAT environment for QSPI-only boot
SRC_URI += "${@bb.utils.contains('SSBL_BOOT_SRC', 'qspi', 'file://disable-fat-env.cfg', '', d)}"

python () {
    import bb

    dtb = d.getVar("UBOOT_DEVICE_TREE")

    if not dtb:
        bb.fatal("UBOOT_DEVICE_TREE is not set. Please define it (e.g., socfpga_agilex5_socdk.dtb).")

    # Strip .dtb suffix if present
    base = dtb.replace(".dtb", "") if dtb.endswith(".dtb") else dtb

    dtsi_file = f"{d.getVar('S')}/arch/arm/dts/{base}-u-boot.dtsi"
    d.setVar("UBOOT_DTSI_FILE", dtsi_file)
}

# FSBL - based on boot source (SSBL_BOOT_SRC) configuration, update
# the u-boot,spl-boot-order property in device tree source file
do_configure:append() {
    # QSPI boot source SPL boot-order patching will be enabled in a future release.
}
