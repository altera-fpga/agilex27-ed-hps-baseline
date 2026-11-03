#!/bin/bash
# =============================================================================
# Agilex 27 HPS Roll-Your-Own Linux Example Script
# =============================================================================
#
# PURPOSE:
# This script builds an SD card boot image for Altera Agilex 27 HPS systems.
# The SD card image produced from this script will demonstrate the HPS first boot flow
# and no configuration of FPGA core fabric will take place in U-Boot or Linux.
#
# USAGE:
#   ./ryo_linux_sd.sh
#
# OUTPUT:
#   sdcard.img - Ready to write to SD card
#
# REQUIREMENTS:
# - Linux host system (Ubuntu 22.04+ recommended)
# - Internet connection for downloading sources
# - ~20GB free disk space
# - mtools (mformat, mcopy) for SD image creation
#
# =============================================================================

set -e  # Exit on any error

# Prioritize system binaries over ARC shell packages (needed for Ubuntu container
# where system git/curl are built against OpenSSL 3.x)
export PATH="/usr/bin:/usr/sbin:$PATH"

# =============================================================================
# CONFIGURATION
# =============================================================================

echo "======================================================================"
echo "   Agilex 27 HPS SD Card Boot Flow Builder"
echo "======================================================================"

# Build configuration
OUTPUT_DIR="./build_output"
JOBS=$(nproc)

# Component URLs and settings
# Using the musl compiler to make a tight, statically linked Linux environment
TOOLCHAIN_URL="https://github.com/cross-tools/musl-cross/releases/download/20250929/aarch64-unknown-linux-musl.tar.xz"
TOOLCHAIN_DIR="aarch64-unknown-linux-musl"

ATF_REPO="https://github.com/altera-fpga/arm-trusted-firmware"
ATF_BRANCH="QPDS26.3_REL_BASELINE_PR"
ATF_DIR="arm-trusted-firmware"
ATF_PLAT="agilex27"

UBOOT_REPO="https://github.com/altera-fpga/u-boot-socfpga"
UBOOT_BRANCH="QPDS26.3_REL_BASELINE_PR"
UBOOT_DIR="u-boot-socfpga"

LINUX_REPO="https://github.com/altera-fpga/linux-socfpga"
LINUX_BRANCH="QPDS26.3_REL_BASELINE_PR"
LINUX_DIR="linux-socfpga"

TOYBOX_REPO="https://github.com/landley/toybox.git"
TOYBOX_DIR="toybox"

# =============================================================================
# BUILD PROCESS
# =============================================================================

echo "[STEP] Setting up build environment..."

# Create and enter build directory
mkdir -p "${OUTPUT_DIR}"
cd "${OUTPUT_DIR}"

# Set environment variables
export ARCH=arm64
export CROSS_COMPILE="${PWD}/${TOOLCHAIN_DIR}/bin/aarch64-unknown-linux-musl-"

echo "Build directory: ${PWD}"
echo "Architecture: ${ARCH}"
echo "Cross compiler: ${CROSS_COMPILE}"

# =============================================================================
# DOWNLOAD AND SETUP TOOLCHAIN
# =============================================================================

echo "[STEP] Setting up ARM GNU toolchain..."

TOOLCHAIN_ARCHIVE="${TOOLCHAIN_DIR}.tar.xz"

if [[ ! -d "${TOOLCHAIN_DIR}" ]]; then
    if [[ ! -f "${TOOLCHAIN_ARCHIVE}" ]]; then
        echo "Downloading ARM GNU toolchain..."
        if command -v wget >/dev/null 2>&1; then
            wget --no-check-certificate --progress=bar:force:noscroll -O "${TOOLCHAIN_ARCHIVE}" "${TOOLCHAIN_URL}"
        elif command -v curl >/dev/null 2>&1; then
            curl -L --progress-bar -o "${TOOLCHAIN_ARCHIVE}" "${TOOLCHAIN_URL}"
        else
            echo "ERROR: Neither wget nor curl found. Please install one of them."
            exit 1
        fi
    fi

    echo "Extracting ARM GNU toolchain..."
    tar -xf "${TOOLCHAIN_ARCHIVE}"

    # Verify toolchain
    if [[ ! -x "${TOOLCHAIN_DIR}/bin/aarch64-unknown-linux-musl-gcc" ]]; then
        echo "ERROR: ARM toolchain verification failed"
        exit 1
    fi

    echo "ARM toolchain setup complete"
    chmod -R 755 . # Ensure extracted toolchain files are able to clean up.
