// SPDX-License-Identifier: GPL-3.0-or-later
`timescale 1ns/1ps
// Open 1 Gb/s SGMII-over-LVDS PCS/PMA.
//
// Stage 3 provides the complete Clause 22 MDIO master, AXI4-Lite debug and
// management registers, clocking, PHY reset control, programmable RX input
// delay, DDR serial capture/transmit, comma alignment, 8b/10b coding, receive
// synchronization diagnostics, raw 10-bit words, event counters, and a fixed
// 1 Gb/s full-duplex GMII packet path with 1000BASE-X/SGMII ordered sets.
module open_eth_sgmii_pcs_pma #(
    // Selects the matching MMCM and SelectIO simulation models.  The value is
    // exposed as a two-choice parameter in the packaged Vivado IP.
    parameter string FPGA_FAMILY = "ULTRASCALE"
) (
    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 s_axi_aclk CLK" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_aclk, ASSOCIATED_BUSIF s_axi, ASSOCIATED_RESET s_axi_aresetn, FREQ_HZ 150000000" *)
    input  wire        s_axi_aclk,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 s_axi_aresetn RST" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME s_axi_aresetn, POLARITY ACTIVE_LOW" *)
    input  wire        s_axi_aresetn,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWADDR" *) input wire [11:0] s_axi_awaddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWVALID" *) input wire s_axi_awvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi AWREADY" *) output wire s_axi_awready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WDATA" *) input wire [31:0] s_axi_wdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WSTRB" *) input wire [3:0] s_axi_wstrb,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WVALID" *) input wire s_axi_wvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi WREADY" *) output wire s_axi_wready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BRESP" *) output wire [1:0] s_axi_bresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BVALID" *) output reg s_axi_bvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi BREADY" *) input wire s_axi_bready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARADDR" *) input wire [11:0] s_axi_araddr,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARVALID" *) input wire s_axi_arvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi ARREADY" *) output wire s_axi_arready,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RDATA" *) output reg [31:0] s_axi_rdata,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RRESP" *) output wire [1:0] s_axi_rresp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RVALID" *) output reg s_axi_rvalid,
    (* X_INTERFACE_INFO = "xilinx.com:interface:aximm:1.0 s_axi RREADY" *) input wire s_axi_rready,

    (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 refclk625 CLK_P" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME refclk625, ASSOCIATED_BUSIF sgmii, FREQ_HZ 625000000" *)
    input wire refclk625_p,
    (* X_INTERFACE_INFO = "xilinx.com:interface:diff_clock:1.0 refclk625 CLK_N" *) input wire refclk625_n,
    (* X_INTERFACE_INFO = "xilinx.com:interface:sgmii:1.0 sgmii RXP" *) input wire sgmii_rxp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:sgmii:1.0 sgmii RXN" *) input wire sgmii_rxn,
    (* X_INTERFACE_INFO = "xilinx.com:interface:sgmii:1.0 sgmii TXP" *) output wire sgmii_txp,
    (* X_INTERFACE_INFO = "xilinx.com:interface:sgmii:1.0 sgmii TXN" *) output wire sgmii_txn,
    (* X_INTERFACE_INFO = "xilinx.com:interface:mdio:1.0 mdio MDC" *) output wire mdio_mdc,
    (* X_INTERFACE_INFO = "xilinx.com:interface:mdio:1.0 mdio MDIO_I" *) input wire mdio_mdio_i,
    (* X_INTERFACE_INFO = "xilinx.com:interface:mdio:1.0 mdio MDIO_O" *) output wire mdio_mdio_o,
    (* X_INTERFACE_INFO = "xilinx.com:interface:mdio:1.0 mdio MDIO_T" *) output wire mdio_mdio_t,
    (* X_INTERFACE_INFO = "xilinx.com:signal:reset:1.0 phy_reset_n RST" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME phy_reset_n, POLARITY ACTIVE_LOW" *)
    output wire phy_reset_n,

    (* X_INTERFACE_INFO = "xilinx.com:signal:clock:1.0 gmii_clk125 CLK" *)
    (* X_INTERFACE_PARAMETER = "XIL_INTERFACENAME gmii_clk125, ASSOCIATED_BUSIF gmii, FREQ_HZ 125000000" *)
    output wire gmii_clk125,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gmii:1.0 gmii TXD" *) input wire [7:0] gmii_txd,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gmii:1.0 gmii TX_EN" *) input wire gmii_tx_en,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gmii:1.0 gmii TX_ER" *) input wire gmii_tx_er,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gmii:1.0 gmii RXD" *) output reg [7:0] gmii_rxd,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gmii:1.0 gmii RX_DV" *) output reg gmii_rx_dv,
    (* X_INTERFACE_INFO = "xilinx.com:interface:gmii:1.0 gmii RX_ER" *) output reg gmii_rx_er
);

localparam [31:0] CORE_ID = 32'h4f50_4353; // "OPCS"
localparam [31:0] CORE_VERSION = 32'h0001_0003; // ABI 1, stage 3
localparam [31:0] CAPABILITIES = 32'h0000_000f; // MDIO + raw + codec + GMII
localparam [7:0] PCS_K28_5 = 8'hbc;
localparam [7:0] PCS_K23_7 = 8'hf7;
localparam [7:0] PCS_K27_7 = 8'hfb;
localparam [7:0] PCS_K29_7 = 8'hfd;
localparam [7:0] PCS_K30_7 = 8'hfe;
localparam [7:0] PCS_D5_6 = 8'hc5;
localparam [7:0] PCS_D16_2 = 8'h50;

wire refclk625_i;
wire clkfb_mmcm;
wire clkfb;
wire clk625_mmcm;
wire clk125_mmcm;
wire clk625;
wire clk156;
wire clk125;
wire mmcm_locked;
// RX delay uses DELAY_FORMAT=COUNT. UltraScale count mode is intentionally
// uncalibrated and must not use IDELAYCTRL; taps are selected by the hardware
// eye sweep instead. Keep the status ABI bit asserted to mean "delay usable."
wire idelay_ready = 1'b1;
wire clock_sources_ready = mmcm_locked;
wire reset_high = !s_axi_aresetn;

IBUFDS #(.DIFF_TERM("FALSE"), .IBUF_LOW_PWR("FALSE")) refclk_buffer (
    .I(refclk625_p), .IB(refclk625_n), .O(refclk625_i));

generate
if (FPGA_FAMILY == "ULTRASCALE_PLUS") begin : g_ultrascale_plus_mmcm
    MMCME4_ADV #(
        .BANDWIDTH("OPTIMIZED"), .CLKIN1_PERIOD(1.600),
        .DIVCLK_DIVIDE(2), .CLKFBOUT_MULT_F(2.000),
        .CLKOUT0_DIVIDE_F(5.000), .CLKOUT1_DIVIDE(2),
        .CLKOUT2_DIVIDE(1), .CLKOUT3_DIVIDE(1), .COMPENSATION("AUTO"),
        .STARTUP_WAIT("FALSE")) clock_mmcm (
        .CLKIN1(refclk625_i), .CLKIN2(1'b0), .CLKINSEL(1'b1),
        .CLKFBIN(clkfb), .CLKFBOUT(clkfb_mmcm), .CLKFBOUTB(),
        .CLKOUT0(clk125_mmcm), .CLKOUT0B(), .CLKOUT1(),
        .CLKOUT1B(), .CLKOUT2(clk625_mmcm), .CLKOUT2B(),
        .CLKOUT3(), .CLKOUT3B(), .CLKOUT4(), .CLKOUT5(), .CLKOUT6(),
        .LOCKED(mmcm_locked), .CLKINSTOPPED(), .CLKFBSTOPPED(),
        .PWRDWN(1'b0), .RST(reset_high), .DADDR(7'd0), .DCLK(1'b0),
        .DEN(1'b0), .DI(16'd0), .DO(), .DRDY(), .DWE(1'b0),
        .CDDCDONE(), .CDDCREQ(1'b0), .PSCLK(1'b0), .PSEN(1'b0),
        .PSINCDEC(1'b0), .PSDONE());
end else begin : g_ultrascale_mmcm
    MMCME3_ADV #(
        .BANDWIDTH("OPTIMIZED"), .CLKIN1_PERIOD(1.600),
        .DIVCLK_DIVIDE(2), .CLKFBOUT_MULT_F(2.000),
        .CLKOUT0_DIVIDE_F(5.000), .CLKOUT1_DIVIDE(2),
        .CLKOUT2_DIVIDE(1), .CLKOUT3_DIVIDE(1), .COMPENSATION("AUTO"),
        .STARTUP_WAIT("FALSE")) clock_mmcm (
        .CLKIN1(refclk625_i), .CLKIN2(1'b0), .CLKINSEL(1'b1),
        .CLKFBIN(clkfb), .CLKFBOUT(clkfb_mmcm), .CLKFBOUTB(),
        .CLKOUT0(clk125_mmcm), .CLKOUT0B(), .CLKOUT1(),
        .CLKOUT1B(), .CLKOUT2(clk625_mmcm), .CLKOUT2B(),
        .CLKOUT3(), .CLKOUT3B(), .CLKOUT4(), .CLKOUT5(), .CLKOUT6(),
        .LOCKED(mmcm_locked), .CLKINSTOPPED(), .CLKFBSTOPPED(),
        .PWRDWN(1'b0), .RST(reset_high), .DADDR(7'd0), .DCLK(1'b0),
        .DEN(1'b0), .DI(16'd0), .DO(), .DRDY(), .DWE(1'b0),
        .CDDCDONE(), .CDDCREQ(1'b0), .PSCLK(1'b0), .PSEN(1'b0),
        .PSINCDEC(1'b0), .PSDONE());
end
endgenerate

BUFG clkfb_buffer (.I(clkfb_mmcm), .O(clkfb));
// Feed the SERDES high-speed clock and its divide-by-four CLKDIV clock from
// the same MMCM output.  BUFGCE_DIV preserves their edge relationship and
// avoids the excessive insertion-delay skew possible with two independent
// MMCM outputs and BUFGs.
BUFGCE #(.SIM_DEVICE(FPGA_FAMILY), .STARTUP_SYNC("TRUE")) clk625_buffer (
    .I(clk625_mmcm), .CE(mmcm_locked), .O(clk625));
BUFGCE_DIV #(
    .BUFGCE_DIVIDE(4), .IS_CE_INVERTED(1'b0),
    .IS_CLR_INVERTED(1'b0), .IS_I_INVERTED(1'b0),
    .SIM_DEVICE(FPGA_FAMILY)) clk156_buffer (
    .I(clk625_mmcm), .CE(mmcm_locked), .CLR(1'b0), .O(clk156));
BUFG clk125_buffer (.I(clk125_mmcm), .O(clk125));
// LOCKED is a status output rather than a synchronous reset. Qualify each
// clock domain through its own two-flop chain before using it in logic.
(* ASYNC_REG = "TRUE" *) reg [1:0] ready_156_sync;
(* ASYNC_REG = "TRUE" *) reg [1:0] ready_axi_sync;
(* ASYNC_REG = "TRUE" *) reg [1:0] ready_gmii_sync;
always @(posedge clk156) ready_156_sync <= {ready_156_sync[0], clock_sources_ready};
always @(posedge s_axi_aclk) ready_axi_sync <= {ready_axi_sync[0], clock_sources_ready};
always @(posedge clk125) ready_gmii_sync <= {ready_gmii_sync[0], clock_sources_ready};
wire clocks_ready = ready_axi_sync[1];

assign gmii_clk125 = clk125;
reg [31:0] control;
(* ASYNC_REG = "TRUE" *) reg [1:0] core_enable_serdes_sync;

// The 125 MHz GMII and 156.25 MHz SelectIO gearbox clocks are frequency
// locked but have a 4:5 ratio. Queue complete MAC frames across the TX clock
// boundary; the terminating gmii_tx_en=0 sample is retained as an explicit
// end marker. Four words of prefill cover synchronizer latency while the two
// domains continue at exactly the same byte/symbol rate.
(* ASYNC_REG = "TRUE" *) reg [1:0] core_enable_gmii_sync;
(* ASYNC_REG = "TRUE" *) reg [1:0] packet_mode_gmii_sync;
(* ASYNC_REG = "TRUE" *) reg [1:0] packet_mode_serdes_sync;
reg gmii_tx_en_d;
reg [31:0] gmii_tx_byte_count;
reg [31:0] gmii_tx_frame_count;
wire [9:0] tx_fifo_wr_data = {gmii_tx_er, gmii_tx_en, gmii_txd};
wire tx_fifo_wr_en = packet_mode_gmii_sync[1] &&
    (gmii_tx_en || gmii_tx_en_d);
wire tx_fifo_full;
wire [5:0] tx_fifo_wr_level;
wire [9:0] tx_fifo_rd_data;
wire tx_fifo_empty;
wire [5:0] tx_fifo_rd_level;
wire tx_fifo_rd_en;
wire tx_fifo_wr_resetn = ready_gmii_sync[1] &&
    core_enable_gmii_sync[1] && packet_mode_gmii_sync[1];
wire tx_fifo_rd_resetn = ready_156_sync[1] &&
    core_enable_serdes_sync[1] && packet_mode_serdes_sync[1];

open_eth_async_fifo #(.WIDTH(10), .ADDR_WIDTH(5)) tx_gmii_fifo (
    .wr_clk(clk125), .wr_resetn(tx_fifo_wr_resetn),
    .wr_data(tx_fifo_wr_data), .wr_en(tx_fifo_wr_en),
    .wr_full(tx_fifo_full), .wr_level(tx_fifo_wr_level),
    .rd_clk(clk156), .rd_resetn(tx_fifo_rd_resetn),
    .rd_data(tx_fifo_rd_data), .rd_en(tx_fifo_rd_en),
    .rd_empty(tx_fifo_empty), .rd_level(tx_fifo_rd_level));

always @(posedge clk125) begin
    core_enable_gmii_sync <= {core_enable_gmii_sync[0], control[0]};
    packet_mode_gmii_sync <= {packet_mode_gmii_sync[0], control[4]};
    if (!ready_gmii_sync[1] || !core_enable_gmii_sync[1]) begin
        gmii_tx_en_d <= 1'b0;
        gmii_tx_byte_count <= 32'd0;
        gmii_tx_frame_count <= 32'd0;
    end else begin
        gmii_tx_en_d <= gmii_tx_en;
        if (gmii_tx_en)
            gmii_tx_byte_count <= gmii_tx_byte_count + 1'b1;
        if (gmii_tx_en && !gmii_tx_en_d)
            gmii_tx_frame_count <= gmii_tx_frame_count + 1'b1;
    end
end

reg [15:0] mdio_divider;
reg [4:0] mdio_phy_addr;
reg [4:0] mdio_reg_addr;
reg mdio_write;
reg [15:0] mdio_write_data;
reg mdio_start;
wire [15:0] mdio_read_data;
wire mdio_busy;
wire mdio_done;
wire mdio_error;
reg mdio_done_latched;
reg mdio_error_latched;
reg [8:0] rx_delay_value;
reg rx_delay_load_toggle;
reg [8:0] tx_test_code;
reg [31:0] scratch;

assign phy_reset_n = s_axi_aresetn && control[1];

open_eth_mdio_master mdio_master (
    .clk(s_axi_aclk), .resetn(s_axi_aresetn),
    .clk_divider(mdio_divider), .start(mdio_start),
    .write_not_read(mdio_write), .phy_addr(mdio_phy_addr),
    .reg_addr(mdio_reg_addr), .write_data(mdio_write_data),
    .read_data(mdio_read_data), .busy(mdio_busy), .done(mdio_done),
    .error(mdio_error), .mdc(mdio_mdc), .mdio_i(mdio_mdio_i),
    .mdio_o(mdio_mdio_o), .mdio_t(mdio_mdio_t));

// AXI4-Lite: one outstanding read and one write. Address and data channels
// are captured independently as required by AXI4-Lite.
reg aw_pending;
reg w_pending;
reg [11:0] awaddr_hold;
reg [31:0] wdata_hold;
reg [3:0] wstrb_hold;
assign s_axi_awready = s_axi_aresetn && !s_axi_bvalid && !aw_pending;
assign s_axi_wready  = s_axi_aresetn && !s_axi_bvalid && !w_pending;
assign s_axi_bresp = 2'b00;
assign s_axi_arready = s_axi_aresetn && !s_axi_rvalid;
assign s_axi_rresp = 2'b00;
wire aw_accept = s_axi_awvalid && s_axi_awready;
wire w_accept = s_axi_wvalid && s_axi_wready;
wire write_fire = !s_axi_bvalid && (aw_pending || aw_accept) &&
    (w_pending || w_accept);
wire [11:0] write_addr = aw_pending ? awaddr_hold : s_axi_awaddr;
wire [31:0] write_data = w_pending ? wdata_hold : s_axi_wdata;
wire [3:0] write_strb = w_pending ? wstrb_hold : s_axi_wstrb;
wire read_fire = s_axi_arvalid && s_axi_arready;

wire [9:0] rx_raw_word_axi;
wire rx_word_toggle_axi;
wire comma_seen_axi;
wire [31:0] rx_word_count_axi;
wire [31:0] comma_count_axi;
wire [31:0] gmii_tx_byte_count_axi;
wire [31:0] gmii_tx_frame_count_axi;
wire [31:0] rx_pcs_status_axi;
wire [31:0] rx_decoded_count_axi;
wire [31:0] rx_code_error_count_axi;
wire [31:0] rx_disparity_error_count_axi;
wire [31:0] rx_sync_loss_count_axi;
wire [9:0] rx_aligned_symbol_axi;
wire [31:0] fifo_status_axi;
wire rx_aligned_axi;
wire rx_synced_axi;
wire [9:0] tx_test_symbol_axi = control[31:22];

integer byte_index;
always @(posedge s_axi_aclk) begin
    mdio_start <= 1'b0;
    if (!s_axi_aresetn) begin
        control <= 32'd0;
        mdio_divider <= 16'd29; // 150 MHz/(2*(29+1)) = 2.5 MHz
        mdio_phy_addr <= 5'd1;
        mdio_reg_addr <= 5'd0;
        mdio_write <= 1'b0;
        mdio_write_data <= 16'd0;
        mdio_done_latched <= 1'b0;
        mdio_error_latched <= 1'b0;
        rx_delay_value <= 9'd0;
        rx_delay_load_toggle <= 1'b0;
        tx_test_code <= {1'b1, 8'hbc}; // K28.5
        scratch <= 32'd0;
        aw_pending <= 1'b0;
        w_pending <= 1'b0;
        awaddr_hold <= 12'd0;
        wdata_hold <= 32'd0;
        wstrb_hold <= 4'd0;
        s_axi_bvalid <= 1'b0;
        s_axi_rvalid <= 1'b0;
        s_axi_rdata <= 32'd0;
    end else begin
        if (mdio_done) mdio_done_latched <= 1'b1;
        if (mdio_error) mdio_error_latched <= 1'b1;
        if (s_axi_bvalid && s_axi_bready) s_axi_bvalid <= 1'b0;
        if (s_axi_rvalid && s_axi_rready) s_axi_rvalid <= 1'b0;
        if (aw_accept) begin
            aw_pending <= 1'b1;
            awaddr_hold <= s_axi_awaddr;
        end
        if (w_accept) begin
            w_pending <= 1'b1;
            wdata_hold <= s_axi_wdata;
            wstrb_hold <= s_axi_wstrb;
        end

        if (write_fire) begin
            aw_pending <= 1'b0;
            w_pending <= 1'b0;
            s_axi_bvalid <= 1'b1;
            case (write_addr[7:2])
                6'h02: begin
                    for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1)
                        if (write_strb[byte_index])
                            control[byte_index*8 +: 8] <= write_data[byte_index*8 +: 8];
                    // Bits 9:8 are write-one commands, not stored state.
                    control[9:8] <= 2'b00;
                    if (write_data[8] && write_strb[1] && !mdio_busy) mdio_start <= 1'b1;
                    if (write_data[9] && write_strb[1]) begin
                        mdio_done_latched <= 1'b0;
                        mdio_error_latched <= 1'b0;
                    end
                end
                6'h04: begin
                    if (write_strb[0]) begin
                        mdio_reg_addr <= write_data[4:0];
                        mdio_write <= write_data[7];
                    end
                    if (write_strb[1]) mdio_phy_addr <= write_data[12:8];
                end
                6'h05: if (write_strb[0] || write_strb[1]) mdio_write_data <= write_data[15:0];
                6'h07: if (write_strb[0] || write_strb[1]) mdio_divider <= write_data[15:0];
                6'h08: if (|write_strb) begin
                    rx_delay_value <= write_data[8:0];
                    rx_delay_load_toggle <= ~rx_delay_load_toggle;
                end
                6'h11: if (write_strb[0] || write_strb[1])
                    tx_test_code <= write_data[8:0];
                6'h18: for (byte_index = 0; byte_index < 4; byte_index = byte_index + 1)
                    if (write_strb[byte_index]) scratch[byte_index*8 +: 8] <= write_data[byte_index*8 +: 8];
                default: ;
            endcase
        end

        if (read_fire) begin
            s_axi_rvalid <= 1'b1;
            case (s_axi_araddr[7:2])
                6'h00: s_axi_rdata <= CORE_ID;
                6'h01: s_axi_rdata <= CORE_VERSION;
                6'h02: s_axi_rdata <= control;
                6'h03: s_axi_rdata <= {17'd0, rx_synced_axi, rx_aligned_axi,
                    idelay_ready, mmcm_locked,
                    comma_seen_axi, rx_word_toggle_axi,
                    clocks_ready, phy_reset_n, mdio_error_latched,
                    mdio_done_latched, mdio_busy, 4'd0};
                6'h04: s_axi_rdata <= {19'd0, mdio_phy_addr, mdio_write, 2'd0, mdio_reg_addr};
                6'h05: s_axi_rdata <= {16'd0, mdio_write_data};
                6'h06: s_axi_rdata <= {16'd0, mdio_read_data};
                6'h07: s_axi_rdata <= {16'd0, mdio_divider};
                6'h08: s_axi_rdata <= {23'd0, rx_delay_value};
                6'h09: s_axi_rdata <= {22'd0, rx_raw_word_axi};
                6'h0a: s_axi_rdata <= {22'd0, tx_test_symbol_axi};
                6'h0b: s_axi_rdata <= CAPABILITIES;
                6'h0c: s_axi_rdata <= rx_word_count_axi;
                6'h0d: s_axi_rdata <= comma_count_axi;
                6'h0e: s_axi_rdata <= gmii_tx_byte_count_axi;
                6'h0f: s_axi_rdata <= gmii_tx_frame_count_axi;
                6'h10: s_axi_rdata <= rx_pcs_status_axi;
                6'h11: s_axi_rdata <= {23'd0, tx_test_code};
                6'h12: s_axi_rdata <= rx_decoded_count_axi;
                6'h13: s_axi_rdata <= rx_code_error_count_axi;
                6'h14: s_axi_rdata <= rx_disparity_error_count_axi;
                6'h15: s_axi_rdata <= rx_sync_loss_count_axi;
                6'h16: s_axi_rdata <= {22'd0, rx_aligned_symbol_axi};
                6'h17: s_axi_rdata <= fifo_status_axi;
                6'h18: s_axi_rdata <= scratch;
                default: s_axi_rdata <= 32'd0;
            endcase
        end
    end
end

// Cross the manually selected delay into the SelectIO CLKDIV domain.  UltraScale
// requires IDELAYE3.CLK and its associated ISERDESE3.CLKDIV to use the same net.
(* ASYNC_REG = "TRUE" *) reg [1:0] delay_toggle_sync;
reg [8:0] delay_value_sync;
wire delay_load = delay_toggle_sync[1] ^ delay_toggle_sync[0];
always @(posedge clk156) begin
    delay_toggle_sync <= {delay_toggle_sync[0], rx_delay_load_toggle};
    delay_value_sync <= rx_delay_value;
end

wire sgmii_rx_i;
wire sgmii_rx_delayed;
IBUFDS #(.DIFF_TERM("FALSE"), .IBUF_LOW_PWR("FALSE")) sgmii_rx_buffer (
    .I(sgmii_rxp), .IB(sgmii_rxn), .O(sgmii_rx_i));
IDELAYE3 #(
    .CASCADE("NONE"), .DELAY_FORMAT("COUNT"), .DELAY_SRC("IDATAIN"),
    .DELAY_TYPE("VAR_LOAD"), .DELAY_VALUE(0),
    .SIM_DEVICE(FPGA_FAMILY)) rx_input_delay (
    .DATAOUT(sgmii_rx_delayed), .IDATAIN(sgmii_rx_i), .DATAIN(1'b0),
    .CLK(clk156), .CE(1'b0), .INC(1'b0), .LOAD(delay_load),
    .CNTVALUEIN(delay_value_sync), .CNTVALUEOUT(), .RST(!ready_156_sync[1]),
    .EN_VTC(1'b0), .CASC_IN(1'b0), .CASC_RETURN(1'b0), .CASC_OUT());

wire [7:0] rx_parallel;
wire rx_serdes_reset;
ISERDESE3 #(
    .DATA_WIDTH(8), .DDR_CLK_EDGE("SAME_EDGE_PIPELINED"),
    .FIFO_ENABLE("FALSE"), .FIFO_SYNC_MODE("FALSE"),
    .IS_CLK_B_INVERTED(1'b1), .SIM_DEVICE(FPGA_FAMILY)) rx_iserdes (
    .Q(rx_parallel), .CLK(clk625), .CLK_B(clk625), .CLKDIV(clk156),
    .D(sgmii_rx_delayed), .RST(rx_serdes_reset),
    .FIFO_RD_CLK(1'b0), .FIFO_RD_EN(1'b0), .FIFO_EMPTY(),
    .INTERNAL_DIVCLK());

reg [9:0] rx_history;
reg [9:0] rx_raw_word;
reg rx_word_toggle;
reg comma_seen;
reg [31:0] rx_word_count;
reg [31:0] comma_count;
reg rx_aligned;
reg rx_synced;
reg [3:0] rx_symbol_start;
reg rx_running_disparity;
reg [4:0] rx_good_streak;
reg [2:0] rx_bad_streak;
reg [9:0] rx_aligned_symbol;
reg [7:0] rx_decoded_byte;
reg rx_decoded_control;
reg rx_last_code_error;
reg rx_last_disparity_error;
reg [31:0] rx_decoded_count;
reg [31:0] rx_code_error_count;
reg [31:0] rx_disparity_error_count;
reg [31:0] rx_sync_loss_count;
reg [9:0] rx_decode_symbol;
reg rx_decode_disparity_in;
reg rx_decode_was_aligned;
reg rx_decode_valid;
reg [9:0] rx_result_symbol;
reg [7:0] rx_result_byte;
reg rx_result_control;
reg rx_result_disparity_error;
reg rx_result_code_error;
reg rx_result_was_aligned;
reg rx_result_valid;
reg rx_pcs_frame;
reg [9:0] rx_gmii_word;
reg rx_pcs_frame_after;
wire rx_fifo_wr_en = packet_mode_serdes_sync[1] && rx_synced &&
    rx_result_valid;
wire rx_fifo_full;
wire [5:0] rx_fifo_wr_level;
wire [9:0] rx_fifo_rd_data;
wire rx_fifo_empty;
wire [5:0] rx_fifo_rd_level;
wire rx_fifo_rd_en;
reg rx_fifo_started;
wire rx_fifo_wr_resetn = ready_156_sync[1] &&
    core_enable_serdes_sync[1] && packet_mode_serdes_sync[1];
wire rx_fifo_rd_resetn = ready_gmii_sync[1] &&
    core_enable_gmii_sync[1] && packet_mode_gmii_sync[1];
wire [17:0] rx_scan_window = {rx_parallel, rx_history};

// Convert each decoded 1000BASE-X code group into one GMII sample. /S/
// reconstructs the first preamble byte which the PCS replaces on transmit.
// A word is queued for every valid code group, including idles, preserving
// the fixed one-symbol-per-GMII-cycle rate across the elastic buffer.
always @* begin
    rx_gmii_word = 10'd0;
    rx_pcs_frame_after = rx_pcs_frame;
    if (rx_result_code_error ||
        (rx_result_was_aligned && rx_result_disparity_error)) begin
        rx_gmii_word = {1'b1, rx_pcs_frame, rx_result_byte};
    end else if (rx_result_control) begin
        case (rx_result_byte)
            PCS_K28_5: begin
                rx_gmii_word = 10'd0;
                rx_pcs_frame_after = 1'b0;
            end
            PCS_K27_7: begin
                rx_gmii_word = {1'b0, 1'b1, 8'h55};
                rx_pcs_frame_after = 1'b1;
            end
            PCS_K29_7: begin
                rx_gmii_word = 10'd0;
                rx_pcs_frame_after = 1'b0;
            end
            PCS_K23_7: begin
                rx_gmii_word = {1'b1, 1'b0, 8'd0};
                rx_pcs_frame_after = 1'b0;
            end
            PCS_K30_7: rx_gmii_word =
                {1'b1, rx_pcs_frame, PCS_K30_7};
            default: begin
                rx_gmii_word = {1'b1, 1'b0, rx_result_byte};
                rx_pcs_frame_after = 1'b0;
            end
        endcase
    end else if (rx_pcs_frame) begin
        rx_gmii_word = {1'b0, 1'b1, rx_result_byte};
    end
end

open_eth_async_fifo #(.WIDTH(10), .ADDR_WIDTH(5)) rx_gmii_fifo (
    .wr_clk(clk156), .wr_resetn(rx_fifo_wr_resetn),
    .wr_data(rx_gmii_word), .wr_en(rx_fifo_wr_en),
    .wr_full(rx_fifo_full), .wr_level(rx_fifo_wr_level),
    .rd_clk(clk125), .rd_resetn(rx_fifo_rd_resetn),
    .rd_data(rx_fifo_rd_data), .rd_en(rx_fifo_rd_en),
    .rd_empty(rx_fifo_empty), .rd_level(rx_fifo_rd_level));

assign rx_fifo_rd_en = packet_mode_gmii_sync[1] &&
    ((rx_fifo_started && !rx_fifo_empty) ||
     (!rx_fifo_started && rx_fifo_rd_level >= 6'd8));

always @(posedge clk125) begin
    if (!rx_fifo_rd_resetn) begin
        rx_fifo_started <= 1'b0;
        gmii_rxd <= 8'd0;
        gmii_rx_dv <= 1'b0;
        gmii_rx_er <= 1'b0;
    end else if (rx_fifo_rd_en) begin
        rx_fifo_started <= 1'b1;
        gmii_rxd <= rx_fifo_rd_data[7:0];
        gmii_rx_dv <= rx_fifo_rd_data[8];
        gmii_rx_er <= rx_fifo_rd_data[9];
    end else begin
        if (rx_fifo_empty)
            rx_fifo_started <= 1'b0;
        gmii_rxd <= 8'd0;
        gmii_rx_dv <= 1'b0;
        gmii_rx_er <= 1'b0;
    end
end

function automatic is_comma;
    input [9:0] symbol;
    begin
        is_comma = symbol == 10'b0101111100 ||
            symbol == 10'b1010000011 || symbol == 10'b1001111100 ||
            symbol == 10'b0110000011;
    end
endfunction

// Running disparity can be carried into the decoder pipeline without waiting
// for the full legality decode. Legal 8b/10b symbols have a disparity of -2,
// zero, or +2; neutral symbols retain the previous running disparity.
function automatic symbol_running_disparity;
    input [9:0] symbol;
    input current_disparity;
    integer bit_index;
    reg [3:0] ones;
    begin
        ones = 4'd0;
        for (bit_index = 0; bit_index < 10; bit_index = bit_index + 1)
            ones = ones + symbol[bit_index];
        if (ones > 4'd5)
            symbol_running_disparity = 1'b1;
        else if (ones < 4'd5)
            symbol_running_disparity = 1'b0;
        else
            symbol_running_disparity = current_disparity;
    end
endfunction

wire [7:0] rx_comma_hits;
genvar comma_offset;
generate
    for (comma_offset = 0; comma_offset < 8; comma_offset = comma_offset + 1) begin : comma_scan
        assign rx_comma_hits[comma_offset] =
            is_comma(rx_scan_window[comma_offset + 1 +: 10]);
    end
endgenerate
wire rx_comma_event = |rx_comma_hits;
reg [3:0] rx_comma_start;
always @* begin
    if (rx_comma_hits[0]) rx_comma_start = 4'd1;
    else if (rx_comma_hits[1]) rx_comma_start = 4'd2;
    else if (rx_comma_hits[2]) rx_comma_start = 4'd3;
    else if (rx_comma_hits[3]) rx_comma_start = 4'd4;
    else if (rx_comma_hits[4]) rx_comma_start = 4'd5;
    else if (rx_comma_hits[5]) rx_comma_start = 4'd6;
    else if (rx_comma_hits[6]) rx_comma_start = 4'd7;
    else if (rx_comma_hits[7]) rx_comma_start = 4'd8;
    else rx_comma_start = 4'd0;
end

wire rx_aligned_word_valid = rx_aligned && rx_symbol_start <= 4'd8;
wire rx_candidate_valid = rx_aligned_word_valid || (!rx_aligned && rx_comma_event);
wire [3:0] rx_candidate_start = rx_aligned ? rx_symbol_start : rx_comma_start;
wire [9:0] rx_candidate_symbol = rx_scan_window[rx_candidate_start +: 10];
wire [7:0] rx_decode_byte;
wire rx_decode_control;
wire rx_decode_disparity;
wire rx_decode_disparity_error;
wire rx_decode_code_error;
open_eth_8b10b_decoder rx_decoder (
    .symbol(rx_decode_symbol), .disparity_in(rx_decode_disparity_in),
    .data(rx_decode_byte), .is_control(rx_decode_control),
    .disparity_out(rx_decode_disparity),
    .disparity_error(rx_decode_disparity_error),
    .code_error(rx_decode_code_error));
assign rx_serdes_reset = !ready_156_sync[1] || !core_enable_serdes_sync[1];

// Dedicated SelectIO deserialization keeps the 625 MHz path entirely inside
// the I/O tile.  The fabric sees eight serial bits per 156.25 MHz cycle.  The
// 18-bit scan window covers every newly completed 10-bit alignment, allowing
// comma discovery before alignment. Once a comma is found, rx_symbol_start
// advances by ten symbol bits and retreats by the eight bits consumed on each
// CLKDIV cycle. This produces exactly four symbols every five cycles without
// inventing a false one-symbol-per-cycle clock. Extracted symbols and decoder
// results are separately registered, removing the variable-select and counter
// logic from the codec's 156.25 MHz timing path.
always @(posedge clk156) begin
    core_enable_serdes_sync <= {core_enable_serdes_sync[0], control[0]};
    if (!ready_156_sync[1] || !core_enable_serdes_sync[1]) begin
        rx_history <= 10'd0;
        rx_raw_word <= 10'd0;
        rx_word_toggle <= 1'b0;
        comma_seen <= 1'b0;
        rx_word_count <= 32'd0;
        comma_count <= 32'd0;
        rx_aligned <= 1'b0;
        rx_synced <= 1'b0;
        rx_symbol_start <= 4'd1;
        rx_running_disparity <= 1'b0;
        rx_good_streak <= 5'd0;
        rx_bad_streak <= 3'd0;
        rx_aligned_symbol <= 10'd0;
        rx_decoded_byte <= 8'd0;
        rx_decoded_control <= 1'b0;
        rx_last_code_error <= 1'b0;
        rx_last_disparity_error <= 1'b0;
        rx_decoded_count <= 32'd0;
        rx_code_error_count <= 32'd0;
        rx_disparity_error_count <= 32'd0;
        rx_sync_loss_count <= 32'd0;
        rx_decode_symbol <= 10'd0;
        rx_decode_disparity_in <= 1'b0;
        rx_decode_was_aligned <= 1'b0;
        rx_decode_valid <= 1'b0;
        rx_result_symbol <= 10'd0;
        rx_result_byte <= 8'd0;
        rx_result_control <= 1'b0;
        rx_result_disparity_error <= 1'b0;
        rx_result_code_error <= 1'b0;
        rx_result_was_aligned <= 1'b0;
        rx_result_valid <= 1'b0;
        rx_pcs_frame <= 1'b0;
    end else begin
        rx_history <= rx_scan_window[17:8];
        rx_raw_word <= rx_scan_window[17:8];
        rx_decode_valid <= rx_candidate_valid;
        rx_result_valid <= rx_decode_valid;
        if (!packet_mode_serdes_sync[1])
            rx_pcs_frame <= 1'b0;
        else if (rx_result_valid && rx_synced)
            rx_pcs_frame <= rx_pcs_frame_after;

        if (rx_candidate_valid) begin
            rx_decode_symbol <= rx_candidate_symbol;
            rx_decode_disparity_in <= rx_running_disparity;
            rx_decode_was_aligned <= rx_aligned;
            rx_running_disparity <= symbol_running_disparity(
                rx_candidate_symbol, rx_running_disparity);
            rx_raw_word <= rx_candidate_symbol;
            rx_word_toggle <= ~rx_word_toggle;
            rx_word_count <= rx_word_count + 1'b1;
        end

        if (rx_decode_valid) begin
            rx_result_symbol <= rx_decode_symbol;
            rx_result_byte <= rx_decode_byte;
            rx_result_control <= rx_decode_control;
            rx_result_disparity_error <= rx_decode_disparity_error;
            rx_result_code_error <= rx_decode_code_error;
            rx_result_was_aligned <= rx_decode_was_aligned;
        end

        if (rx_aligned) begin
            if (rx_aligned_word_valid)
                rx_symbol_start <= rx_symbol_start + 4'd2;
            else
                rx_symbol_start <= rx_symbol_start - 4'd8;
        end else if (rx_comma_event) begin
            rx_aligned <= 1'b1;
            rx_symbol_start <= rx_comma_start + 4'd2;
        end

        if (rx_result_valid) begin
            rx_aligned_symbol <= rx_result_symbol;
            rx_decoded_count <= rx_decoded_count + 1'b1;
            rx_decoded_byte <= rx_result_byte;
            rx_decoded_control <= rx_result_control;
            rx_last_code_error <= rx_result_code_error;
            // The first comma establishes disparity; there was no meaningful
            // expected running disparity before that symbol.
            rx_last_disparity_error <= rx_result_was_aligned &&
                rx_result_disparity_error;

            if (rx_result_code_error) begin
                rx_code_error_count <= rx_code_error_count + 1'b1;
            end
            if (rx_result_was_aligned && rx_result_disparity_error) begin
                rx_disparity_error_count <= rx_disparity_error_count + 1'b1;
            end

            if (!rx_result_code_error &&
                (!rx_result_was_aligned || !rx_result_disparity_error)) begin
                rx_bad_streak <= 3'd0;
                if (rx_good_streak < 5'd16)
                    rx_good_streak <= rx_good_streak + 1'b1;
                if (rx_good_streak >= 5'd15)
                    rx_synced <= 1'b1;
            end else begin
                rx_good_streak <= 5'd0;
                if (rx_bad_streak < 3'd4)
                    rx_bad_streak <= rx_bad_streak + 1'b1;
                if (rx_bad_streak >= 3'd3) begin
                    if (rx_synced)
                        rx_sync_loss_count <= rx_sync_loss_count + 1'b1;
                    rx_aligned <= 1'b0;
                    rx_synced <= 1'b0;
                    rx_bad_streak <= 3'd0;
                    rx_running_disparity <= 1'b0;
                    rx_decode_valid <= 1'b0;
                    rx_result_valid <= 1'b0;
                    rx_pcs_frame <= 1'b0;
                end
            end
        end
        if (rx_comma_event) begin
            comma_seen <= 1'b1;
            comma_count <= comma_count + 1'b1;
        end
    end
end

// Control bit 4 selects packet transport, bit 3 selects the encoded diagnostic,
// and neither bit selects the raw-symbol diagnostic. The PCS replaces the
// first GMII preamble byte with /S/, terminates with /T/ and /R/, and emits
// alternating /I1/ or /I2/ ordered sets while idle. Four symbols are encoded
// over four CLKDIV cycles and atomically published on the fifth gearbox cycle.
// This sustains line rate with only one combinational codec in the timing path.
(* ASYNC_REG = "TRUE" *) reg [1:0] tx_enable_sync;
(* ASYNC_REG = "TRUE" *) reg [9:0] tx_symbol_meta;
(* ASYNC_REG = "TRUE" *) reg [9:0] tx_symbol_sync;
(* ASYNC_REG = "TRUE" *) reg [8:0] tx_code_meta;
(* ASYNC_REG = "TRUE" *) reg [8:0] tx_code_sync;
(* ASYNC_REG = "TRUE" *) reg [1:0] tx_codec_mode_sync;
reg [2:0] tx_chunk_phase;
reg tx_running_disparity;
wire [9:0] tx_symbol_requested = control[31:22];
wire [39:0] tx_repeated_symbols = {4{tx_symbol_sync}};
reg [9:0] tx_encoded_symbol0;
reg [9:0] tx_encoded_symbol1;
reg [9:0] tx_encoded_symbol2;
reg [9:0] tx_encoded_symbol3;
reg [39:0] tx_encoded_symbols;
reg tx_pipeline_disparity;
reg tx_pipeline_error;
reg tx_pcs_frame;
reg tx_pcs_odd;
reg tx_pcs_extend;
reg tx_pcs_frame_next;
reg tx_pcs_extend_next;
reg [8:0] tx_pcs_code;
reg tx_pcs_pop;
wire tx_encoder_disparity_in = (tx_chunk_phase == 3'd0) ?
    tx_running_disparity : tx_pipeline_disparity;
wire tx_encoded_mode = tx_codec_mode_sync[1] ||
    packet_mode_serdes_sync[1];
wire [7:0] tx_encoder_data = packet_mode_serdes_sync[1] ?
    tx_pcs_code[7:0] : tx_code_sync[7:0];
wire tx_encoder_control = packet_mode_serdes_sync[1] ?
    tx_pcs_code[8] : tx_code_sync[8];
wire [9:0] tx_encoder_symbol;
wire tx_encoder_disparity_out;
wire tx_encoder_error;
open_eth_8b10b_encoder tx_encoder (
    .data(tx_encoder_data), .is_control(tx_encoder_control),
    .disparity_in(tx_encoder_disparity_in), .symbol(tx_encoder_symbol),
    .disparity_out(tx_encoder_disparity_out), .code_error(tx_encoder_error));
wire [39:0] tx_active_symbols = tx_encoded_mode ?
    tx_encoded_symbols : tx_repeated_symbols;
assign tx_fifo_rd_en = packet_mode_serdes_sync[1] &&
    tx_chunk_phase != 3'd4 && tx_pcs_pop;

always @* begin
    tx_pcs_code = {1'b1, PCS_K28_5};
    tx_pcs_pop = 1'b0;
    tx_pcs_frame_next = tx_pcs_frame;
    tx_pcs_extend_next = tx_pcs_extend;

    if (tx_pcs_frame) begin
        if (tx_fifo_empty) begin
            // An unexpected FIFO starvation is made visible on the wire.
            tx_pcs_code = {1'b1, PCS_K30_7};
            tx_pcs_frame_next = 1'b0;
            tx_pcs_extend_next = 1'b1;
        end else begin
            tx_pcs_pop = 1'b1;
            if (tx_fifo_rd_data[8]) begin
                tx_pcs_code = tx_fifo_rd_data[9] ?
                    {1'b1, PCS_K30_7} : {1'b0, tx_fifo_rd_data[7:0]};
            end else begin
                tx_pcs_code = {1'b1, PCS_K29_7};
                tx_pcs_frame_next = 1'b0;
                tx_pcs_extend_next = 1'b1;
            end
        end
    end else if (tx_pcs_extend) begin
        tx_pcs_code = {1'b1, PCS_K23_7};
        if (tx_pcs_odd)
            tx_pcs_extend_next = 1'b0;
    end else if (!tx_pcs_odd && tx_fifo_rd_level >= 6'd4 &&
                 !tx_fifo_empty && tx_fifo_rd_data[8]) begin
        tx_pcs_code = {1'b1, PCS_K27_7};
        tx_pcs_pop = 1'b1;
        tx_pcs_frame_next = 1'b1;
    end else if (!tx_pcs_odd) begin
        tx_pcs_code = {1'b1, PCS_K28_5};
    end else begin
        tx_pcs_code = tx_encoder_disparity_in ?
            {1'b0, PCS_D16_2} : {1'b0, PCS_D5_6};
    end
end

reg [7:0] tx_parallel;
wire tx_serial;
always @* begin
    case (tx_chunk_phase)
        3'd0: tx_parallel = tx_active_symbols[7:0];
        3'd1: tx_parallel = tx_active_symbols[15:8];
        3'd2: tx_parallel = tx_active_symbols[23:16];
        3'd3: tx_parallel = tx_active_symbols[31:24];
        default: tx_parallel = tx_active_symbols[39:32];
    endcase
    if (!tx_enable_sync[1]) tx_parallel = 8'd0;
end
always @(posedge clk156) begin
    tx_enable_sync <= {tx_enable_sync[0], control[2]};
    tx_codec_mode_sync <= {tx_codec_mode_sync[0], control[3]};
    packet_mode_serdes_sync <= {packet_mode_serdes_sync[0], control[4]};
    tx_symbol_meta <= tx_symbol_requested;
    tx_symbol_sync <= tx_symbol_meta;
    tx_code_meta <= tx_test_code;
    tx_code_sync <= tx_code_meta;
    if (!ready_156_sync[1] || !core_enable_serdes_sync[1]) begin
        tx_chunk_phase <= 3'd0;
        tx_running_disparity <= 1'b0;
        tx_pipeline_disparity <= 1'b0;
        tx_pipeline_error <= 1'b0;
        tx_encoded_symbol0 <= 10'd0;
        tx_encoded_symbol1 <= 10'd0;
        tx_encoded_symbol2 <= 10'd0;
        tx_encoded_symbol3 <= 10'd0;
        tx_encoded_symbols <= 40'd0;
        tx_pcs_frame <= 1'b0;
        tx_pcs_odd <= 1'b0;
        tx_pcs_extend <= 1'b0;
    end else if (tx_chunk_phase == 3'd4) begin
        tx_chunk_phase <= 3'd0;
        if (tx_encoded_mode && !tx_pipeline_error) begin
            tx_encoded_symbols <= {tx_encoded_symbol3,
                tx_encoded_symbol2, tx_encoded_symbol1,
                tx_encoded_symbol0};
            tx_running_disparity <= tx_pipeline_disparity;
        end
    end else begin
        tx_chunk_phase <= tx_chunk_phase + 1'b1;
        if (packet_mode_serdes_sync[1]) begin
            tx_pcs_frame <= tx_pcs_frame_next;
            tx_pcs_extend <= tx_pcs_extend_next;
            tx_pcs_odd <= ~tx_pcs_odd;
        end else begin
            tx_pcs_frame <= 1'b0;
            tx_pcs_odd <= 1'b0;
            tx_pcs_extend <= 1'b0;
        end
        tx_pipeline_disparity <= tx_encoder_disparity_out;
        if (tx_chunk_phase == 3'd0)
            tx_pipeline_error <= tx_encoder_error;
        else
            tx_pipeline_error <= tx_pipeline_error || tx_encoder_error;
        case (tx_chunk_phase)
            3'd0: tx_encoded_symbol0 <= tx_encoder_symbol;
            3'd1: tx_encoded_symbol1 <= tx_encoder_symbol;
            3'd2: tx_encoded_symbol2 <= tx_encoder_symbol;
            default: tx_encoded_symbol3 <= tx_encoder_symbol;
        endcase
    end
end
OSERDESE3 #(
    .DATA_WIDTH(8), .INIT(1'b0), .SIM_DEVICE(FPGA_FAMILY)) tx_oserdes (
    .OQ(tx_serial), .T_OUT(), .CLK(clk625), .CLKDIV(clk156),
    .D(tx_parallel), .RST(rx_serdes_reset), .T(1'b0));
OBUFDS sgmii_tx_buffer (.I(tx_serial), .O(sgmii_txp), .OB(sgmii_txn));

// Debug values are monotonic or stable snapshots. Double-flop them into AXI
// space; exact atomicity is unnecessary for diagnostic counters.
(* ASYNC_REG = "TRUE" *) reg [9:0] rx_raw_meta, rx_raw_sync;
(* ASYNC_REG = "TRUE" *) reg [1:0] rx_toggle_sync;
(* ASYNC_REG = "TRUE" *) reg [1:0] comma_sync;
(* ASYNC_REG = "TRUE" *) reg [31:0] rx_count_meta, rx_count_sync;
(* ASYNC_REG = "TRUE" *) reg [31:0] comma_count_meta, comma_count_sync;
(* ASYNC_REG = "TRUE" *) reg [31:0] tx_bytes_meta, tx_bytes_sync;
(* ASYNC_REG = "TRUE" *) reg [31:0] tx_frames_meta, tx_frames_sync;
wire [31:0] rx_pcs_status = {14'd0, rx_running_disparity,
    rx_symbol_start, rx_synced, rx_aligned, rx_last_disparity_error,
    rx_last_code_error, rx_decoded_control, rx_decoded_byte};
(* ASYNC_REG = "TRUE" *) reg [31:0] pcs_status_meta, pcs_status_sync;
(* ASYNC_REG = "TRUE" *) reg [31:0] decoded_count_meta, decoded_count_sync;
(* ASYNC_REG = "TRUE" *) reg [31:0] code_error_meta, code_error_sync;
(* ASYNC_REG = "TRUE" *) reg [31:0] disparity_error_meta, disparity_error_sync;
(* ASYNC_REG = "TRUE" *) reg [31:0] sync_loss_meta, sync_loss_sync;
(* ASYNC_REG = "TRUE" *) reg [9:0] aligned_symbol_meta, aligned_symbol_sync;
wire [31:0] fifo_status = {8'd0, rx_fifo_wr_level,
    rx_fifo_rd_level, tx_fifo_wr_level, tx_fifo_rd_level};
(* ASYNC_REG = "TRUE" *) reg [31:0] fifo_status_meta, fifo_status_sync;
always @(posedge s_axi_aclk) begin
    rx_raw_meta <= rx_raw_word; rx_raw_sync <= rx_raw_meta;
    rx_toggle_sync <= {rx_toggle_sync[0], rx_word_toggle};
    comma_sync <= {comma_sync[0], comma_seen};
    rx_count_meta <= rx_word_count; rx_count_sync <= rx_count_meta;
    comma_count_meta <= comma_count; comma_count_sync <= comma_count_meta;
    tx_bytes_meta <= gmii_tx_byte_count; tx_bytes_sync <= tx_bytes_meta;
    tx_frames_meta <= gmii_tx_frame_count; tx_frames_sync <= tx_frames_meta;
    pcs_status_meta <= rx_pcs_status; pcs_status_sync <= pcs_status_meta;
    decoded_count_meta <= rx_decoded_count;
    decoded_count_sync <= decoded_count_meta;
    code_error_meta <= rx_code_error_count;
    code_error_sync <= code_error_meta;
    disparity_error_meta <= rx_disparity_error_count;
    disparity_error_sync <= disparity_error_meta;
    sync_loss_meta <= rx_sync_loss_count; sync_loss_sync <= sync_loss_meta;
    aligned_symbol_meta <= rx_aligned_symbol;
    aligned_symbol_sync <= aligned_symbol_meta;
    fifo_status_meta <= fifo_status; fifo_status_sync <= fifo_status_meta;
end
assign rx_raw_word_axi = rx_raw_sync;
assign rx_word_toggle_axi = rx_toggle_sync[1];
assign comma_seen_axi = comma_sync[1];
assign rx_word_count_axi = rx_count_sync;
assign comma_count_axi = comma_count_sync;
assign gmii_tx_byte_count_axi = tx_bytes_sync;
assign gmii_tx_frame_count_axi = tx_frames_sync;
assign rx_pcs_status_axi = pcs_status_sync;
assign rx_decoded_count_axi = decoded_count_sync;
assign rx_code_error_count_axi = code_error_sync;
assign rx_disparity_error_count_axi = disparity_error_sync;
assign rx_sync_loss_count_axi = sync_loss_sync;
assign rx_aligned_symbol_axi = aligned_symbol_sync;
assign fifo_status_axi = fifo_status_sync;
assign rx_aligned_axi = pcs_status_sync[11];
assign rx_synced_axi = pcs_status_sync[12];

endmodule
