#!/bin/bash

set -eo pipefail

# ============================
# Usage check
# ============================
COMMAND="${1:-}"

if [[ -z "$COMMAND" ]]; then
    echo "Usage: $0 clean"
    echo "       $0 <sdmmc|backdoor> <binaries_path>"
    exit 1
fi

BINARIES_PATH="$2"

# ============================
# Validate path (for commands that need it)
# ============================
if [[ "$COMMAND" != "clean" ]]; then
    if [[ -z "$BINARIES_PATH" ]]; then
        echo "[ERROR] Binaries path is required for '$COMMAND' command"
        echo "Usage: $0 $COMMAND <binaries_path>"
        exit 1
    fi
    if [[ ! -d "$BINARIES_PATH" ]]; then
        echo "[ERROR] Binaries path '$BINARIES_PATH' does not exist or is not a directory"
        exit 1
    fi

    # Convert BINARIES_PATH to absolute path
    if [[ "$BINARIES_PATH" != /* ]]; then
        BINARIES_PATH="$(readlink -f "$BINARIES_PATH")"
    fi
    echo "[INFO] Binaries path: $BINARIES_PATH"
fi

# ============================
# Clean command
# ============================
if [[ "$COMMAND" == "clean" ]]; then
    echo "[INFO] Cleaning Simics project files..."

    # Remove project files
    (
        PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
        cd "$PROJECT_ROOT" || { echo "[ERROR] Cannot cd to project root: $PROJECT_ROOT"; exit 1; }
        rm -rf \
            .modcache \
            .project-properties \
            CMakeLists.txt \
            GNUmakefile \
            bin \
            cmake-wrapper.mk \
            compiler.mk \
            config.mk \
            documentation \
            gui-requirements.txt \
            linux64 \
            modules \
            requirements.txt \
            simics \
            simics-riscfree \
            targets
    )
    echo "[INFO] Cleanup complete."
    exit 0
fi

BOOTMODE="$COMMAND"
echo "[INFO] Boot mode: $BOOTMODE"

# ============================
# Set boot directory and scenario
# ============================
if [[ "$BOOTMODE" == "sdmmc" ]]; then
    BOOTDIR="sdmmc_boot"
    SIMICS_SCENARIO="$BOOTDIR/sdmmc_gsrd.simics"

    # Define image file paths
    UBOOT_FILE="$BINARIES_PATH/u-boot-spl-dtb.bin"
    SDMMC_IMAGE_FILE="$BINARIES_PATH/gsrd-console-image-agilex27.rootfs.wic"
    if [[ ! -f "$SDMMC_IMAGE_FILE" && -f "gsrd-console-image-agilex27.rootfs.wic" ]]; then
        SDMMC_IMAGE_FILE="gsrd-console-image-agilex27.rootfs.wic"
    fi

    # Log setup
    echo "[INFO] Simics scenario: $SIMICS_SCENARIO"
    echo "[INFO] U-Boot file: $UBOOT_FILE"
    echo "[INFO] SD image file: $SDMMC_IMAGE_FILE"

    # Verify files and update Simics scenario
    if [[ -f "$UBOOT_FILE" && -f "$SDMMC_IMAGE_FILE" && -f "$SIMICS_SCENARIO" ]]; then
        echo "[INFO] Updating Simics script: $SIMICS_SCENARIO"
        sed -i \
            -e "s|^\$hps_apu_fsbl_image_filename *= *\"[^\"]*\"|\$hps_apu_fsbl_image_filename = \"$UBOOT_FILE\"|" \
            -e "s|^\$sd_image_filename *= *\"[^\"]*\"|\$sd_image_filename = \"$SDMMC_IMAGE_FILE\"|" \
            "$SIMICS_SCENARIO"
        echo "[INFO] Simics script updated successfully."
    else
        echo "[WARN] Missing one or more required files:"
        [[ ! -f "$SIMICS_SCENARIO" ]] && echo "  - Simics scenario: $SIMICS_SCENARIO"
        [[ ! -f "$UBOOT_FILE" ]] && echo "  - U-Boot file: $UBOOT_FILE"
        [[ ! -f "$SDMMC_IMAGE_FILE" ]] && echo "  - SD image file: $SDMMC_IMAGE_FILE"
        exit 1
    fi
elif [[ "$BOOTMODE" == "backdoor" ]]; then
    BOOTDIR="backdoor_boot"
    SIMICS_SCENARIO="$BOOTDIR/backdoor_gsrd.simics"

    # Define image file paths
    UBOOT_FILE="$BINARIES_PATH/u-boot-spl-dtb.bin"
    UBOOT_ITB_FILE="$BINARIES_PATH/u-boot.itb"
    IMAGE_FILE="$BINARIES_PATH/Image"
    DTB_FILE="$BINARIES_PATH/socfpga_agilex27_socdk.dtb"
    BACKDOOR_IMAGE_FILE="$BINARIES_PATH/console-image-minimal-agilex27.rootfs.cpio.gz.u-boot"
    if [[ ! -f "$BACKDOOR_IMAGE_FILE" && -f "console-image-minimal-agilex27.rootfs.cpio.gz.u-boot" ]]; then
        BACKDOOR_IMAGE_FILE="console-image-minimal-agilex27.rootfs.cpio.gz.u-boot"
    fi

    # Log setup
    echo "[INFO] Simics scenario: $SIMICS_SCENARIO"
    echo "[INFO] U-Boot file: $UBOOT_FILE"
    echo "[INFO] U-Boot ITB file: $UBOOT_ITB_FILE"
    echo "[INFO] IMAGE file: $IMAGE_FILE"
    echo "[INFO] DTB file: $DTB_FILE"
    echo "[INFO] Backdoor image file: $BACKDOOR_IMAGE_FILE"

    # Verify files and update Simics scenario
    if [[ -f "$UBOOT_FILE" && -f "$UBOOT_ITB_FILE" && -f "$IMAGE_FILE" && -f "$DTB_FILE" && -f "$BACKDOOR_IMAGE_FILE" && -f "$SIMICS_SCENARIO" ]]; then
        echo "[INFO] Updating Simics script: $SIMICS_SCENARIO"
        sed -i \
            -e "s|^\$hps_apu_fsbl_image_filename *= *\"[^\"]*\"|\$hps_apu_fsbl_image_filename = \"$UBOOT_FILE\"|" \
            -e "s|^\$uboot_itb_image_filename *= *\"[^\"]*\"|\$uboot_itb_image_filename = \"$UBOOT_ITB_FILE\"|" \
            -e "s|^\$image_filename *= *\"[^\"]*\"|\$image_filename = \"$IMAGE_FILE\"|" \
            -e "s|^\$dtb_filename *= *\"[^\"]*\"|\$dtb_filename = \"$DTB_FILE\"|" \
            -e "s|^\$bd_image_filename *= *\"[^\"]*\"|\$bd_image_filename = \"$BACKDOOR_IMAGE_FILE\"|" \
            "$SIMICS_SCENARIO"
        echo "[INFO] Simics script updated successfully."
    else
        echo "[WARN] Missing one or more required files:"
        [[ ! -f "$SIMICS_SCENARIO" ]] && echo "  - Simics scenario: $SIMICS_SCENARIO"
        [[ ! -f "$UBOOT_FILE" ]] && echo "  - U-Boot file: $UBOOT_FILE"
        [[ ! -f "$UBOOT_ITB_FILE" ]] && echo "  - U-Boot ITB file: $UBOOT_ITB_FILE"
        [[ ! -f "$IMAGE_FILE" ]] && echo "  - Image file: $IMAGE_FILE"
        [[ ! -f "$DTB_FILE" ]] && echo "  - DTB file: $DTB_FILE"
        [[ ! -f "$BACKDOOR_IMAGE_FILE" ]] && echo "  - Backdoor image file: $BACKDOOR_IMAGE_FILE"
        exit 1
    fi
fi

# ============================
# Deploy & Build Simics project
# ============================
echo "[INFO] Checking for existing Simics project..."
SIMICS_TARGET="targets/agilex27-universal/agilex27-universal.simics"
SIMICS_BINARY="./simics"

if find modules -type f \( -name "Makefile" -o -name "*.py" \) | grep -q . && [[ -f "$SIMICS_TARGET" && -f "$SIMICS_BINARY" ]]; then
        echo "[INFO] Existing Simics project and binary detected. Skipping deploy and build."
else
    echo "[INFO] Simics project or binary missing. Deploying and building..."
    simics_intelfpga_cli --deploy agilex27-universal
    make
fi

# ============================
# Launch simulation
# ============================
echo "[INFO] Starting Simics simulation with scenario $SIMICS_SCENARIO ..."
./simics "$SIMICS_SCENARIO"