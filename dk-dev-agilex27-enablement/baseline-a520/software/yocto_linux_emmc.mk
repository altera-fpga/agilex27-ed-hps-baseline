# Yocto Linux eMMC Build (KM software-only)
# Required inputs: REVISION, INSTALL_ROOT_BINARIES, INSTALL_ROOT_ARTIFACTS
# Optional inputs: RESTORE_INSTALL
# Entry targets: clean-sw, build-sw, install-sw

THIS_MK_ABSPATH := $(abspath $(lastword $(MAKEFILE_LIST)))
THIS_MK_DIR := $(dir $(THIS_MK_ABSPATH))

# Enable pipefail for all commands
SHELL := /bin/bash
.SHELLFLAGS := -o pipefail -c

# Enable second expansion
.SECONDEXPANSION:

# Clear all built in suffixes
.SUFFIXES:

ifeq ($(strip $(INSTALL_ROOT_BINARIES)),)
$(error ERROR: INSTALL_ROOT_BINARIES was not defined before yocto_linux_emmc.mk was parsed)
endif

ifeq ($(strip $(INSTALL_ROOT_ARTIFACTS)),)
$(error ERROR: INSTALL_ROOT_ARTIFACTS was not defined before yocto_linux_emmc.mk was parsed)
endif

ifeq ($(strip $(REVISION)),)
$(error ERROR: REVISION was not set. Pass REVISION=<revision> on the command line)
endif

MACHINE_YML_PATH := software/yocto_linux_emmc/kas/machine.yml
YOCTO_PROJECT_DIR := software/yocto_linux_emmc
include $(THIS_MK_DIR)/sw_build_common.mk

ifdef KAS_CUSTOM_LINUX_DTB
  YOCTO_EMMC_OPTIONAL_DTB := $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/$(KAS_CUSTOM_LINUX_DTB)
else
  YOCTO_EMMC_OPTIONAL_DTB :=
endif

###############################################################################
#                           SW Build Targets
###############################################################################

YOCTO_EMMC_IMAGE_DIR := $(KAS_YOCTO_IMAGE_DIR)
YOCTO_EMMC_WIC       := $(YOCTO_EMMC_IMAGE_DIR)/gsrd-console-image-$(KAS_MACHINE).rootfs.wic

# Copy required files to artifacts directory
YOCTO_EMMC_ARTIFACT_FILES := \
	u-boot-spl \
	u-boot-spl.dtb \
	u-boot-spl.map \
	u-boot \
	u-boot.dtb \
	$(KAS_LINUX_DTB) \
	console-image-minimal-$(KAS_MACHINE).rootfs.cpio.gz.u-boot \
	gsrd-console-image-$(KAS_MACHINE).rootfs.cpio.gz.u-boot

$(INSTALL_ROOT_ARTIFACTS)/software/yocto_linux_emmc/%: $(YOCTO_EMMC_IMAGE_DIR)/% | $(INSTALL_ROOT_ARTIFACTS)
	mkdir -p $(dir $@)
	cp -f $< $@

.PHONY: clean-sw
clean-sw:
	cd software/yocto_linux_emmc && ./clean_build.sh

.PHONY: build-sw
build-sw:
	cd software/yocto_linux_emmc && ./build.sh emmc

# Post-process: generate emmcimage.tar.gz, emmcimage.tar.gz.md5sum, copy uboot_bin.sh, and run uboot_bin.sh
.PHONY: postprocess-yocto-emmc
postprocess-yocto-emmc: $(YOCTO_EMMC_IMAGE_DIR)/emmcimage.tar.gz $(YOCTO_EMMC_IMAGE_DIR)/emmcimage.tar.gz.md5sum $(YOCTO_EMMC_IMAGE_DIR)/uboot_bin.sh
	cd $(YOCTO_EMMC_IMAGE_DIR) && ./uboot_bin.sh

$(YOCTO_EMMC_IMAGE_DIR)/emmcimage.tar.gz: $(YOCTO_EMMC_WIC)
	tar -chzf $@ -C $(dir $<) $(notdir $<)

$(YOCTO_EMMC_IMAGE_DIR)/emmcimage.tar.gz.md5sum: $(YOCTO_EMMC_IMAGE_DIR)/emmcimage.tar.gz
	cd $(dir $@) && md5sum $(notdir $(basename $@)) > $(notdir $@)

$(YOCTO_EMMC_IMAGE_DIR)/uboot_bin.sh: software/yocto_linux_emmc/scripts/uboot_bin.sh
	cp -f $< $@

.PHONY: install-sw
install-sw: postprocess-yocto-emmc \
	$(addprefix $(INSTALL_ROOT_ARTIFACTS)/software/yocto_linux_emmc/, $(YOCTO_EMMC_ARTIFACT_FILES))
	mkdir -p $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/Image $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/$(KAS_LINUX_DTB) $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/boot.scr.uimg $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/console-image-minimal-$(KAS_MACHINE).rootfs.manifest $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/console-image-minimal-$(KAS_MACHINE).rootfs.tar.gz $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/gsrd-console-image-$(KAS_MACHINE).rootfs.manifest $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/gsrd-console-image-$(KAS_MACHINE).rootfs.tar.gz $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/kernel.itb $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/emmcimage.tar.gz $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/emmcimage.tar.gz.md5sum $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/u-boot-spl $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/u-boot-spl-dtb.bin $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/u-boot-spl-dtb.hex $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/u-boot.bin $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/u-boot.itb $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/uboot.env $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
	cp -f $(YOCTO_EMMC_IMAGE_DIR)/uboot_bin.sh $(INSTALL_ROOT_BINARIES)/software/yocto_linux_emmc/
