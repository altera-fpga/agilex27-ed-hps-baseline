# Roll-your-own Linux SD Build (Agilex 27 software-only)
# Required inputs: REVISION, INSTALL_ROOT_ARTIFACTS
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

ifeq ($(strip $(REVISION)),)
$(error ERROR: REVISION was not set. Pass REVISION=<revision> on the command line)
endif

ifeq ($(strip $(INSTALL_ROOT_ARTIFACTS)),)
$(error ERROR: INSTALL_ROOT_ARTIFACTS was not defined before ryo_linux_sd.mk was parsed)
endif

RYO_IMAGE_DIR := software/ryo_linux/build_output
RYO_BUILD_SCRIPT := software/ryo_linux/ryo_linux_sd.sh

.PHONY: clean-sw
clean-sw:
	cd software/ryo_linux && ./clean_build.sh

.PHONY: build-sw
build-sw: $(RYO_IMAGE_DIR)/sdcard.img

$(RYO_IMAGE_DIR)/sdcard.img: $(RYO_BUILD_SCRIPT)
	cd software/ryo_linux && ./ryo_linux_sd.sh

.PHONY: install-sw
install-sw: $(INSTALL_ROOT_ARTIFACTS)/software/ryo_linux/sdcard.img

$(INSTALL_ROOT_ARTIFACTS)/software/ryo_linux/sdcard.img: $(RYO_IMAGE_DIR)/sdcard.img
	mkdir -p $(dir $@)
	cp -f $(RYO_IMAGE_DIR)/sdcard.img $@
