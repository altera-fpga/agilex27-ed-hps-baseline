`timescale 1 ps / 1 ps
//
`default_nettype none

// import libraries
import altera_axi_bfm_pkg::*;
import host_memory_class_pkg::*;

// import packages
import hps_h2f_pkg::*;
import hps_h2f_lw_pkg::*;

// Define helpers for hierarchical access into the DUT / TB-owned BFMs.
`define h2f_bfm_m u_bfms.testbench_h2f_bfm
`define lwh2f_bfm_m u_bfms.testbench_lwh2f_bfm
// Agilex 27 HPS sim model has no f2sdram_bfm_gen / f2soc_bfm_gen subordinate
// BFMs (those exist only on Agilex 5 MPFE). Monitor the HPS-exported
// fpga2hpsmem ACE5-Lite (f2soc) ports and the fabric F2SDRAM NoC initiator.
`define hps_ip dut.u_baseline_top.u_shell_subsys.u_agilex27_hps.u_agilex27_hps
`define f2h_mon `hps_ip
`define f2sdram_mon dut.u_baseline_top.u_fabric_subsys.u_ff_mnoc_init

module testbench ();

    //==================================================================================================
    // Local Signals
    //==================================================================================================

    // Clock and reset
    wire fpga_clk_100_clk;
    bit reset_done;

    // DUT signals
    logic fpga_reset_n;
    wire [3:0] fpga_led_pio;
    wire [3:0] fpga_dipsw_pio = '0;
    wire [3:0] fpga_button_pio = '0;

    // Test flag
    bit h2f_pass = 1;
    bit lwh2f_pass = 1;
    bit f2sdram_pass = 1;
    bit f2h_pass = 1;
    bit test_pass = 1;
    int f2h_txn_count = 0;
    int f2h_r_count = 0;
    int f2sdram_txn_count = 0;
    int f2sdram_r_count = 0;
    logic [255:0] f2h_rd_data[2];
    // hps2fpga test flag
    // Odd transfers = full-width; even transfers = narrow.
    // f1: xfer#1 full single, f2: xfer#2 narrow single
    // f3-f6: xfer#3 full burst beats, f7-f10: xfer#4 narrow burst beats
    bit h2f_f1 = 0;
    bit h2f_f2 = 0;
    bit h2f_f3 = 0;
    bit h2f_f4 = 0;
    bit h2f_f5 = 0;
    bit h2f_f6 = 0;
    bit h2f_f7 = 0;
    bit h2f_f8 = 0;
    bit h2f_f9 = 0;
    bit h2f_f10 = 0;

    string h2f_messageQueue[$];
    task automatic h2f_storeMessage(input string msg);
        string formattedMsg = $sformatf("[%0t] %s", $time, msg);
        h2f_messageQueue.push_back(formattedMsg);
    endtask

    // HPS2FPGA manager data bus width (BFM .DATA_WIDTH).
    localparam int H2F_BUS_BYTES = H2F_SYMBOLS_PER_WORD;

    // A narrow beat is placed in the byte lane selected by its address and the
    // BFM hands back raw rdata, so only that lane may be compared.
    function automatic bit h2f_narrow_match(input bit [255:0] rdata, input bit [127:0] expected,
                                            input int unsigned addr);
        int unsigned shift_bits;
        bit [255:0] mask;
        bit [255:0] expected_in_lane;
        shift_bits = (addr % H2F_BUS_BYTES) * 8;
        mask = '0;
        mask[127:0] = {128{1'b1}};
        mask = mask << shift_bits;
        expected_in_lane = '0;
        expected_in_lane[127:0] = expected;
        expected_in_lane = expected_in_lane << shift_bits;
        return ((rdata & mask) == expected_in_lane);
    endfunction

    // lwhps2fpga test flag
    bit lwh2f_f1 = 0;
    bit lwh2f_f2 = 0;
    bit lwh2f_f3 = 0;
    bit lwh2f_f4 = 0;
    bit lwh2f_f5 = 0;
    bit lwh2f_f6 = 0;

    string lwh2f_messageQueue[$];
    task automatic lwh2f_storeMessage(input string msg);
        string formattedMsg = $sformatf("[%0t] %s", $time, msg);
        lwh2f_messageQueue.push_back(formattedMsg);
    endtask

    // F2SDRAM
    string f2sdram_messageQueue[$];
    task automatic f2sdram_storeMessage(input string msg);
        string formattedMsg = $sformatf("[%0t] %s", $time, msg);
        f2sdram_messageQueue.push_back(formattedMsg);
    endtask

    // F2H
    string f2h_messageQueue[$];
    task automatic f2h_storeMessage(input string msg);
        string formattedMsg = $sformatf("[%0t] %s", $time, msg);
        f2h_messageQueue.push_back(formattedMsg);
    endtask
    //==================================================================================================
    // DUT
    //==================================================================================================
    baseline_a520 dut (
        // Switches and LEDs
        .fpga_user_leds        (fpga_led_pio),
        .fpga_user_switches    (fpga_dipsw_pio),
        .fpga_user_push_buttons(fpga_button_pio),

        // Memory Subsystem
        .emif_ddr5_0_mem_ch0_mem_cs_n       (),
        .emif_ddr5_0_mem_ch0_mem_ca         (),
        .emif_ddr5_0_mem_ch0_mem_dq         (),
        .emif_ddr5_0_mem_ch0_mem_dqs_t      (),
        .emif_ddr5_0_mem_ch0_mem_dqs_c      (),
        .emif_ddr5_0_mem_ch0_mem_alert_n    (1'b1),
        .emif_ddr5_0_mem_ck_ch0_mem_ck_t    (),
        .emif_ddr5_0_mem_ck_ch0_mem_ck_c    (),
        .emif_ddr5_0_mem_reset_n_mem_reset_n(),
        .emif_ddr5_0_mem_ref_clk_clk        (1'b0),

        // HPS IO60 Peripherals
        .hps_io_spim0_spim0_ss1_n            (1'b1),
        .hps_io_spim0_spim0_clk              (1'b0),
        .hps_io_spim0_spim0_mosi             (1'b0),
        .hps_io_spim0_spim0_miso             (),
        .hps_io_spim0_spim0_ss0_n            (1'b1),
        .hps_io_ospi_ospi_data0              (),
        .hps_io_ospi_ospi_data1              (),
        .hps_io_ospi_ospi_clk                (1'b0),
        .hps_io_ospi_ospi_write_protect      (1'b0),
        .hps_io_ospi_ospi_data2              (),
        .hps_io_ospi_ospi_data3              (),
        .hps_io_ospi_ospi_cs_n               (1'b1),
        .hps_io_ospi_ospi_data4              (),
        .hps_io_ospi_ospi_data5              (),
        .hps_io_ospi_ospi_data6              (),
        .hps_io_ospi_ospi_data7              (),
        .hps_io_ospi_ospi_cs1_n              (1'b1),
        .hps_io_ospi_ospi_reset1_n           (1'b1),
        .hps_io_ospi_ospi_reset_n            (1'b1),
        .hps_io_ospi_ospi_data_strobe        (),
        .hps_io_uart0_uart0_cts_n            (),
        .hps_io_uart0_uart0_rts_n            (1'b1),
        .hps_io_uart0_uart0_tx               (1'b1),
        .hps_io_uart0_uart0_rx               (),
        .hps_io_sdemmc0_sdemmc0_data0        (),
        .hps_io_sdemmc0_sdemmc0_data1        (),
        .hps_io_sdemmc0_sdemmc0_clk          (1'b0),
        .hps_io_sdemmc0_sdemmc0_write_protect(),
        .hps_io_sdemmc0_sdemmc0_data2        (),
        .hps_io_sdemmc0_sdemmc0_data3        (),
        .hps_io_sdemmc0_sdemmc0_cmd          (),
        .hps_io_sdemmc0_sdemmc0_data4        (),
        .hps_io_sdemmc0_sdemmc0_data5        (),
        .hps_io_sdemmc0_sdemmc0_data6        (),
        .hps_io_sdemmc0_sdemmc0_data7        (),
        .hps_io_sdemmc0_sdemmc0_pu_pd_data2  (1'b0),
        .hps_io_sdemmc0_sdemmc0_pwr_ena      (1'b0),
        .hps_io_sdemmc0_sdemmc0_data_strobe  (),
        .hps_io_sdemmc0_sdemmc0_card_detect  (),
        .hps_io_i2c0_i2c0_smbalert_n         (),
        .hps_io_i2c0_i2c0_sda                (),
        .hps_io_i2c0_i2c0_scl                (),
        .hps_io_i3c0_i3c0_sda                (),
        .hps_io_i3c0_i3c0_scl                (),
        .hps_io_i3c0_i3c0_sda_pullup_en      (1'b0),
        .hps_io_usb31phy_usb31phy_vbus_ctrl  (1'b0),
        .hps_io_usb31phy_usb31phy_usb31_id   (),
        .hps_io_usb31phy_usb31phy_vbus_det   (),
        .hps_io_usb31phy_usb31phy_over_curr  (),
        .hps_io_usb31phy_usb31phy_usb2_rst_n (1'b1),
        .hps_io_i2c1_i2c1_smbalert_n         (),
        .hps_io_i2c1_i2c1_sda                (),
        .hps_io_i2c1_i2c1_scl                (),

        // HPS fabric peripherals
        .usb_pipe3_phy_ref_pad_clk_m   (1'b0),
        .usb_pipe3_phy_ref_pad_clk_p   (1'b0),
        .usb_pipe3_phy_resref_bidir_in (1'b0),
        .usb_pipe3_phy_rx_m            (1'b0),
        .usb_pipe3_phy_rx_p            (1'b0),
        .usb_pipe3_phy_resref_bidir_out(),
        .usb_pipe3_phy_tx_m            (),
        .usb_pipe3_phy_tx_p            (),

        .emac_ptp_ref_clk_clk      (1'b0),
        .emac1_mdio_gmii_mdi       (1'b0),
        .emac1_mdio_gmii_mdc       (),
        .emac1_mdio_gmii_mdo_e     (),
        .emac1_mdio_gmii_mdo       (),
        .emac1_phy_col             (1'b0),
        .emac1_phy_crs             (1'b0),
        .emac1_phy_rxd             (8'b0),
        .emac1_phy_rxdv            (1'b0),
        .emac1_phy_rxer            (1'b0),
        .emac1_phy_mac_speed       (),
        .emac1_phy_txd_gmii        (),
        .emac1_phy_txd             (),
        .emac1_phy_txen            (),
        .emac1_phy_txer            (),
        .emac1_rst_clk_app_n_reset (),
        .emac1_rst_clk_rx_n_o_reset(),
        .emac1_rst_clk_tx_n_o_reset(),
        .emac1_phy_rxclk_clk       (1'b0),
        .emac1_phy_txclk_i_clk     (1'b0),
        .emac1_phy_txclk_o_clk     (),

        .i3c1_f2h_sda      (1'b1),
        .i3c1_h2f_sda      (),
        .i3c1_scl_oe       (),
        .i3c1_scl_pullup_en(),
        .i3c1_sda_oe       (),
        .i3c1_sda_pullup_en(),
        .i3c1_scl_in_clk   (1'b0),
        .i3c1_scl_out_clk  (),

        // SDM IO
        .sdmio_1_jtag_tdo_out          (),
        .sdmio_2_jtag_tck_in           (1'b0),
        .sdmio_3_jtag_tdi_in           (1'b0),
        .sdmio_4_jtag_tms_in           (1'b0),
        .sdmio_5_cfg_nconfig_in        (1'b1),
        .sdmio_6_ref_refclk_in         (1'b0),
        .sdmio_9_pm_i2c_sda_in         (1'b0),
        .sdmio_9_pm_i2c_sda_oe         (1'b0),
        .sdmio_9_pm_i2c_sda_out        (),
        .sdmio_10_pm_i2c_scl_in        (1'b0),
        .sdmio_10_pm_i2c_scl_oe        (1'b0),
        .sdmio_10_pm_i2c_scl_out       (),
        .sdmio_11_ospi_clk_out         (),
        .sdmio_12_ospi_data0_in        (1'b0),
        .sdmio_12_ospi_data0_oe        (1'b0),
        .sdmio_12_ospi_data0_out       (),
        .sdmio_13_ospi_data1_in        (1'b0),
        .sdmio_13_ospi_data1_oe        (1'b0),
        .sdmio_13_ospi_data1_out       (),
        .sdmio_14_ospi_data2_in        (1'b0),
        .sdmio_14_ospi_data2_oe        (1'b0),
        .sdmio_14_ospi_data2_out       (),
        .sdmio_15_ospi_data3_in        (1'b0),
        .sdmio_15_ospi_data3_oe        (1'b0),
        .sdmio_15_ospi_data3_out       (),
        .sdmio_16_ospi_data4_in        (1'b0),
        .sdmio_16_ospi_data4_oe        (1'b0),
        .sdmio_16_ospi_data4_out       (),
        .sdmio_17_ospi_data_stb_in     (1'b0),
        .sdmio_17_ospi_data_stb_oe     (1'b0),
        .sdmio_17_ospi_data_stb_out    (),
        .sdmio_18_ospi_data5_in        (1'b0),
        .sdmio_18_ospi_data5_oe        (1'b0),
        .sdmio_18_ospi_data5_out       (),
        .sdmio_19_ospi_data6_in        (1'b0),
        .sdmio_19_ospi_data6_oe        (1'b0),
        .sdmio_19_ospi_data6_out       (),
        .sdmio_20_ospi_data7_in        (1'b0),
        .sdmio_20_ospi_data7_oe        (1'b0),
        .sdmio_20_ospi_data7_out       (),
        .sdmio_21_ospi_rst_n_out       (),
        .sdmio_22_ospi_cs0_n_out       (),
        .sdmio_23_i3c_scl_in           (1'b0),
        .sdmio_24_i3c_sda_in           (1'b0),
        .sdmio_24_i3c_sda_oe           (1'b0),
        .sdmio_24_i3c_sda_out          (),
        .sdmio_33_dfx_dig_viewpin_0_in (1'b0),
        .sdmio_33_dfx_dig_viewpin_0_oe (1'b0),
        .sdmio_33_dfx_dig_viewpin_0_out(),
        .sdmio_34_dfx_dig_viewpin_1_in (1'b0),
        .sdmio_34_dfx_dig_viewpin_1_oe (1'b0),
        .sdmio_34_dfx_dig_viewpin_1_out(),

        // External FPGA Reset
        .fpga_reset_n(fpga_reset_n)
    );

    // Generated NoC clocks + synchronised resets for the H2F / LWH2F BFMs.
    bridges_clk_rst u_clk_rst ();
    // TB-owned H2F / LWH2F BFMs (suppresses model-generated BFMs + self-tests).
    hps_bridges_bfms u_bfms ();

    //==================================================================================================
    // clk and reset
    //==================================================================================================
    // DUT fpga_clk_100 (looped from o_osc_100mhz_clk_clk inside baseline_a520)
    assign fpga_clk_100_clk = dut.u_baseline_top.fpga_clk_100_clk;
    //==================================================================================================
    // HPS2FPGA AXI4 Object handles.
    //==================================================================================================
    AlteraAxiTransaction h2f_wr_tr, h2f_rd_tr;

    //---------------------------------------------------------
    // LWHPS2FPGA AXI4 Object handles.
    //---------------------------------------------------------
    AlteraAxiTransaction lwh2f_wr_tr, lwh2f_rd_tr;

    // Enable BFM debug mode
    //assign `h2f_bfm_m.dbg = 1;
    //assign `lwh2f_bfm_m.dbg = 1;


    // Print initialization of the BFMs
    initial begin
        `h2f_bfm_m.AXI4MAN.bfm.hello();
        `lwh2f_bfm_m.AXI4LITEMAN.bfm.hello();
    end

    // Check if the nios_mem.hex file exists, and error out if it doesn't.
    initial begin
        if ($fopen("nios_mem.hex", "r") == 0) begin
            $fatal(
                1,
                "Missing nios_mem.hex in simulation working directory. Generate/copy it before running simulation.");
        end
    end

    //==================================================================================================
    // Testbench tasks
    //==================================================================================================
    task wait_for_nios_done();
        //print(VERBOSITY_INFO, "Waiting for Nios Done");
        fork : wait_watched
            begin
                while (dut.nios_done != 1'b1) begin
                    @fpga_clk_100_clk;
                end
            end
            begin
                #100ms;
                //print(VERBOSITY_FAILURE, "Nios Done not received");
                $fatal;
            end
        join_any
        disable wait_watched;
        //print(VERBOSITY_INFO, "Nios Done received");
    endtask

    task wait_for_nios_start();
        //print(VERBOSITY_INFO, "Waiting for Nios Start");
        fork : wait_watched
            begin
                while (dut.nios_start != 1'b1) begin
                    @fpga_clk_100_clk;
                end
            end
            begin
                #10ms;
                //print(VERBOSITY_FAILURE, "Nios Start not received");
                $fatal;
            end
        join_any
        disable wait_watched;
        //print(VERBOSITY_INFO, "Nios Start received");
    endtask

    //==================================================================================================
    // Simulation Main
    //==================================================================================================

    // Crete a simulation watchdog to avoid infinite simulation runs
    initial begin
        #40000000ns;
        $display("Test Timeout...");
        $display("Baseline Simulation Test Failed!");
        $fatal;
    end

    // Reset sequence
    initial begin
        $display("Assert Reset");
        fpga_reset_n = 1'b0;

        // Hold reset for 10 clock cycles
        repeat (10) @(posedge fpga_clk_100_clk);

        $display("De-assert Reset");
        fpga_reset_n = 1'b1;
        #10ns;

        $display("Waiting for Reset to de-assert");
        fork : wait_reset
            begin
                #1000000ns;
                if (!reset_done) $fatal("INIT_DONE not asserted");
            end
        join_none

        $display("waiting for bfm reset.");
        fork
            begin
                while (dut.sys_clk_100_reset_n != 1'b1) begin
                    @fpga_clk_100_clk;
                end
            end
            `h2f_bfm_m.AXI4MAN.bfm.m_reset();
            `lwh2f_bfm_m.AXI4LITEMAN.bfm.m_reset();
        join

        $display("collect response");
        `h2f_bfm_m.AXI4MAN.bfm.do_collect_responses();
        `lwh2f_bfm_m.AXI4LITEMAN.bfm.do_collect_responses();

        reset_done = 1;
        $display("Reset done Time = %0t", $time);

        // Post reset cycles
        repeat (10) @(posedge fpga_clk_100_clk);

        // Begin HPS to FPGA Bridge Test. No F2SDRAM subordinate BFM to arm
        // (NoC+EMIF model responds), so Nios can be enabled after reset.
        force dut.nios_enable = 1'b1;

        fork : bridge_test

            begin
                // Odd transfers = full 256b (32B); even transfers = narrow 128b (16B).
                // #1 full single, #2 narrow single, #3 full burst, #4 narrow burst.
                // Strobes are never set from the test: set_write_strobes() would
                // override the byte-lane-shifted wstrb the BFM derives for narrow beats.
                automatic
                logic [255:0]
                h2f_wr1_data = {2{128'haaaaaaaa_11111111_a1a1a1a1_0a100a10}};
                automatic logic [127:0] h2f_wr2_data = 128'hbbbbbbbb_22222222_b2b2b2b2_0b200b20;
                automatic logic [255:0] h2f_burst0 = {8{32'hfab0fab1}};
                automatic logic [255:0] h2f_burst1 = {8{32'hfab2fab3}};
                automatic logic [255:0] h2f_burst2 = {8{32'hfab4fab5}};
                automatic logic [255:0] h2f_burst3 = {8{32'hfab6fab7}};
                automatic logic [127:0] h2f_nburst0 = {4{32'hfab0fab1}};
                automatic logic [127:0] h2f_nburst1 = {4{32'hfab2fab3}};
                automatic logic [127:0] h2f_nburst2 = {4{32'hfab4fab5}};
                automatic logic [127:0] h2f_nburst3 = {4{32'hfab6fab7}};

                // Sync this thread to the BFM clock
                repeat (5) @(`h2f_bfm_m.m_cb);
                `h2f_bfm_m.AXI4MAN.bfm.set_config(AXI_CONFIG_MAX_HANDSHAKE_TIMEOUT, 1000);

                h2f_storeMessage("*******************************************************");
                h2f_storeMessage("**************** Test HPS2FPGA Bridge *****************");
                h2f_storeMessage("*******************************************************");
                h2f_storeMessage("[TESTINFO]: Odd xfers=full(32B), even xfers=narrow(16B)");
                h2f_storeMessage("[TESTINFO]: Test Sequence for Write Started");

                // ---- Transfer #1 (odd): FULL single write ----
                h2f_storeMessage(
                    "*************** START OF First Write TEST (FULL) ***************\n");
                h2f_storeMessage(
                    "HPS2FPGA Write #1 FULL - 256b tiled 128'haaaaaaaa_11111111_a1a1a1a1_0a100a10 at OCRAM_BASE_ADDR");
                $display("\n@%0t, ************ HPS2FPGA - START OF WRITE TEST **********\n", $time);

                // manager_bfm_wr_tx(<id>, <addr>, <data>, <burst_len>, <burst_size>,
                //                   <burst_type>, <awvalid>, <wvalid>, <bready>, <wlast>);
                h2f_wr_tr = `h2f_bfm_m.AXI4MAN.bfm.manager_bfm_wr_tx(1, H2F_OCRAM_BASE_ADDR);
                h2f_wr_tr.set_burst_length(0);
                h2f_wr_tr.set_size(AXI4_BYTES_32);
                h2f_wr_tr.set_burst_type(BURST_TYPE_FIXED);
                h2f_wr_tr.set_data_words(h2f_wr1_data, 0);
                `h2f_bfm_m.AXI4MAN.bfm.put_transaction(h2f_wr_tr);
                `h2f_bfm_m.AXI4MAN.bfm.drive_transaction();
                h2f_storeMessage("*************** END OF First Write TEST ***************\n");

                // ---- Transfer #2 (even): NARROW single write ----
                // set_size() must be called after construction: manager_bfm_wr_tx()
                // overrides its burst_size argument with the full bus width.
                h2f_storeMessage("[TESTINFO]: Test for Second Write Started");
                h2f_storeMessage(
                    "*************** START OF SECOND Write TEST (NARROW) ***************\n");
                h2f_storeMessage(
                    "HPS2FPGA Write #2 NARROW 16B - 128'hbbbbbbbb_22222222_b2b2b2b2_0b200b20 at OCRAM_BASE_ADDR + 64");

                // manager_bfm_wr_tx(<id>, <addr>, <data>, <burst_len>, <burst_size>,
                //                   <burst_type>, <awvalid>, <wvalid>, <bready>, <wlast>);
                h2f_wr_tr = `h2f_bfm_m.AXI4MAN.bfm.manager_bfm_wr_tx(2, H2F_OCRAM_BASE_ADDR + 64);
                h2f_wr_tr.set_burst_length(0);
                h2f_wr_tr.set_size(AXI4_BYTES_16);
                h2f_wr_tr.set_burst_type(BURST_TYPE_FIXED);
                h2f_wr_tr.set_data_words(h2f_wr2_data, 0);
                `h2f_bfm_m.AXI4MAN.bfm.put_transaction(h2f_wr_tr);
                `h2f_bfm_m.AXI4MAN.bfm.drive_transaction();
                h2f_storeMessage("*************** END OF Second Write TEST ***************\n");

                h2f_storeMessage("[TESTINFO]: Test Sequence for Read Started");
                h2f_storeMessage(
                    "*************** START OF FIRST Read TEST (FULL) ***************\n");
                $display("\n@%0t, ************ HPS2FPGA - START OF READ TEST **********\n", $time);

                // manager_bfm_rd_tx(<id>, <addr>, <burst_len>, <burst_size>,
                //                   <burst_type>, <arvalid>, <rready>);
                h2f_rd_tr = `h2f_bfm_m.AXI4MAN.bfm.manager_bfm_rd_tx(1, H2F_OCRAM_BASE_ADDR);
                h2f_rd_tr.set_size(AXI4_BYTES_32);
                `h2f_bfm_m.AXI4MAN.bfm.put_transaction(h2f_rd_tr);
                `h2f_bfm_m.AXI4MAN.bfm.drive_transaction();
                if (h2f_rd_tr.get_data_words(0) == h2f_wr1_data) begin
                    h2f_f1 = 1'b1;
                    h2f_storeMessage($sformatf("value of h2f_f1 is %b", h2f_f1));
                    h2f_storeMessage(
                        "manager sanity test: Read correct FULL 256b data at address (0)");
                end else begin
                    h2f_storeMessage($sformatf(
                                     "manager sanity test: Error: Expected FULL 256b data at address 0, but got %h",
                                     h2f_rd_tr.get_data_words(
                                         0
                                     )
                                     ));
                end
                h2f_storeMessage("*************** END OF First Read TEST ***************\n");

                h2f_storeMessage(
                    "*************** START OF SECOND Read TEST (NARROW) ***************\n");

                // manager_bfm_rd_tx(<id>, <addr>, <burst_len>, <burst_size>,
                //                   <burst_type>, <arvalid>, <rready>);
                h2f_rd_tr = `h2f_bfm_m.AXI4MAN.bfm.manager_bfm_rd_tx(2, H2F_OCRAM_BASE_ADDR + 64);
                h2f_rd_tr.set_size(AXI4_BYTES_16);
                `h2f_bfm_m.AXI4MAN.bfm.put_transaction(h2f_rd_tr);
                `h2f_bfm_m.AXI4MAN.bfm.drive_transaction();
                if (h2f_narrow_match(
                        h2f_rd_tr.get_data_words(0), h2f_wr2_data, H2F_OCRAM_BASE_ADDR + 64
                    )) begin
                    h2f_f2 = 1'b1;
                    h2f_storeMessage($sformatf("value of h2f_f2 is %b", h2f_f2));
                    h2f_storeMessage(
                        "manager sanity test: Read correct NARROW 16B data at address (64)");
                end else begin
                    h2f_storeMessage($sformatf(
                                     "manager sanity test: Error: Expected NARROW 16B data at address 64, but got %h",
                                     h2f_rd_tr.get_data_words(
                                         0
                                     )
                                     ));
                end
                h2f_storeMessage("*************** END OF Second Read TEST ***************\n");

                // ---- Transfer #3 (odd): FULL burst ----
                h2f_storeMessage("[TESTINFO]: Test Sequence for FULL Burst Transaction Started");
                $display("\n@%0t, **** HPS2FPGA - START OF FULL Burst Transaction TEST ****\n",
                         $time);

                // burst_len must be the constructor arg: that sizes
                // tr.received_wstrb. set_burst_length() does not.
                // manager_bfm_wr_tx(<id>, <addr>, <data>, <burst_len>, <burst_size>,
                //                   <burst_type>, <awvalid>, <wvalid>, <bready>, <wlast>);
                h2f_wr_tr =
                    `h2f_bfm_m.AXI4MAN.bfm.manager_bfm_wr_tx(4, H2F_OCRAM_BASE_ADDR + 128, 0, 3);
                h2f_wr_tr.set_size(AXI4_BYTES_32);
                h2f_wr_tr.set_burst_type(BURST_TYPE_INCR);
                h2f_wr_tr.set_data_words(h2f_burst0, 0);
                h2f_wr_tr.set_data_words(h2f_burst1, 1);
                h2f_wr_tr.set_data_words(h2f_burst2, 2);
                h2f_wr_tr.set_data_words(h2f_burst3, 3);
                `h2f_bfm_m.AXI4MAN.bfm.put_transaction(h2f_wr_tr);
                `h2f_bfm_m.AXI4MAN.bfm.drive_transaction();

                // manager_bfm_rd_tx(<id>, <addr>, <burst_len>, <burst_size>,
                //                   <burst_type>, <arvalid>, <rready>);
                h2f_rd_tr =
                    `h2f_bfm_m.AXI4MAN.bfm.manager_bfm_rd_tx(4, H2F_OCRAM_BASE_ADDR + 128, 3);
                h2f_rd_tr.set_size(AXI4_BYTES_32);
                h2f_rd_tr.set_burst_type(BURST_TYPE_INCR);
                `h2f_bfm_m.AXI4MAN.bfm.put_transaction(h2f_rd_tr);
                `h2f_bfm_m.AXI4MAN.bfm.drive_transaction();

                if (h2f_rd_tr.get_data_words(0) == h2f_burst0) begin
                    h2f_f3 = 1'b1;
                    h2f_storeMessage(
                        "master_test_program: FULL burst beat0 OK (tiled hfab0fab1) at +128");
                end else begin
                    h2f_storeMessage($sformatf(
                                     "master_test_program: Error FULL burst beat0 at +128, got %h",
                                     h2f_rd_tr.get_data_words(
                                         0
                                     )
                                     ));
                end

                if (h2f_rd_tr.get_data_words(1) == h2f_burst1) begin
                    h2f_f4 = 1'b1;
                    h2f_storeMessage(
                        "master_test_program: FULL burst beat1 OK (tiled hfab2fab3) at +160");
                end else begin
                    h2f_storeMessage($sformatf(
                                     "master_test_program: Error FULL burst beat1 at +160, got %h",
                                     h2f_rd_tr.get_data_words(
                                         1
                                     )
                                     ));
                end

                if (h2f_rd_tr.get_data_words(2) == h2f_burst2) begin
                    h2f_f5 = 1'b1;
                    h2f_storeMessage(
                        "master_test_program: FULL burst beat2 OK (tiled hfab4fab5) at +192");
                end else begin
                    h2f_storeMessage($sformatf(
                                     "master_test_program: Error FULL burst beat2 at +192, got %h",
                                     h2f_rd_tr.get_data_words(
                                         2
                                     )
                                     ));
                end

                if (h2f_rd_tr.get_data_words(3) == h2f_burst3) begin
                    h2f_f6 = 1'b1;
                    h2f_storeMessage(
                        "master_test_program: FULL burst beat3 OK (tiled hfab6fab7) at +224");
                end else begin
                    h2f_storeMessage($sformatf(
                                     "master_test_program: Error FULL burst beat3 at +224, got %h",
                                     h2f_rd_tr.get_data_words(
                                         3
                                     )
                                     ));
                end

                // ---- Transfer #4 (even): NARROW burst ----
                // AxSIZE is fixed for a burst, so narrow is a separate transaction.
                // Beats step 16B, so successive beats alternate between the low and
                // high 16B lane of the 32B bus. Leave wstrb unset so the BFM drives
                // the lane-shifted strobe, and compare only the addressed lane.
                h2f_storeMessage("[TESTINFO]: Test Sequence for NARROW Burst Transaction Started");
                $display("\n@%0t, **** HPS2FPGA - START OF NARROW Burst Transaction TEST ****\n",
                         $time);

                // manager_bfm_wr_tx(<id>, <addr>, <data>, <burst_len>, <burst_size>,
                //                   <burst_type>, <awvalid>, <wvalid>, <bready>, <wlast>);
                h2f_wr_tr =
                    `h2f_bfm_m.AXI4MAN.bfm.manager_bfm_wr_tx(5, H2F_OCRAM_BASE_ADDR + 384, 0, 3);
                h2f_wr_tr.set_size(AXI4_BYTES_16);
                h2f_wr_tr.set_burst_type(BURST_TYPE_INCR);
                h2f_wr_tr.set_data_words(h2f_nburst0, 0);
                h2f_wr_tr.set_data_words(h2f_nburst1, 1);
                h2f_wr_tr.set_data_words(h2f_nburst2, 2);
                h2f_wr_tr.set_data_words(h2f_nburst3, 3);
                `h2f_bfm_m.AXI4MAN.bfm.put_transaction(h2f_wr_tr);
                `h2f_bfm_m.AXI4MAN.bfm.drive_transaction();

                // manager_bfm_rd_tx(<id>, <addr>, <burst_len>, <burst_size>,
                //                   <burst_type>, <arvalid>, <rready>);
                h2f_rd_tr =
                    `h2f_bfm_m.AXI4MAN.bfm.manager_bfm_rd_tx(5, H2F_OCRAM_BASE_ADDR + 384, 3);
                h2f_rd_tr.set_size(AXI4_BYTES_16);
                h2f_rd_tr.set_burst_type(BURST_TYPE_INCR);
                `h2f_bfm_m.AXI4MAN.bfm.put_transaction(h2f_rd_tr);
                `h2f_bfm_m.AXI4MAN.bfm.drive_transaction();

                if (h2f_narrow_match(
                        h2f_rd_tr.get_data_words(0), h2f_nburst0, H2F_OCRAM_BASE_ADDR + 384
                    )) begin
                    h2f_f7 = 1'b1;
                    h2f_storeMessage(
                        "master_test_program: NARROW burst beat0 OK (hfab0fab1 x4) at +384");
                end else begin
                    h2f_storeMessage($sformatf(
                                     "master_test_program: Error NARROW burst beat0 at +384, got %h",
                                     h2f_rd_tr.get_data_words(
                                         0
                                     )
                                     ));
                end

                if (h2f_narrow_match(
                        h2f_rd_tr.get_data_words(1), h2f_nburst1, H2F_OCRAM_BASE_ADDR + 400
                    )) begin
                    h2f_f8 = 1'b1;
                    h2f_storeMessage(
                        "master_test_program: NARROW burst beat1 OK (hfab2fab3 x4) at +400");
                end else begin
                    h2f_storeMessage($sformatf(
                                     "master_test_program: Error NARROW burst beat1 at +400, got %h",
                                     h2f_rd_tr.get_data_words(
                                         1
                                     )
                                     ));
                end

                if (h2f_narrow_match(
                        h2f_rd_tr.get_data_words(2), h2f_nburst2, H2F_OCRAM_BASE_ADDR + 416
                    )) begin
                    h2f_f9 = 1'b1;
                    h2f_storeMessage(
                        "master_test_program: NARROW burst beat2 OK (hfab4fab5 x4) at +416");
                end else begin
                    h2f_storeMessage($sformatf(
                                     "master_test_program: Error NARROW burst beat2 at +416, got %h",
                                     h2f_rd_tr.get_data_words(
                                         2
                                     )
                                     ));
                end

                if (h2f_narrow_match(
                        h2f_rd_tr.get_data_words(3), h2f_nburst3, H2F_OCRAM_BASE_ADDR + 432
                    )) begin
                    h2f_f10 = 1'b1;
                    h2f_storeMessage(
                        "master_test_program: NARROW burst beat3 OK (hfab6fab7 x4) at +432");
                end else begin
                    h2f_storeMessage($sformatf(
                                     "master_test_program: Error NARROW burst beat3 at +432, got %h",
                                     h2f_rd_tr.get_data_words(
                                         3
                                     )
                                     ));
                end

                if (h2f_f1 && h2f_f2 && h2f_f3 && h2f_f4 && h2f_f5 && h2f_f6 && h2f_f7 && h2f_f8 &&
                    h2f_f9 && h2f_f10) begin
                    h2f_storeMessage("HPS2FPGA Test Pass!\n");
                    h2f_pass = 1;
                end else begin
                    h2f_storeMessage("HPS2FPGA Test Fail!\n");
                    h2f_pass = 0;
                end
            end

            begin
                // Sync this thread to the BFM clock
                repeat (5) @(`lwh2f_bfm_m.m_cb);
                // Fail fast naming the stalled handshake rather than running to the watchdog.
                `lwh2f_bfm_m.AXI4LITEMAN.bfm.set_config(AXI_CONFIG_MAX_HANDSHAKE_TIMEOUT, 1000);
                //@(`lwh2f_bfm_m.m_cb);

                lwh2f_storeMessage("*******************************************************");
                lwh2f_storeMessage("*************** Test LWHPS2FPGA Bridge *****************");
                lwh2f_storeMessage("*******************************************************");
                lwh2f_storeMessage("[TESTINFO]: Test Sequence for Write Started");

                lwh2f_storeMessage("*************** START OF First Write TEST ***************\n");
                lwh2f_storeMessage(
                    "LWHPS2FPGA Write #1 - Write data (32'habcdef12) at LWH2F_LED_PIO_ADDR");
                $display("\n@%0t, ************ LWHPS2FPGA - START OF WRITE TEST **********\n",
                         $time);

                lwh2f_wr_tr = `lwh2f_bfm_m.AXI4LITEMAN.bfm.manager_bfm_wr_tx(2, LWH2F_LED_PIO_ADDR);
                lwh2f_wr_tr.set_size(AXI4_BYTES_4);
                lwh2f_wr_tr.set_burst_length(0);
                lwh2f_wr_tr.set_burst_type(BURST_TYPE_FIXED);
                lwh2f_wr_tr.set_data_words(32'habcdef12, 0);
                lwh2f_wr_tr.set_write_strobes(4'hf, 0);
                `lwh2f_bfm_m.AXI4LITEMAN.bfm.put_transaction(lwh2f_wr_tr);
                `lwh2f_bfm_m.AXI4LITEMAN.bfm.drive_transaction();
                lwh2f_storeMessage("*************** END OF First Write TEST ***************\n");

                /////////////////////////////////////////////////////////////////////////////////

                lwh2f_storeMessage("[TESTINFO]: Test Sequence for Read Started");

                lwh2f_storeMessage("*************** START OF FIRST Read TEST ***************\n");
                lwh2f_storeMessage("LWHPS2FPGA Read #1 at LWH2F_SYSID_ADDR");
                lwh2f_rd_tr = `lwh2f_bfm_m.AXI4LITEMAN.bfm.manager_bfm_rd_tx(1, LWH2F_SYSID_ADDR);
                lwh2f_rd_tr.set_size(AXI4_BYTES_4);
                lwh2f_rd_tr.set_burst_length(0);
                lwh2f_rd_tr.set_burst_type(BURST_TYPE_FIXED);
                `lwh2f_bfm_m.AXI4LITEMAN.bfm.put_transaction(lwh2f_rd_tr);
                `lwh2f_bfm_m.AXI4LITEMAN.bfm.drive_transaction();
                if (lwh2f_rd_tr.get_data_words(0) == LWH2F_SYSID_VALUE) begin
                    lwh2f_f1 = 1'b1;
                    lwh2f_storeMessage($sformatf("value of lwh2f_f1 is %b", lwh2f_f1));
                    lwh2f_storeMessage($sformatf(
                                       "manager sanity test: Read correct data %h at LWH2F_SYSID_ADDR",
                                       LWH2F_SYSID_VALUE
                                       ));
                end else begin
                    lwh2f_storeMessage($sformatf(
                                       "manager sanity test: Error: Expected data %h at LWH2F_SYSID_ADDR, but got %h",
                                       LWH2F_SYSID_VALUE,
                                       lwh2f_rd_tr.get_data_words(
                                           0
                                       )
                                       ));
                end
                lwh2f_storeMessage("*************** END OF First Read TEST ***************\n");

                ////////////////////////////////////////////////////////////////////////////////

                lwh2f_storeMessage("*************** START OF SECOND Read TEST ***************\n");
                lwh2f_storeMessage("LWHPS2FPGA Read #2 at LWH2F_LED_PIO_ADDR");
                lwh2f_rd_tr = `lwh2f_bfm_m.AXI4LITEMAN.bfm.manager_bfm_rd_tx(2, LWH2F_LED_PIO_ADDR);
                lwh2f_rd_tr.set_size(AXI4_BYTES_4);
                lwh2f_rd_tr.set_burst_length(0);
                lwh2f_rd_tr.set_burst_type(BURST_TYPE_FIXED);
                `lwh2f_bfm_m.AXI4LITEMAN.bfm.put_transaction(lwh2f_rd_tr);
                `lwh2f_bfm_m.AXI4LITEMAN.bfm.drive_transaction();
                if (lwh2f_rd_tr.get_data_words(0) == 32'habcdef12) begin
                    lwh2f_f2 = 1'b1;
                    lwh2f_storeMessage($sformatf("value of lwh2f_f2 is %b", lwh2f_f2));
                    lwh2f_storeMessage(
                        "manager sanity test: Read correct data (32'habcdef12) at LWH2F_LED_PIO_ADDR");
                end else begin
                    lwh2f_storeMessage($sformatf(
                                       "manager sanity test: Error: Expected data (32'habcdef12) at LWH2F_LED_PIO_ADDR, but got %h",
                                       lwh2f_rd_tr.get_data_words(
                                           0
                                       )
                                       ));
                end
                lwh2f_storeMessage("*************** END OF Second Read TEST ***************\n");

                /////////////////////////////////////////////////////////////////////////////////

                if (lwh2f_f1 == 1'b1 && lwh2f_f2 == 1'b1) begin
                    lwh2f_storeMessage("LWH2F Test Pass!");
                    lwh2f_pass = 1;
                end else begin
                    lwh2f_storeMessage("LWH2F Test Fail!");
                    lwh2f_pass = 0;
                end
            end

            begin
                f2sdram_storeMessage("*******************************************************");
                f2sdram_storeMessage("*************** Test F2SDRAM Bridge *****************");
                f2sdram_storeMessage("*******************************************************");

                wait_for_nios_start();
                f2sdram_storeMessage(
                    "[TESTINFO]: F2SDRAM monitor on fabric u_ff_mnoc_init.s_axi4 (no sub_bfm)");

                begin : f2sdram_nios_done_with_monitor
                    f2sdram_txn_count = 0;
                    f2sdram_r_count = 0;
                    fork
                        begin
                            wait_for_nios_done();
                        end
                        begin : f2sdram_traffic_mon
                            while (dut.nios_done !== 1'b1) begin
                                @(posedge fpga_clk_100_clk);
                                if (`f2sdram_mon.s_axi4_awvalid === 1'b1 &&
                                    `f2sdram_mon.s_axi4_awready === 1'b1)
                                    f2sdram_txn_count++;
                                if (`f2sdram_mon.s_axi4_arvalid === 1'b1 &&
                                    `f2sdram_mon.s_axi4_arready === 1'b1)
                                    f2sdram_txn_count++;
                                if (`f2sdram_mon.s_axi4_rvalid === 1'b1 &&
                                    `f2sdram_mon.s_axi4_rready === 1'b1)
                                    f2sdram_r_count++;
                            end
                        end : f2sdram_traffic_mon
                    join
                    if (f2sdram_txn_count == 0)
                        f2sdram_storeMessage("[WARNING]: NiosV F2SDRAM traffic not observed");
                    else
                        f2sdram_storeMessage($sformatf(
                                             "[TESTINFO]: NiosV F2SDRAM traffic observed: %0d transaction(s), %0d read beat(s)",
                                             f2sdram_txn_count,
                                             f2sdram_r_count
                                             ));
                end : f2sdram_nios_done_with_monitor
                repeat (1000) @fpga_clk_100_clk;
                f2sdram_storeMessage("*************** END OF F2SDRAM TEST ***************\n");

                if (dut.nios_f2sdram_pass == 1'b1) begin
                    f2sdram_storeMessage("F2SDRAM Test Pass!");
                    f2sdram_pass = 1;
                end else begin
                    f2sdram_storeMessage("F2SDRAM Test Fail!");
                    f2sdram_pass = 0;
                end
            end

            begin
                f2h_storeMessage("*******************************************************");
                f2h_storeMessage("**************** Test FPGA2HPS Bridge *****************");
                f2h_storeMessage("*******************************************************");
                f2h_storeMessage(
                    "[TESTINFO]: F2H monitor on HPS fpga2hpsmem (f2soc ACE5-Lite; no sub_bfm)");

                wait_for_nios_start();
                f2h_storeMessage("[TESTINFO]: Test Sequence for F2H Started (NiosV manager)");

                begin : f2h_nios_done_with_monitor
                    f2h_txn_count = 0;
                    f2h_r_count = 0;
                    fork
                        begin
                            wait_for_nios_done();
                        end
                        begin : f2h_traffic_mon
                            while (dut.nios_done !== 1'b1) begin
                                @(posedge fpga_clk_100_clk);
                                if (`f2h_mon.fpga2hpsmem_awvalid === 1'b1 &&
                                    `f2h_mon.fpga2hpsmem_awready === 1'b1)
                                    f2h_txn_count++;
                                if (`f2h_mon.fpga2hpsmem_arvalid === 1'b1 &&
                                    `f2h_mon.fpga2hpsmem_arready === 1'b1)
                                    f2h_txn_count++;
                                if (`f2h_mon.fpga2hpsmem_rvalid === 1'b1 &&
                                    `f2h_mon.fpga2hpsmem_rready === 1'b1) begin
                                    f2h_r_count++;
                                    if (f2h_r_count <= 2)
                                        f2h_rd_data[f2h_r_count-1] = `f2h_mon.fpga2hpsmem_rdata;
                                    if (f2h_r_count <= 8)
                                        f2h_storeMessage($sformatf(
                                                         "[READDATA]: F2H [%0d] = 0x%h",
                                                         f2h_r_count,
                                                         `f2h_mon.fpga2hpsmem_rdata
                                                         ));
                                end
                            end
                        end : f2h_traffic_mon
                    join
                    if (f2h_txn_count == 0)
                        f2h_storeMessage("[WARNING]: NiosV F2H traffic not observed");
                    else
                        f2h_storeMessage($sformatf(
                                         "[TESTINFO]: NiosV F2H traffic observed: %0d transaction(s)",
                                         f2h_txn_count
                                         ));
                    if (f2h_r_count == 0)
                        f2h_storeMessage("[WARNING]: No F2H read data beat observed");
                    else
                        f2h_storeMessage(
                            $sformatf("[TESTINFO]: F2H read data beats observed: %0d", f2h_r_count
                            ));
                end : f2h_nios_done_with_monitor
                repeat (1000) @fpga_clk_100_clk;

                if (f2h_r_count >= 1)
                    f2h_storeMessage($sformatf(
                                     "[READDATA]: F2H captured beat [1] = 0x%h", f2h_rd_data[0]));
                if (f2h_r_count >= 2)
                    f2h_storeMessage($sformatf(
                                     "[READDATA]: F2H captured beat [2] = 0x%h", f2h_rd_data[1]));

                f2h_storeMessage("*************** END OF F2H TEST ***************\n");

                if (dut.nios_f2h_pass == 1'b1) begin
                    f2h_storeMessage("FPGA2HPS Test Pass!");
                    f2h_pass = 1;
                end else begin
                    f2h_storeMessage("FPGA2HPS Test Fail!");
                    f2h_pass = 0;
                end
            end
        join

        foreach (h2f_messageQueue[i]) begin
            $display("%s", h2f_messageQueue[i]);
        end
        foreach (lwh2f_messageQueue[i]) begin
            $display("%s", lwh2f_messageQueue[i]);
        end
        foreach (f2sdram_messageQueue[i]) begin
            $display("%s", f2sdram_messageQueue[i]);
        end
        foreach (f2h_messageQueue[i]) begin
            $display("%s", f2h_messageQueue[i]);
        end
        $display("@%0t*********************************************", $time);
        $display("@%0t************** TEST SUMMARY *****************", $time);
        $display("@%0t*********************************************", $time);
        if (h2f_pass) begin
            $display("HPS2FPGA Test -- PASS");
        end else begin
            $display("HPS2FPGA Test -- FAIL");
            test_pass = 0;
        end
        if (lwh2f_pass) begin
            $display("LWHPS2FPGA Test -- PASS");
        end else begin
            $display("LWHPS2FPGA Test -- FAIL");
            test_pass = 0;
        end
        if (f2sdram_pass) begin
            $display("F2SDRAM Test -- PASS");
        end else begin
            $display("F2SDRAM Test -- FAIL");
            test_pass = 0;
        end
        if (f2h_pass) begin
            $display("F2H Test -- PASS");
        end else begin
            $display("F2H Test -- FAIL");
            test_pass = 0;
        end

        if (test_pass == 0) begin
            $fatal("Baseline Simulation Test Failed!");
        end else begin
            $display("\n@%0t**************** END OF TEST ****************\n", $time);
            $display("\n@%0t************ Simulation complete ************\n", $time);
            #0 $finish(1);
        end
    end

    // For VCSMX simulator - uncomment this section to enable VPD waveform dump for debug.
    // Run dve -vpd dump.vpd to view waveforms after simulation completes.
    // initial begin
    //      $vcdplusfile("dump.vpd");
    //      $vcdpluson(0, testbench);
    //     $vcdplusmemon(0, testbench);
    // end


endmodule
