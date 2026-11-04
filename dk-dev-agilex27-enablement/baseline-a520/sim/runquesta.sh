#! /bin/bash
set -eo pipefail

# Determine the path to the bash script
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Toplevel design directory
DESIGN_ROOT_DIR="$(realpath $SCRIPT_DIR/..)"

# Toplevel sim script generation (match runvcs.sh)
SIM_SCRIPT_GEN_DIR=$DESIGN_ROOT_DIR/sim_setup_baseline_a520

# ------------------------------------------------------------------------------
# Ensure nios_mem.hex is present in *this* simulation run directory.
# Questa/memory init typically looks for it relative to the current working dir.
# ------------------------------------------------------------------------------
if [ ! -f "nios_mem.hex" ]; then
  echo "INFO: nios_mem.hex not found in $(pwd). Searching under DESIGN_ROOT_DIR=$DESIGN_ROOT_DIR"

  # Find the first matching file under the design root (skip common huge dirs to speed up)
  NIOS_HEX_PATH="$(
    find "$DESIGN_ROOT_DIR" \
      -type d \( -name .git -o -name sim_setup_baseline_a520 -o -name work -o -name output_files \) -prune -false \
      -o -type f -name "nios_mem.hex" -print \
    | head -n 1
  )"

  if [ -z "${NIOS_HEX_PATH}" ]; then
    echo "ERROR: Could not locate nios_mem.hex anywhere under: $DESIGN_ROOT_DIR" >&2
    echo "       Nios memory init file is required for baseline_a520_tb.sv to see nios_start." >&2
    exit 2
  fi

  echo "INFO: Found nios_mem.hex at: ${NIOS_HEX_PATH}"
  cp -f "${NIOS_HEX_PATH}" "./nios_mem.hex"
  echo "INFO: Copied to: $(pwd)/nios_mem.hex"
fi

# # TOP-LEVEL TEMPLATE - BEGIN
# #
# # QSYS_SIMDIR is used in the Quartus-generated IP simulation script to
# # construct paths to the files required to simulate the IP in your Quartus
# # project. By default, the IP script assumes that you are launching the
# # simulator from the IP script location. If launching from another
# # location, set QSYS_SIMDIR to the output directory you specified when you
# # generated the IP script, relative to the directory from which you launch
# # the simulator.
# #
# set QSYS_SIMDIR <script generation output directory>
# #
# # Source the generated IP simulation script.
# source $QSYS_SIMDIR/mentor/msim_setup.tcl
# #
# # Set any compilation options you require (this is unusual).
# set USER_DEFINED_COMPILE_OPTIONS <compilation options>
# set USER_DEFINED_VHDL_COMPILE_OPTIONS <compilation options for VHDL>
# set USER_DEFINED_VERILOG_COMPILE_OPTIONS <compilation options for Verilog>
# #
# # Call command to compile the Quartus EDA simulation library.
# dev_com
# #
# # Call command to compile the Quartus-generated IP simulation files.
# com
# #
# # Add commands to compile all design files and testbench files, including
# # the top level. (These are all the files required for simulation other
# # than the files compiled by the Quartus-generated IP simulation script)
# #
# vlog <compilation options> <design and testbench files>
# #
# # Set the top-level simulation or testbench module/entity name, which is
# # used by the elab command to elaborate the top level.
# #
# set TOP_LEVEL_NAME <simulation top>
# #
# # Set any elaboration options you require.
# set USER_DEFINED_ELAB_OPTIONS <elaboration options>
# #
# # Call command to elaborate your design and testbench.
# elab
# # Elaborate design with -voptargs=+acc option
# elab_debug
# #
# # Run the simulation.
# run -all;
# #
# # Report success to the shell.
# exit -code 0
# #
# # TOP-LEVEL TEMPLATE - END

# vsim option
# 	-c   runs the simulator in console mode
# 	-gui launches the simulator in GUI mode

vsim -c -do "
	set QSYS_SIMDIR $SIM_SCRIPT_GEN_DIR;
	source $SIM_SCRIPT_GEN_DIR/mentor/msim_setup.tcl;
	set TOP_LEVEL_NAME testbench;
	dev_com;
	com;
	vlog -sv $DESIGN_ROOT_DIR/src/debounce.sv;
	vlog -sv $DESIGN_ROOT_DIR/src/clocks_and_resets.sv;
	vlog -sv $DESIGN_ROOT_DIR/baseline_a520.sv;
	vlog -sv $DESIGN_ROOT_DIR/sim/hps_h2f_pkg.sv;
	vlog -sv $DESIGN_ROOT_DIR/sim/hps_h2f_lw_pkg.sv;
	vlog -sv -timescale 1ps/1ps $DESIGN_ROOT_DIR/sim/bridges_clk_rst.sv -L altera_km_lnsim_ver -L nextgen_km_hps_ver;
	vlog -sv -timescale 1ps/1ps $DESIGN_ROOT_DIR/sim/hps_bridges_bfms.sv -L altera_km_lnsim_ver -L nextgen_km_hps_ver;
	vlog -sv -timescale 1ps/1ps $DESIGN_ROOT_DIR/sim/baseline_a520_tb.sv -L altera_km_lnsim_ver -L nextgen_km_hps_ver;
	set USER_DEFINED_ELAB_OPTIONS \"-suppress 14408  -voptargs=-svext=+adta\";
	elab_debug;
	run -all"

# Check simulation results for errors
if [ -f transcript ]; then
    if grep -qiE "(FAIL|Error:|Fatal)" transcript; then
        echo "ERROR: Simulation failed! Check transcript for details."
        grep -iE "(FAIL|Error:|Fatal)" transcript
        exit 1
    else
        echo "Simulation completed successfully."
        exit 0
    fi
else
    echo "ERROR: Transcript file not found!"
    exit 1
fi
