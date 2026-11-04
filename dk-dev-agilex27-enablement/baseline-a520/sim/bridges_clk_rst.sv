`timescale 1 ps / 1 ps
//
`default_nettype none

// Shared simulation clocks and synchronised resets for the TB-owned H2F /
// LWH2F bridge BFMs. hps_bridges_bfms sources .clk / .rstn here.
//
// Must be instantiated under testbench, ahead of the BFM wrapper:
//   testbench dut (...);
//   bridges_clk_rst  u_clk_rst ();
//   hps_bridges_bfms u_bfms ();
//
// Clocks
// ------
// The HPS sim model does not drive its NoC aclk inputs, so the TB generates
// them here and forces them onto the design nets at the bottom of this file.
// Each BFM must run on the same clock as the initiator or target sharing its
// AXI cut, otherwise handshakes never complete.
//
// Resets
// ------
// The BFMs cannot take a reset from the AXI interface they attach to, because
// that interface has none. The soc2noc / lw_soc2noc interfaces exported by the
// HPS sim model carry a clock plus the AXI channels and nothing else.
//
// That leaves the FPGA-side bridge reset outputs of the HPS IP,
// hps2fpga_resetn and lwhps2fpga_resetn.
//
// The bridge resets are released in the fabric clock domain, while the BFMs are
// clocked by the generated clocks above. Driving a reset from one clock domain
// directly into flops clocked by another is safe on assertion but not on
// release, where the deasserting edge can land arbitrarily close to a clock
// edge. So each clock domain gets its own two-flop synchroniser: asserted
// asynchronously, released in step with the clock that BFM actually samples.
//
// "=== 1'b1" instead of a plain tap: the hierarchical net reads X until the DUT
// drives it, and "if (!X)" is not true, so a plain tap would take the else
// branch and release the BFM immediately -- the opposite of the point. Case
// equality reads X and Z as "still in reset".

`define bridges_clk_rst_hps_ip \
    testbench.dut.u_baseline_top.u_shell_subsys.u_agilex27_hps.u_agilex27_hps

module bridges_clk_rst #(
    // Clock periods in ps (`timescale 1 ps / 1 ps). HPS soc_noc runs at 1 GHz.
    // HPS lw_soc_noc is generated with PERIPH_CLK_FREQ_HZ = 500000000, so it
    // runs at 500 MHz.
    parameter int H2F_CLK_PERIOD_PS   = 1000,
    parameter int LWH2F_CLK_PERIOD_PS = 2000
) ();

    bit h2f_clk;
    bit lwh2f_clk;

    initial forever #(H2F_CLK_PERIOD_PS / 2) h2f_clk = ~h2f_clk;
    initial forever #(LWH2F_CLK_PERIOD_PS / 2) lwh2f_clk = ~lwh2f_clk;

    // Each synchroniser starts from the bridge reset named after the HPS
    // interface its traffic reaches. Both bridge resets are driven from the same
    // system reset in this design, so the sources are the same signal today;
    // keeping them apart means the code stays right if that ever changes.
    wire h2f_src_rstn = (`bridges_clk_rst_hps_ip.hps2fpga_resetn_reset_n === 1'b1);
    wire lwh2f_src_rstn = (`bridges_clk_rst_hps_ip.lwhps2fpga_resetn_reset_n === 1'b1);

    // Start asserted. A source that is already low at time 0 never produces a
    // negedge, so without the initial value the synchroniser would hold X for
    // the whole run and the BFM would never see a clean reset.
    logic [1:0] h2f_rstn_sync = 2'b00;
    logic [1:0] lwh2f_rstn_sync = 2'b00;

    always @(posedge h2f_clk or negedge h2f_src_rstn) begin
        if (!h2f_src_rstn) h2f_rstn_sync <= 2'b00;
        else h2f_rstn_sync <= {h2f_rstn_sync[0], 1'b1};
    end

    always @(posedge lwh2f_clk or negedge lwh2f_src_rstn) begin
        if (!lwh2f_src_rstn) lwh2f_rstn_sync <= 2'b00;
        else lwh2f_rstn_sync <= {lwh2f_rstn_sync[0], 1'b1};
    end

    wire h2f_rstn = h2f_rstn_sync[1];
    wire lwh2f_rstn = lwh2f_rstn_sync[1];

    // Drive the aclk inputs the sim models leave undriven (needed for WREADY).
    initial begin
        // HPS: hps_mnoc_init / hps_mnoc_tgt / hps_rnoc_init / hps_rnoc_tgt take
        // i_aclk from these wires.
        force `bridges_clk_rst_hps_ip.hps_720_520_component_soc_noc_mnoc_clk_clk = h2f_clk;
        force `bridges_clk_rst_hps_ip.hps_720_520_component_noc_soc_mnoc_clk_clk = h2f_clk;
        force `bridges_clk_rst_hps_ip.hps_720_520_component_lw_soc_noc_clk_clk = lwh2f_clk;
        force `bridges_clk_rst_hps_ip.hps_720_520_component_lw_noc_soc_clk_clk = lwh2f_clk;
    end

endmodule
