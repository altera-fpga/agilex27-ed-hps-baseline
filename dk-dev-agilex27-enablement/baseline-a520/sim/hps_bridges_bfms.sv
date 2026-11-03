`timescale 1 ps / 1 ps
//
`default_nettype none

// Instantiate TB-owned H2F / LWH2F manager BFMs and attach them to the HPS
// sim-model soc_noc / lw_soc_noc shell nets.
//
// Clocks and synchronised resets come from bridges_clk_rst. That module
// also forces the undriven NoC aclk nets.
//
// Must be instantiated under testbench so hierarchical paths resolve:
//   testbench dut (...);
//   bridges_clk_rst  u_clk_rst ();
//   hps_bridges_bfms u_bfms ();

import hps_h2f_pkg::*;
import hps_h2f_lw_pkg::*;

`define hps_bridges_hps_ip \
    testbench.dut.u_baseline_top.u_shell_subsys.u_agilex27_hps.u_agilex27_hps
`define hps_bridges_h2f_shell \
    `hps_bridges_hps_ip.hps_720_520_component.soc_noc_gen.soc_noc_inst.sf_rtl_inst
`define hps_bridges_lwh2f_shell \
    `hps_bridges_hps_ip.hps_720_520_component.lw_soc_noc_gen.lw_soc_noc_inst.sf_rtl_inst
`define hps_bridges_clk_rst testbench.u_clk_rst

