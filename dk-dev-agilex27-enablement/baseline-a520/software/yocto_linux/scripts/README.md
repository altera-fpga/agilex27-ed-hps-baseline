# Steps to create QSPI bootable image

- Install mtd utilities
	```
	sudo apt update
	sudo apt install mtd-utils
	```
- Copy SOF files(`baseline_a520_yocto_linux_qspi.sof` & `baseline_a520_hps_debug.sof`) into `yocto_linux/build/tmp/deploy/images/agilex5e/`

- Copy scripts from `yocto_linux/scripts/*` into `yocto_linux/build/tmp/deploy/images/agilex5e/`

- cd to `yocto_linux/build/tmp/deploy/images/agilex5e/`

- Execute following scripts and commands to produce UBI and JIC images for QSPI boot.

    **Note:** This README assumes that the Quartus tool installed and properly configured.

	```
    # Create u-boot.bin
    $ ./uboot_bin.sh

    # Create UBI image 'root.ubi' using config file 'ubinize_nor.cfg'
    $ ubinize -o root.ubi -p 65536 -m 1 -s 1 ubinize_nor.cfg

    # Create UBI image 'hps.bin' using config file 'ubinize_nor.cfg'
    $ ubinize -o hps.bin -p 65536 -m 1 -s 1 ubinize_nor.cfg

    # Pad hps.bin to 190MB to match MTD partition size (defined in u-boot-env.txt)
    # This ensures U-Boot doesn't scan uninitialized flash beyond the UBI image
    $ truncate -s 190M hps.bin

    # Generate full QSPI JIC image with HPS first boot - qspi_flash_image.hps.jic
    $ quartus_pfg -c flash_image_hps.pfg

    # Generate full QSPI JIC image with FPGA first boot - qspi_flash_image.jic
    $ quartus_pfg -c flash_image.pfg

    # Generate QSPI JIC image containing only U-Boot - uboot.jic
    $ quartus_pfg -c uboot_only.pfg

    # Create core.rbf file
    $ quartus_pfg -o hps=ON -c -o hps_path=u-boot-spl-dtb.hex baseline_a520_hps_debug.sof ghrd.rbf
	```