else
    echo "ARM toolchain already exists, skipping download"
fi

# Add toolchain to the path
export PATH=${PWD}/${TOOLCHAIN_DIR}/bin:$PATH

# =============================================================================
# BUILD TOYBOX ROOTFS
# =============================================================================

echo "[STEP] Building toybox root filesystem..."

if [[ ! -d "${TOYBOX_DIR}" ]]; then
    git clone "${TOYBOX_REPO}" "${TOYBOX_DIR}"
fi

cd "${TOYBOX_DIR}"

# Clean any previous builds first
make clean 2>/dev/null || true

# Use defconfig and build with cross-compilation.
# CC=gcc is for host helpers only; unset after so ATF/U-Boot/Linux keep using CROSS_COMPILE.
export CC=gcc

# Use standard defconfig - musl toolchain should handle this cleanly
make defconfig

# Adapt mkroot's QEMU-oriented init for the SD/Simics boot flow:
# - present the login prompt instead of a direct shell
# - allow passwordless root login because regtest sends only the username
# - do not attempt network time synchronization against QEMU/Internet hosts
# - re-run login instead of rebooting when a session ends, so the prompt stays
# Restore upstream first so the patch applies the same way on every rebuild.
git checkout -- mkroot/mkroot.sh
sed -i \
    -e '/sntp -sq/d' \
    -e '/HANDOFF=\/bin\/sh/c\  [ -z "$HANDOFF" ] \&\& HANDOFF=/bin/login' \
    -e 's|^root:x:0:0:root:|root::0:0:root:|' \
    -e 's|^  reboot -f &$|  exec "$0"|' \
    mkroot/mkroot.sh
if grep -q 'sntp -sq' mkroot/mkroot.sh ||
    ! grep -q 'HANDOFF=/bin/login' mkroot/mkroot.sh ||
    ! grep -Fq 'root::0:0:root:' mkroot/mkroot.sh ||
    ! grep -Fq 'exec "$0"' mkroot/mkroot.sh; then
    echo "ERROR: Failed to customize toybox mkroot login/network setup"
    exit 1
fi

# Disable Toybox login idle timeout (default 60s) so the session is not aborted.
git checkout -- toys/other/login.c
sed -i 's|alarm(TT.login_timeout = 60);|alarm(TT.login_timeout = 0);|' \
    toys/other/login.c
if ! grep -Fq 'alarm(TT.login_timeout = 0);' toys/other/login.c; then
    echo "ERROR: Failed to disable toybox login timeout"
    exit 1
fi

mkroot/mkroot.sh || { echo "ERROR: make root failed"; exit 1; }

# Extract the initramfs.cpio from toybox's output (same as Makefile approach)
if [[ -f "root/aarch64/initramfs.cpio.gz" ]]; then
    echo "Creating initramfs.cpio from toybox output..."
    gzip -dc root/aarch64/initramfs.cpio.gz > ../initramfs.cpio
    echo "Toybox initramfs.cpio created successfully"
else
    echo "ERROR: Failed to find toybox initramfs.cpio.gz output"
    exit 1
fi

unset CC
cd ..
echo "Toybox rootfs build complete"

# =============================================================================
# BUILD ARM TRUSTED FIRMWARE
# =============================================================================

echo "[STEP] Building ARM Trusted Firmware (ATF)..."

if [[ ! -d "${ATF_DIR}" ]]; then
    git clone -b "${ATF_BRANCH}" "${ATF_REPO}" "${ATF_DIR}"
fi

cd "${ATF_DIR}"

git checkout "${ATF_BRANCH}"

# Clean and build ATF
make realclean
make -j "${JOBS}" PLAT="${ATF_PLAT}" bl31 ENABLE_LTO=0

cd ..

echo "ATF build complete"

echo "ATF build complete" >> ATF_BUILD_SUCCESS.txt

# =============================================================================
# BUILD U-BOOT
# =============================================================================

echo "[STEP] Building U-Boot bootloader..."

