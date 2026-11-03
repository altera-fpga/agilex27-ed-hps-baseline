// Defines constants for HPS to FPGA bridge interface (soc_noc / H2F BFM side).
package hps_h2f_pkg;

    localparam H2F_ID_WIDTH = 11;
    localparam H2F_DATA_WIDTH = 256;
    localparam H2F_ADDR_WIDTH = 47;
    localparam H2F_USER_WIDTH = 32;
    localparam H2F_SYMBOLS_PER_WORD = H2F_DATA_WIDTH / 8;

    // The soc2noc BFM drives the AXI input of hps_mnoc_init. That init has a
    // single identity AT (RULE0: base 0, 256 GB, target offset 0) whose only
    // enabled destination is fpga_mnoc_tgt -> hps2fpga. Sending 0 therefore
    // hits fabric OCRAM. Do not add a CPU-visible aperture here.
    localparam H2F_OCRAM_BASE_ADDR = 32'h0000_0000;
    localparam H2F_OCRAM_SIZE = 32'h0004_0000;

endpackage
