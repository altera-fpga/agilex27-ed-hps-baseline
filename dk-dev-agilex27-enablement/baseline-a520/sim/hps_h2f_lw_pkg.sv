// Defines constants for HPS to FPGA LW bridge interface
package hps_h2f_lw_pkg;

    localparam LWH2F_DATA_WIDTH = 32;
    localparam LWH2F_ADDR_WIDTH = 32;
    localparam LWH2F_SYMBOLS_PER_WORD = LWH2F_DATA_WIDTH / 8;

    // LWH2F_BRIDGE_BASE is the HPS-visible RNoC window (hps_rnoc_init RULE1).
    // The lw_soc2noc BFM sits before that decoder, so simulation and HPS
    // software use the same map: window + fabric offset.
    // 0x0000_0000 in this space is SDM (RULE0), not fabric.
    // 0x0800_0000 in this space is FPGA fabric (RULE1).
    localparam LWH2F_BRIDGE_BASE = 32'h0800_0000;

    localparam LWH2F_BUTTON_PIO_BASE_ADDR = 32'h0001_0060;
    localparam LWH2F_BUTTON_PIO_SIZE = 32'h0000_0010;
    localparam LWH2F_DIPSW_PIO_BASE_ADDR = 32'h0001_0070;
    localparam LWH2F_DIPSW_PIO_SIZE = 32'h0000_0010;
    localparam LWH2F_LED_PIO_BASE_ADDR = 32'h0001_0080;
    localparam LWH2F_LED_PIO_SIZE = 32'h0000_0010;
    localparam LWH2F_SYSID_BASE_ADDR = 32'h0001_0000;
    localparam LWH2F_SYSID_SIZE = 32'h0000_0010;
    localparam LWH2F_SYSID_VALUE = 32'h0000_0001;

    localparam LWH2F_SYSID_ADDR = LWH2F_BRIDGE_BASE + LWH2F_SYSID_BASE_ADDR;
    localparam LWH2F_LED_PIO_ADDR = LWH2F_BRIDGE_BASE + LWH2F_LED_PIO_BASE_ADDR;

endpackage