if [[ ! -d "${UBOOT_DIR}" ]]; then
    git clone -b "${UBOOT_BRANCH}" "${UBOOT_REPO}" "${UBOOT_DIR}"
fi

cd "${UBOOT_DIR}"

git checkout "${UBOOT_BRANCH}"

# Build U-Boot
make clean && git clean -df

# Link after git clean so the untracked links cannot be removed.
# bl31.elf is not used by the FIT, but Simics/debuggers load it for symbols.
ln -sf "../${ATF_DIR}/build/${ATF_PLAT}/release/bl31.bin" .
ln -sf "../${ATF_DIR}/build/${ATF_PLAT}/release/bl31/bl31.elf" .

# Use a compiled-in boot command instead of distro boot.
# Load Image, DTB, and toybox initramfs from a single FAT volume, then booti into RAM.
cat > config-fragment << 'EOF'
CONFIG_BOOTFILE="Image"
CONFIG_DISTRO_DEFAULTS=n
CONFIG_HUSH_PARSER=y
CONFIG_SYS_PROMPT_HUSH_PS2="> "
CONFIG_USE_BOOTCOMMAND=y
CONFIG_BOOTCOMMAND="printenv bootcmd; fatls mmc 0:1; setenv bootargs earlycon panic=-1 root=/dev/ram0 rw init=init ramdisk_size=10000000; mmc info; fatload mmc 0:1 0x86000000 Image; fatload mmc 0:1 0x8c000000 socfpga_agilex27_socdk.dtb; fatload mmc 0:1 0x90000000 initramfs.cpio; booti 0x86000000 0x90000000:\${filesize} 0x8c000000"
CONFIG_CMD_BOOTI=y
CONFIG_CMD_FAT=y
CONFIG_CMD_FS_GENERIC=y
CONFIG_DOS_PARTITION=y
CONFIG_SPL_DOS_PARTITION=y
CONFIG_CMD_PART=y
EOF

make socfpga_agilex27_defconfig
./scripts/kconfig/merge_config.sh -O . -m .config config-fragment
make -j "${JOBS}"

# Copy SPL files only if build was successful
if [[ -f "spl/u-boot-spl" && -f "spl/u-boot-spl.bin" ]]; then
    cp -f spl/u-boot* ./
    echo "✓ SPL files copied successfully"
else
    echo "ERROR: U-Boot SPL build failed - required files not found"
    exit 1
fi

if [[ ! -f u-boot.itb ]]; then
    echo "ERROR: u-boot.itb not found after U-Boot build"
    exit 1
fi

# Publish into build_output immediately so a later pack step cannot pick up a
# stale copy from a previous full build (cp -f always overwrites).
cp -f u-boot.itb ..
echo "✓ Overwrote ../u-boot.itb from ${UBOOT_DIR}/u-boot.itb"

cd ..

echo "U-Boot build complete"

echo "U-Boot build complete" >> UBOOT_BUILD_SUCCESS.txt

# =============================================================================
# BUILD LINUX KERNEL
# =============================================================================

echo "[STEP] Building Linux kernel..."

if [[ ! -d "${LINUX_DIR}" ]]; then
    git clone -b "${LINUX_BRANCH}" "${LINUX_REPO}" "${LINUX_DIR}"
fi

cd "${LINUX_DIR}"

git checkout "${LINUX_BRANCH}"

# Configure and build kernel
make clean && git clean -df && make mrproper
./scripts/config --file arch/arm64/configs/defconfig --enable CONFIG_MTD_UBI --enable CONFIG_UBIFS_FS --disable CONFIG_MTD_SPI_NOR_USE_4K_SECTORS
make defconfig
# enable below make option to just build Image and socfpga_agilex27_socdk.dtb
#make -j "${JOBS}" Image && make altera/socfpga_agilex27_socdk.dtb
make -j "${JOBS}" all

cd ..

echo "Linux kernel build complete"

echo "Linux kernel build complete" >> LINUX_BUILD_SUCCESS.txt

echo "[STEP] Copying build artifacts..."

if [[ -f "${UBOOT_DIR}/u-boot.itb" ]]; then
    cp -f "${UBOOT_DIR}/u-boot.itb" .
    echo "✓ Overwrote u-boot.itb from ${UBOOT_DIR}/u-boot.itb"
else
    echo "ERROR: ${UBOOT_DIR}/u-boot.itb not found"
    exit 1