module hps_bridges_bfms ();

    // Widths from hps_h2f_pkg / hps_h2f_lw_pkg (soc_noc BFM cut, not FPGA
    // hps2fpga fabric ports). The continuous assignment zero-extends the
    // narrower shell USER/QOS nets to the manager BFM widths. Do not size these
    // with $bits() of the shell nets: VCS rejects $bits() on a hierarchical
    // name (Error-[SV-BXBSF]).
    wire [H2F_USER_WIDTH-1:0] h2f_awuser = `hps_bridges_h2f_shell.soc2noc_awuser_o;
    wire [H2F_USER_WIDTH-1:0] h2f_aruser = `hps_bridges_h2f_shell.soc2noc_aruser_o;
    wire [3:0] h2f_awqos = `hps_bridges_h2f_shell.soc2noc_awqos_o;
    wire [3:0] h2f_arqos = `hps_bridges_h2f_shell.soc2noc_arqos_o;

    altera_axi4_mm_manager #(
        .ADDR_WIDTH  (H2F_ADDR_WIDTH),
        .DATA_WIDTH  (H2F_DATA_WIDTH),
        .ID_WIDTH    (H2F_ID_WIDTH),
        .USER_WIDTH  (H2F_USER_WIDTH),
        .USE_AWID    (1),
        .USE_AWREGION(1),
        .USE_AWLEN   (1),
        .USE_AWSIZE  (1),
        .USE_AWBURST (1),
        .USE_AWLOCK  (1),
        .USE_AWCACHE (1),
        .USE_AWQOS   (1),
        .USE_WSTRB   (1),
        .USE_BID     (1),
        .USE_BRESP   (1),
        .USE_ARID    (1),
        .USE_ARREGION(1),
        .USE_ARLEN   (1),
        .USE_ARSIZE  (1),
        .USE_ARBURST (1),
        .USE_ARLOCK  (1),
        .USE_ARCACHE (1),
        .USE_ARQOS   (1),
        .USE_RID     (1),
        .USE_RRESP   (1),
        .USE_RLAST   (1),
        .USE_AWUSER  (1),
        .USE_ARUSER  (1),
        .USE_WUSER   (1),
        .USE_RUSER   (1),
        .USE_BUSER   (1)
    ) testbench_h2f_bfm (
        .clk     (`hps_bridges_clk_rst.h2f_clk),
        .rstn    (`hps_bridges_clk_rst.h2f_rstn),
        .awid    (`hps_bridges_h2f_shell.soc2noc_awid_o),
        .awaddr  (`hps_bridges_h2f_shell.soc2noc_awaddr_o),
        .awlen   (`hps_bridges_h2f_shell.soc2noc_awlen_o),
        .awsize  (`hps_bridges_h2f_shell.soc2noc_awsize_o),
        .awburst (`hps_bridges_h2f_shell.soc2noc_awburst_o),
        .awlock  (`hps_bridges_h2f_shell.soc2noc_awlock_o),
        .awcache (),
        .awprot  (),
        .awqos   (h2f_awqos),
        .awregion(),
        .awuser  (h2f_awuser),
        .awvalid (`hps_bridges_h2f_shell.soc2noc_awvalid_o),
        .awready (`hps_bridges_h2f_shell.soc2noc_awready_i),
        .wdata   (`hps_bridges_h2f_shell.soc2noc_wdata_o),
        .wstrb   (`hps_bridges_h2f_shell.soc2noc_wstrb_o),
        .wlast   (`hps_bridges_h2f_shell.soc2noc_wlast_o),
        .wuser   (`hps_bridges_h2f_shell.soc2noc_wuser_o),
        .wvalid  (`hps_bridges_h2f_shell.soc2noc_wvalid_o),
        .wready  (`hps_bridges_h2f_shell.soc2noc_wready_i),
        .bid     (`hps_bridges_h2f_shell.soc2noc_bid_i),
        .bresp   (`hps_bridges_h2f_shell.soc2noc_bresp_i),
        .buser   ({H2F_USER_WIDTH{1'b0}}),
        .bvalid  (`hps_bridges_h2f_shell.soc2noc_bvalid_i),
        .bready  (`hps_bridges_h2f_shell.soc2noc_bready_o),
        .arid    (`hps_bridges_h2f_shell.soc2noc_arid_o),
        .araddr  (`hps_bridges_h2f_shell.soc2noc_araddr_o),
        .arlen   (`hps_bridges_h2f_shell.soc2noc_arlen_o),
        .arsize  (`hps_bridges_h2f_shell.soc2noc_arsize_o),
        .arburst (`hps_bridges_h2f_shell.soc2noc_arburst_o),
        .arlock  (`hps_bridges_h2f_shell.soc2noc_arlock_o),
        .arcache (),
        .arprot  (),
        .arqos   (h2f_arqos),
        .arregion(),
        .aruser  (h2f_aruser),
        .arvalid (`hps_bridges_h2f_shell.soc2noc_arvalid_o),
        .arready (`hps_bridges_h2f_shell.soc2noc_arready_i),
        .rid     (`hps_bridges_h2f_shell.soc2noc_rid_i),
        .rdata   (`hps_bridges_h2f_shell.soc2noc_rdata_i),
        .rresp   (`hps_bridges_h2f_shell.soc2noc_rresp_i),
        .rlast   (`hps_bridges_h2f_shell.soc2noc_rlast_i),
        .ruser   (`hps_bridges_h2f_shell.soc2noc_ruser_i),
        .rvalid  (`hps_bridges_h2f_shell.soc2noc_rvalid_i),
        .rready  (`hps_bridges_h2f_shell.soc2noc_rready_o)
    );

    altera_axi4lite_mm_manager #(
        .ADDR_WIDTH(LWH2F_ADDR_WIDTH),
        .DATA_WIDTH(LWH2F_DATA_WIDTH)
    ) testbench_lwh2f_bfm (
        .clk    (`hps_bridges_clk_rst.lwh2f_clk),
        .rstn   (`hps_bridges_clk_rst.lwh2f_rstn),
        .awaddr (`hps_bridges_lwh2f_shell.lw_soc2noc_awaddr_o),
        .awprot (),
        .awvalid(`hps_bridges_lwh2f_shell.lw_soc2noc_awvalid_o),
        .awready(`hps_bridges_lwh2f_shell.lw_soc2noc_awready_i),
        .wdata  (`hps_bridges_lwh2f_shell.lw_soc2noc_wdata_o),
        .wstrb  (`hps_bridges_lwh2f_shell.lw_soc2noc_wstrb_o),
        .wvalid (`hps_bridges_lwh2f_shell.lw_soc2noc_wvalid_o),
        .wready (`hps_bridges_lwh2f_shell.lw_soc2noc_wready_i),
        .bresp  (`hps_bridges_lwh2f_shell.lw_soc2noc_bresp_i),
        .bvalid (`hps_bridges_lwh2f_shell.lw_soc2noc_bvalid_i),
        .bready (`hps_bridges_lwh2f_shell.lw_soc2noc_bready_o),
        .araddr (`hps_bridges_lwh2f_shell.lw_soc2noc_araddr_o),
        .arprot (),
        .arvalid(`hps_bridges_lwh2f_shell.lw_soc2noc_arvalid_o),
        .arready(`hps_bridges_lwh2f_shell.lw_soc2noc_arready_i),
        .rdata  (`hps_bridges_lwh2f_shell.lw_soc2noc_rdata_i),
        .rresp  (`hps_bridges_lwh2f_shell.lw_soc2noc_rresp_i),
        .rvalid (`hps_bridges_lwh2f_shell.lw_soc2noc_rvalid_i),
        .rready (`hps_bridges_lwh2f_shell.lw_soc2noc_rready_o)
    );

endmodule
