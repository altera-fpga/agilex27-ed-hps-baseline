`timescale 1 ps / 1 ps
//
`default_nettype none

module baseline_a520 (
    // User switches and LEDs
    output wire [4-1:0] fpga_user_leds,
    input  wire [4-1:0] fpga_user_switches,
    input  wire [4-1:0] fpga_user_push_buttons,

    // Memory Subsystem
    output wire [ 0:0] emif_ddr5_0_mem_ch0_mem_cs_n,
    output wire [13:0] emif_ddr5_0_mem_ch0_mem_ca,
    inout  wire [31:0] emif_ddr5_0_mem_ch0_mem_dq,
    inout  wire [ 3:0] emif_ddr5_0_mem_ch0_mem_dqs_t,
    inout  wire [ 3:0] emif_ddr5_0_mem_ch0_mem_dqs_c,
    input  wire        emif_ddr5_0_mem_ch0_mem_alert_n,
    output wire [ 0:0] emif_ddr5_0_mem_ck_ch0_mem_ck_t,
    output wire [ 0:0] emif_ddr5_0_mem_ck_ch0_mem_ck_c,
    output wire        emif_ddr5_0_mem_reset_n_mem_reset_n,
    input  wire        emif_ddr5_0_mem_ref_clk_clk,

    //
    //HPS
    // HPS IO60 Peripherals
    input  wire hps_io_spim0_spim0_ss1_n,
    input  wire hps_io_spim0_spim0_clk,
    input  wire hps_io_spim0_spim0_mosi,
    output wire hps_io_spim0_spim0_miso,
    input  wire hps_io_spim0_spim0_ss0_n,
    inout  wire hps_io_ospi_ospi_data0,
    inout  wire hps_io_ospi_ospi_data1,
    input  wire hps_io_ospi_ospi_clk,
    input  wire hps_io_ospi_ospi_write_protect,
    inout  wire hps_io_ospi_ospi_data2,
    inout  wire hps_io_ospi_ospi_data3,
    input  wire hps_io_ospi_ospi_cs_n,
    inout  wire hps_io_ospi_ospi_data4,
    inout  wire hps_io_ospi_ospi_data5,
    inout  wire hps_io_ospi_ospi_data6,
    inout  wire hps_io_ospi_ospi_data7,
    input  wire hps_io_ospi_ospi_cs1_n,
    input  wire hps_io_ospi_ospi_reset1_n,
    input  wire hps_io_ospi_ospi_reset_n,
    inout  wire hps_io_ospi_ospi_data_strobe,
    output wire hps_io_uart0_uart0_cts_n,
    input  wire hps_io_uart0_uart0_rts_n,
    input  wire hps_io_uart0_uart0_tx,
    output wire hps_io_uart0_uart0_rx,
    inout  wire hps_io_sdemmc0_sdemmc0_data0,
    inout  wire hps_io_sdemmc0_sdemmc0_data1,
    input  wire hps_io_sdemmc0_sdemmc0_clk,
    output wire hps_io_sdemmc0_sdemmc0_write_protect,
    inout  wire hps_io_sdemmc0_sdemmc0_data2,
    inout  wire hps_io_sdemmc0_sdemmc0_data3,
    inout  wire hps_io_sdemmc0_sdemmc0_cmd,
    inout  wire hps_io_sdemmc0_sdemmc0_data4,
    inout  wire hps_io_sdemmc0_sdemmc0_data5,
    inout  wire hps_io_sdemmc0_sdemmc0_data6,
    inout  wire hps_io_sdemmc0_sdemmc0_data7,
    input  wire hps_io_sdemmc0_sdemmc0_pu_pd_data2,
    input  wire hps_io_sdemmc0_sdemmc0_pwr_ena,
    output wire hps_io_sdemmc0_sdemmc0_data_strobe,
    output wire hps_io_sdemmc0_sdemmc0_card_detect,
    output wire hps_io_i2c0_i2c0_smbalert_n,
    inout  wire hps_io_i2c0_i2c0_sda,
    inout  wire hps_io_i2c0_i2c0_scl,
    inout  wire hps_io_i3c0_i3c0_sda,
    inout  wire hps_io_i3c0_i3c0_scl,
    input  wire hps_io_i3c0_i3c0_sda_pullup_en,
    input  wire hps_io_usb31phy_usb31phy_vbus_ctrl,
    output wire hps_io_usb31phy_usb31phy_usb31_id,
    output wire hps_io_usb31phy_usb31phy_vbus_det,
    output wire hps_io_usb31phy_usb31phy_over_curr,
    input  wire hps_io_usb31phy_usb31phy_usb2_rst_n,
    output wire hps_io_i2c1_i2c1_smbalert_n,
    inout  wire hps_io_i2c1_i2c1_sda,
    inout  wire hps_io_i2c1_i2c1_scl,

    // HPS fabric peripherials
    input  wire usb_pipe3_phy_ref_pad_clk_m,
    input  wire usb_pipe3_phy_ref_pad_clk_p,
    input  wire usb_pipe3_phy_resref_bidir_in,
    input  wire usb_pipe3_phy_rx_m,
    input  wire usb_pipe3_phy_rx_p,
    output wire usb_pipe3_phy_resref_bidir_out,
    output wire usb_pipe3_phy_tx_m,
    output wire usb_pipe3_phy_tx_p,

    input  wire       emac_ptp_ref_clk_clk,
    input  wire       emac1_mdio_gmii_mdi,
    output wire       emac1_mdio_gmii_mdc,
    output wire       emac1_mdio_gmii_mdo_e,
    output wire       emac1_mdio_gmii_mdo,
    input  wire       emac1_phy_col,
    input  wire       emac1_phy_crs,
    input  wire [7:0] emac1_phy_rxd,
    input  wire       emac1_phy_rxdv,
    input  wire       emac1_phy_rxer,
    output wire [2:0] emac1_phy_mac_speed,
    output wire [7:0] emac1_phy_txd_gmii,
    output wire [7:0] emac1_phy_txd,
    output wire       emac1_phy_txen,
    output wire       emac1_phy_txer,
    output wire       emac1_rst_clk_app_n_reset,
    output wire       emac1_rst_clk_rx_n_o_reset,
    output wire       emac1_rst_clk_tx_n_o_reset,
    input  wire       emac1_phy_rxclk_clk,
    input  wire       emac1_phy_txclk_i_clk,
    output wire       emac1_phy_txclk_o_clk,

    input  wire i3c1_f2h_sda,
    output wire i3c1_h2f_sda,
    output wire i3c1_scl_oe,
    output wire i3c1_scl_pullup_en,
    output wire i3c1_sda_oe,
    output wire i3c1_sda_pullup_en,
    input  wire i3c1_scl_in_clk,
    output wire i3c1_scl_out_clk,

    // sdm io
    output wire sdmio_1_jtag_tdo_out,
    input  wire sdmio_2_jtag_tck_in,
    input  wire sdmio_3_jtag_tdi_in,
    input  wire sdmio_4_jtag_tms_in,
    input  wire sdmio_5_cfg_nconfig_in,
    input  wire sdmio_6_ref_refclk_in,
    input  wire sdmio_9_pm_i2c_sda_in,
    input  wire sdmio_9_pm_i2c_sda_oe,
    output wire sdmio_9_pm_i2c_sda_out,
    input  wire sdmio_10_pm_i2c_scl_in,
    input  wire sdmio_10_pm_i2c_scl_oe,
    output wire sdmio_10_pm_i2c_scl_out,
    output wire sdmio_11_ospi_clk_out,
    input  wire sdmio_12_ospi_data0_in,
    input  wire sdmio_12_ospi_data0_oe,
    output wire sdmio_12_ospi_data0_out,
    input  wire sdmio_13_ospi_data1_in,
    input  wire sdmio_13_ospi_data1_oe,
    output wire sdmio_13_ospi_data1_out,
    input  wire sdmio_14_ospi_data2_in,
    input  wire sdmio_14_ospi_data2_oe,
    output wire sdmio_14_ospi_data2_out,
    input  wire sdmio_15_ospi_data3_in,
    input  wire sdmio_15_ospi_data3_oe,
    output wire sdmio_15_ospi_data3_out,
    input  wire sdmio_16_ospi_data4_in,
    input  wire sdmio_16_ospi_data4_oe,
    output wire sdmio_16_ospi_data4_out,
    input  wire sdmio_17_ospi_data_stb_in,
    input  wire sdmio_17_ospi_data_stb_oe,
    output wire sdmio_17_ospi_data_stb_out,
    input  wire sdmio_18_ospi_data5_in,
    input  wire sdmio_18_ospi_data5_oe,
    output wire sdmio_18_ospi_data5_out,
    input  wire sdmio_19_ospi_data6_in,
    input  wire sdmio_19_ospi_data6_oe,
    output wire sdmio_19_ospi_data6_out,
    input  wire sdmio_20_ospi_data7_in,
    input  wire sdmio_20_ospi_data7_oe,
    output wire sdmio_20_ospi_data7_out,
    output wire sdmio_21_ospi_rst_n_out,
    output wire sdmio_22_ospi_cs0_n_out,
    input  wire sdmio_23_i3c_scl_in,
    input  wire sdmio_24_i3c_sda_in,
    input  wire sdmio_24_i3c_sda_oe,
    output wire sdmio_24_i3c_sda_out,
    input  wire sdmio_33_dfx_dig_viewpin_0_in,
    input  wire sdmio_33_dfx_dig_viewpin_0_oe,
    output wire sdmio_33_dfx_dig_viewpin_0_out,
    input  wire sdmio_34_dfx_dig_viewpin_1_in,
    input  wire sdmio_34_dfx_dig_viewpin_1_oe,
    output wire sdmio_34_dfx_dig_viewpin_1_out,

    // External FPGA Reset
    input wire fpga_reset_n
);
    // Constants
    localparam LED_PIO_WIDTH = 32;
    localparam DIPSW_PIO_WIDTH = 32;
    localparam BUTTONS_PIO_WIDTH = 32;

    // Clock and Reset
    wire sys_clk_100;
    wire sys_clk_100_reset_n;
    // use osc clock from config qhip as fpga clock.
    wire pll_refclk_100;

    wire [31:0] niosv_pio_in;
    // Set this bit to enable the NiosV firmware. Disabled by default.
    wire nios_enable = 1'b0;
    assign niosv_pio_in = {31'b0, nios_enable};

    wire [31:0] niosv_pio_out;
    wire nios_start;
    wire nios_done;
    wire nios_f2sdram_pass;
    wire nios_f2h_pass;
    assign nios_start = niosv_pio_out[0];
    assign nios_f2sdram_pass = niosv_pio_out[1];
    assign nios_f2h_pass = niosv_pio_out[2];
    assign nios_done = niosv_pio_out[3];

    // Debounce logic to clean out push button glitches within 1ms
    wire [BUTTONS_PIO_WIDTH-1:0] fpga_debounced_buttons;
    wire [BUTTONS_PIO_WIDTH-1:0] fpga_push_buttons;
    assign fpga_push_buttons = {
        {BUTTONS_PIO_WIDTH - $size(fpga_user_push_buttons) {1'b0}}, fpga_user_push_buttons
    };

    debounce #(
        .WIDTH        (32),
        .POLARITY     ("LOW"),
        .TIMEOUT      (10000),  // at 100MHz this is a debounce time of 1ms
        .TIMEOUT_WIDTH(32)      // ceil(log2(TIMEOUT))
    ) debounce_inst (
        .clk     (sys_clk_100),
        .reset_n (sys_clk_100_reset_n),
        .data_in (fpga_push_buttons),
        .data_out(fpga_debounced_buttons)
    );

    // Assign DIPSW I/O
    wire [DIPSW_PIO_WIDTH-1:0] fpga_switches;
    assign fpga_switches = {
        {DIPSW_PIO_WIDTH - $size(fpga_user_switches) {1'b0}}, fpga_user_switches
    };

    // Create a heartbeat counter
    reg [22:0] heartbeat_count;
    always @(posedge sys_clk_100) begin
        if (!sys_clk_100_reset_n) begin
            heartbeat_count <= '0;
        end else begin
            heartbeat_count <= heartbeat_count + 23'd1;
        end
    end

    // Create a heartbeat LED
    wire heartbeat_led;
    assign heartbeat_led = heartbeat_count[22];

    // LED PIO
    wire [LED_PIO_WIDTH-1:0] fpga_leds;

    // Drive the USER PIN LEDs to be the HPS LED outputs
    // in addition to the heartbeat LED
    assign fpga_user_leds = {heartbeat_led, fpga_leds[2:0]};

    // Tie off all fabric to HPS interrupts
    wire [31:0] fpga2hps_interrupts;
    assign fpga2hps_interrupts = '0;

    // Directly loop reset request signal to the reset acknowledge signals.
    logic h2f_warm_reset_handshake_reset_ack;
    logic h2f_warm_reset_handshake_reset_req;

    assign h2f_warm_reset_handshake_reset_ack = h2f_warm_reset_handshake_reset_req;

    // Baseline-A55 system top module
    baseline_top u_baseline_top (
        // Board PLL reference clock
        .fpga_clk_100_clk      (pll_refclk_100),
        .o_osc_100mhz_clk_clk  (pll_refclk_100),
        // External FPGA reset
        .fpga_reset_n_reset_n  (fpga_reset_n),
        // System clock and reset to FPGA
        .system_clk_clk        (sys_clk_100),
        .system_reset_n_reset_n(sys_clk_100_reset_n),

        // LEDs, Push Buttons and DIP Switches IOs
        .external_leds_export        (fpga_leds),
        .external_switches_export    (fpga_switches),
        .external_push_buttons_export(fpga_debounced_buttons),

        // Memory Subsystem
        .emif_ddr5_0_mem_ch0_mem_cs_n       (emif_ddr5_0_mem_ch0_mem_cs_n),
        .emif_ddr5_0_mem_ch0_mem_ca         (emif_ddr5_0_mem_ch0_mem_ca),
        .emif_ddr5_0_mem_ch0_mem_dq         (emif_ddr5_0_mem_ch0_mem_dq),
        .emif_ddr5_0_mem_ch0_mem_dqs_t      (emif_ddr5_0_mem_ch0_mem_dqs_t),
        .emif_ddr5_0_mem_ch0_mem_dqs_c      (emif_ddr5_0_mem_ch0_mem_dqs_c),
        .emif_ddr5_0_mem_ch0_mem_alert_n    (emif_ddr5_0_mem_ch0_mem_alert_n),
        .emif_ddr5_0_mem_ck_ch0_mem_ck_t    (emif_ddr5_0_mem_ck_ch0_mem_ck_t),
        .emif_ddr5_0_mem_ck_ch0_mem_ck_c    (emif_ddr5_0_mem_ck_ch0_mem_ck_c),
        .emif_ddr5_0_mem_reset_n_mem_reset_n(emif_ddr5_0_mem_reset_n_mem_reset_n),
        .emif_ddr5_0_mem_ref_clk_clk        (emif_ddr5_0_mem_ref_clk_clk),

        //
        //HPS
        .h2f_warm_reset_handshake_reset_req  (h2f_warm_reset_handshake_reset_req),
        .h2f_warm_reset_handshake_reset_ack  (h2f_warm_reset_handshake_reset_ack),
        .usb_pipe3_phy_ref_pad_clk_m         (usb_pipe3_phy_ref_pad_clk_m),
        .usb_pipe3_phy_ref_pad_clk_p         (usb_pipe3_phy_ref_pad_clk_p),
        .usb_pipe3_phy_resref_bidir_in       (usb_pipe3_phy_resref_bidir_in),
        .usb_pipe3_phy_rx_m                  (usb_pipe3_phy_rx_m),
        .usb_pipe3_phy_rx_p                  (usb_pipe3_phy_rx_p),
        .usb_pipe3_phy_resref_bidir_out      (usb_pipe3_phy_resref_bidir_out),
        .usb_pipe3_phy_tx_m                  (usb_pipe3_phy_tx_m),
        .usb_pipe3_phy_tx_p                  (usb_pipe3_phy_tx_p),
        .emac_ptp_ref_clk_clk                (emac_ptp_ref_clk_clk),
        .emac1_mdio_gmii_mdi                 (emac1_mdio_gmii_mdi),
        .emac1_mdio_gmii_mdc                 (emac1_mdio_gmii_mdc),
        .emac1_mdio_gmii_mdo_e               (emac1_mdio_gmii_mdo_e),
        .emac1_mdio_gmii_mdo                 (emac1_mdio_gmii_mdo),
        .emac1_phy_col                       (emac1_phy_col),
        .emac1_phy_crs                       (emac1_phy_crs),
        .emac1_phy_rxd                       (emac1_phy_rxd),
        .emac1_phy_rxdv                      (emac1_phy_rxdv),
        .emac1_phy_rxer                      (emac1_phy_rxer),
        .emac1_phy_mac_speed                 (emac1_phy_mac_speed),
        .emac1_phy_txd_gmii                  (emac1_phy_txd_gmii),
        .emac1_phy_txd                       (emac1_phy_txd),
        .emac1_phy_txen                      (emac1_phy_txen),
        .emac1_phy_txer                      (emac1_phy_txer),
        .emac1_rst_clk_app_n_reset           (emac1_rst_clk_app_n_reset),
        .emac1_rst_clk_rx_n_o_reset          (emac1_rst_clk_rx_n_o_reset),
        .emac1_rst_clk_tx_n_o_reset          (emac1_rst_clk_tx_n_o_reset),
        .emac1_phy_rxclk_clk                 (emac1_phy_rxclk_clk),
        .emac1_phy_txclk_i_clk               (emac1_phy_txclk_i_clk),
        .emac1_phy_txclk_o_clk               (emac1_phy_txclk_o_clk),
        .i3c1_f2h_sda                        (i3c1_f2h_sda),
        .i3c1_h2f_sda                        (i3c1_h2f_sda),
        .i3c1_scl_oe                         (i3c1_scl_oe),
        .i3c1_scl_pullup_en                  (i3c1_scl_pullup_en),
        .i3c1_sda_oe                         (i3c1_sda_oe),
        .i3c1_sda_pullup_en                  (i3c1_sda_pullup_en),
        .i3c1_scl_in_clk                     (i3c1_scl_in_clk),
        .i3c1_scl_out_clk                    (i3c1_scl_out_clk),
        .hps_io_spim0_spim0_ss1_n            (hps_io_spim0_spim0_ss1_n),
        .hps_io_spim0_spim0_clk              (hps_io_spim0_spim0_clk),
        .hps_io_spim0_spim0_mosi             (hps_io_spim0_spim0_mosi),
        .hps_io_spim0_spim0_miso             (hps_io_spim0_spim0_miso),
        .hps_io_spim0_spim0_ss0_n            (hps_io_spim0_spim0_ss0_n),
        .hps_io_ospi_ospi_data0              (hps_io_ospi_ospi_data0),
        .hps_io_ospi_ospi_data1              (hps_io_ospi_ospi_data1),
        .hps_io_ospi_ospi_clk                (hps_io_ospi_ospi_clk),
        .hps_io_ospi_ospi_write_protect      (hps_io_ospi_ospi_write_protect),
        .hps_io_ospi_ospi_data2              (hps_io_ospi_ospi_data2),
        .hps_io_ospi_ospi_data3              (hps_io_ospi_ospi_data3),
        .hps_io_ospi_ospi_cs_n               (hps_io_ospi_ospi_cs_n),
        .hps_io_ospi_ospi_data4              (hps_io_ospi_ospi_data4),
        .hps_io_ospi_ospi_data5              (hps_io_ospi_ospi_data5),
        .hps_io_ospi_ospi_data6              (hps_io_ospi_ospi_data6),
        .hps_io_ospi_ospi_data7              (hps_io_ospi_ospi_data7),
        .hps_io_ospi_ospi_cs1_n              (hps_io_ospi_ospi_cs1_n),
        .hps_io_ospi_ospi_reset1_n           (hps_io_ospi_ospi_reset1_n),
        .hps_io_ospi_ospi_reset_n            (hps_io_ospi_ospi_reset_n),
        .hps_io_ospi_ospi_data_strobe        (hps_io_ospi_ospi_data_strobe),
        .hps_io_uart0_uart0_cts_n            (hps_io_uart0_uart0_cts_n),
        .hps_io_uart0_uart0_rts_n            (hps_io_uart0_uart0_rts_n),
        .hps_io_uart0_uart0_tx               (hps_io_uart0_uart0_tx),
        .hps_io_uart0_uart0_rx               (hps_io_uart0_uart0_rx),
        .hps_io_sdemmc0_sdemmc0_data0        (hps_io_sdemmc0_sdemmc0_data0),
        .hps_io_sdemmc0_sdemmc0_data1        (hps_io_sdemmc0_sdemmc0_data1),
        .hps_io_sdemmc0_sdemmc0_clk          (hps_io_sdemmc0_sdemmc0_clk),
        .hps_io_sdemmc0_sdemmc0_write_protect(hps_io_sdemmc0_sdemmc0_write_protect),
        .hps_io_sdemmc0_sdemmc0_data2        (hps_io_sdemmc0_sdemmc0_data2),
        .hps_io_sdemmc0_sdemmc0_data3        (hps_io_sdemmc0_sdemmc0_data3),
        .hps_io_sdemmc0_sdemmc0_cmd          (hps_io_sdemmc0_sdemmc0_cmd),
        .hps_io_sdemmc0_sdemmc0_data4        (hps_io_sdemmc0_sdemmc0_data4),
        .hps_io_sdemmc0_sdemmc0_data5        (hps_io_sdemmc0_sdemmc0_data5),
        .hps_io_sdemmc0_sdemmc0_data6        (hps_io_sdemmc0_sdemmc0_data6),
        .hps_io_sdemmc0_sdemmc0_data7        (hps_io_sdemmc0_sdemmc0_data7),
        .hps_io_sdemmc0_sdemmc0_pu_pd_data2  (hps_io_sdemmc0_sdemmc0_pu_pd_data2),
        .hps_io_sdemmc0_sdemmc0_pwr_ena      (hps_io_sdemmc0_sdemmc0_pwr_ena),
        .hps_io_sdemmc0_sdemmc0_data_strobe  (hps_io_sdemmc0_sdemmc0_data_strobe),
        .hps_io_sdemmc0_sdemmc0_card_detect  (hps_io_sdemmc0_sdemmc0_card_detect),
        .hps_io_i2c0_i2c0_smbalert_n         (hps_io_i2c0_i2c0_smbalert_n),
        .hps_io_i2c0_i2c0_sda                (hps_io_i2c0_i2c0_sda),
        .hps_io_i2c0_i2c0_scl                (hps_io_i2c0_i2c0_scl),
        .hps_io_i3c0_i3c0_sda                (hps_io_i3c0_i3c0_sda),
        .hps_io_i3c0_i3c0_scl                (hps_io_i3c0_i3c0_scl),
        .hps_io_i3c0_i3c0_sda_pullup_en      (hps_io_i3c0_i3c0_sda_pullup_en),
        .hps_io_usb31phy_usb31phy_vbus_ctrl  (hps_io_usb31phy_usb31phy_vbus_ctrl),
        .hps_io_usb31phy_usb31phy_usb31_id   (hps_io_usb31phy_usb31phy_usb31_id),
        .hps_io_usb31phy_usb31phy_vbus_det   (hps_io_usb31phy_usb31phy_vbus_det),
        .hps_io_usb31phy_usb31phy_over_curr  (hps_io_usb31phy_usb31phy_over_curr),
        .hps_io_usb31phy_usb31phy_usb2_rst_n (hps_io_usb31phy_usb31phy_usb2_rst_n),
        .hsio_irq2_irq                       ('0),
        .hsio_irq3_irq                       ('0),
        .hps_io_i2c1_i2c1_smbalert_n         (hps_io_i2c1_i2c1_smbalert_n),
        .hps_io_i2c1_i2c1_sda                (hps_io_i2c1_i2c1_sda),
        .hps_io_i2c1_i2c1_scl                (hps_io_i2c1_i2c1_scl),
        // Interrupts
        .f2h_interrupt_irq1_irq              (fpga2hps_interrupts),

        // Config QHIP
        .sdmio_1_jtag_tdo_out          (sdmio_1_jtag_tdo_out),
        .sdmio_2_jtag_tck_in           (sdmio_2_jtag_tck_in),
        .sdmio_3_jtag_tdi_in           (sdmio_3_jtag_tdi_in),
        .sdmio_4_jtag_tms_in           (sdmio_4_jtag_tms_in),
        .sdmio_5_cfg_nconfig_in        (sdmio_5_cfg_nconfig_in),
        .sdmio_6_ref_refclk_in         (sdmio_6_ref_refclk_in),
        .sdmio_9_pm_i2c_sda_in         (sdmio_9_pm_i2c_sda_in),
        .sdmio_9_pm_i2c_sda_oe         (sdmio_9_pm_i2c_sda_oe),
        .sdmio_9_pm_i2c_sda_out        (sdmio_9_pm_i2c_sda_out),
        .sdmio_10_pm_i2c_scl_in        (sdmio_10_pm_i2c_scl_in),
        .sdmio_10_pm_i2c_scl_oe        (sdmio_10_pm_i2c_scl_oe),
        .sdmio_10_pm_i2c_scl_out       (sdmio_10_pm_i2c_scl_out),
        .sdmio_11_ospi_clk_out         (sdmio_11_ospi_clk_out),
        .sdmio_12_ospi_data0_in        (sdmio_12_ospi_data0_in),
        .sdmio_12_ospi_data0_oe        (sdmio_12_ospi_data0_oe),
        .sdmio_12_ospi_data0_out       (sdmio_12_ospi_data0_out),
        .sdmio_13_ospi_data1_in        (sdmio_13_ospi_data1_in),
        .sdmio_13_ospi_data1_oe        (sdmio_13_ospi_data1_oe),
        .sdmio_13_ospi_data1_out       (sdmio_13_ospi_data1_out),
        .sdmio_14_ospi_data2_in        (sdmio_14_ospi_data2_in),
        .sdmio_14_ospi_data2_oe        (sdmio_14_ospi_data2_oe),
        .sdmio_14_ospi_data2_out       (sdmio_14_ospi_data2_out),
        .sdmio_15_ospi_data3_in        (sdmio_15_ospi_data3_in),
        .sdmio_15_ospi_data3_oe        (sdmio_15_ospi_data3_oe),
        .sdmio_15_ospi_data3_out       (sdmio_15_ospi_data3_out),
        .sdmio_16_ospi_data4_in        (sdmio_16_ospi_data4_in),
        .sdmio_16_ospi_data4_oe        (sdmio_16_ospi_data4_oe),
        .sdmio_16_ospi_data4_out       (sdmio_16_ospi_data4_out),
        .sdmio_17_ospi_data_stb_in     (sdmio_17_ospi_data_stb_in),
        .sdmio_17_ospi_data_stb_oe     (sdmio_17_ospi_data_stb_oe),
        .sdmio_17_ospi_data_stb_out    (sdmio_17_ospi_data_stb_out),
        .sdmio_18_ospi_data5_in        (sdmio_18_ospi_data5_in),
        .sdmio_18_ospi_data5_oe        (sdmio_18_ospi_data5_oe),
        .sdmio_18_ospi_data5_out       (sdmio_18_ospi_data5_out),
        .sdmio_19_ospi_data6_in        (sdmio_19_ospi_data6_in),
        .sdmio_19_ospi_data6_oe        (sdmio_19_ospi_data6_oe),
        .sdmio_19_ospi_data6_out       (sdmio_19_ospi_data6_out),
        .sdmio_20_ospi_data7_in        (sdmio_20_ospi_data7_in),
        .sdmio_20_ospi_data7_oe        (sdmio_20_ospi_data7_oe),
        .sdmio_20_ospi_data7_out       (sdmio_20_ospi_data7_out),
        .sdmio_21_ospi_rst_n_out       (sdmio_21_ospi_rst_n_out),
        .sdmio_22_ospi_cs0_n_out       (sdmio_22_ospi_cs0_n_out),
        .sdmio_23_i3c_scl_in           (sdmio_23_i3c_scl_in),
        .sdmio_24_i3c_sda_in           (sdmio_24_i3c_sda_in),
        .sdmio_24_i3c_sda_oe           (sdmio_24_i3c_sda_oe),
        .sdmio_24_i3c_sda_out          (sdmio_24_i3c_sda_out),
        .sdmio_33_dfx_dig_viewpin_0_in (sdmio_33_dfx_dig_viewpin_0_in),
        .sdmio_33_dfx_dig_viewpin_0_oe (sdmio_33_dfx_dig_viewpin_0_oe),
        .sdmio_33_dfx_dig_viewpin_0_out(sdmio_33_dfx_dig_viewpin_0_out),
        .sdmio_34_dfx_dig_viewpin_1_in (sdmio_34_dfx_dig_viewpin_1_in),
        .sdmio_34_dfx_dig_viewpin_1_oe (sdmio_34_dfx_dig_viewpin_1_oe),
        .sdmio_34_dfx_dig_viewpin_1_out(sdmio_34_dfx_dig_viewpin_1_out),

        .sdm_pio_f2s_pio_i('0),
        .sdm_pio_s2f_pio_o(),

        // NiosV subsys PIO
        .niosv_pio_in_export (niosv_pio_in),
        .niosv_pio_out_export(niosv_pio_out)
    );

endmodule