fi

if [[ -f "${LINUX_DIR}/arch/arm64/boot/Image" ]]; then
    cp -f "${LINUX_DIR}/arch/arm64/boot/Image" .
    echo "✓ Overwrote Image"
else
    echo "ERROR: ${LINUX_DIR}/arch/arm64/boot/Image not found"
    exit 1
fi

if [[ -f "${LINUX_DIR}/arch/arm64/boot/dts/altera/socfpga_agilex27_socdk.dtb" ]]; then
    cp -f "${LINUX_DIR}/arch/arm64/boot/dts/altera/socfpga_agilex27_socdk.dtb" .
    echo "✓ Overwrote socfpga_agilex27_socdk.dtb"
else
    echo "ERROR: ${LINUX_DIR}/arch/arm64/boot/dts/altera/socfpga_agilex27_socdk.dtb not found"
    exit 1
fi

# =============================================================================
# CREATE SD CARD IMAGE
# =============================================================================
echo "[STEP] Creating SD card image..."

# Image (~40 MiB) + u-boot.itb + DTB + initramfs 
SD_IMAGE_SIZE_MB=128

if [[ -f sdcard.img ]]; then
    rm -f sdcard.img
    echo "Removed existing SD image"
fi

for cmd in mformat mcopy; do
    if ! command -v "${cmd}" >/dev/null 2>&1; then
        echo "ERROR: ${cmd} not found. Install mtools (e.g. apt install mtools)."
        exit 1
    fi
done

# Final safeguard: always re-publish the just-built FIT before packing so a
# partial rebuild / leftover build_output/u-boot.itb cannot sneak into sdcard.img.
if [[ ! -f "${UBOOT_DIR}/u-boot.itb" ]]; then
    echo "ERROR: ${UBOOT_DIR}/u-boot.itb missing before SD pack"
    exit 1
fi
cp -f "${UBOOT_DIR}/u-boot.itb" ./u-boot.itb
if ! cmp -s "${UBOOT_DIR}/u-boot.itb" ./u-boot.itb; then
    echo "ERROR: build_output/u-boot.itb does not match ${UBOOT_DIR}/u-boot.itb"
    exit 1
fi
echo "✓ Verified u-boot.itb matches ${UBOOT_DIR}/u-boot.itb (will pack this copy)"

if [[ ! -f Image ]]; then
    echo "ERROR: Image not found before SD pack"
    exit 1
fi
if [[ ! -f socfpga_agilex27_socdk.dtb ]]; then
    echo "ERROR: socfpga_agilex27_socdk.dtb not found before SD pack"
    exit 1
fi
if [[ ! -f initramfs.cpio ]]; then
    echo "ERROR: initramfs.cpio not found (expected from toybox build)"
    exit 1
fi

echo "Creating ${SD_IMAGE_SIZE_MB} MiB FAT32 SD image with: u-boot.itb, Image, socfpga_agilex27_socdk.dtb, initramfs.cpio"
dd if=/dev/zero of=sdcard.img bs=1M count="${SD_IMAGE_SIZE_MB}" status=none
mformat -i sdcard.img :: -F
mcopy -i sdcard.img u-boot.itb ::
mcopy -i sdcard.img Image ::
mcopy -i sdcard.img socfpga_agilex27_socdk.dtb ::
mcopy -i sdcard.img initramfs.cpio ::

# compress image into tar.gz for distribution
tar -czvf sdimage.tar.gz sdcard.img

echo "SUCCESS: SD card image created: sdcard.img"
echo ""
echo "======================================================================"
echo "                           BUILD COMPLETE"
echo "======================================================================"
echo ""
echo "Output files created in: ${PWD}"
echo ""
echo "Key files:"
echo "  sdcard.img                   - SD card image (FAT32; write to SD card)"
echo "  u-boot.itb                   - U-Boot bootloader"
echo "  Image                        - Linux kernel"
echo "  socfpga_agilex27_socdk.dtb    - Device tree"
echo "  initramfs.cpio               - Toybox root filesystem (initramfs)"
echo ""
echo "Boot flow:"
echo "  U-Boot fatloads Image + DTB + initramfs.cpio from FAT, then booti into RAM"
echo "  (root=/dev/ram0; no ext root partition)"
echo ""