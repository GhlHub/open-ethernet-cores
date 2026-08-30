// SPDX-License-Identifier: GPL-3.0-or-later
`timescale 1ps/1ps

module tb_open_eth_sgmii_pcs_pma;

localparam [9:0] K28_5_RD_NEG = 10'b0101111100;
localparam [9:0] K28_5_RD_POS = 10'b1010000011;
localparam [9:0] K28_1_RD_NEG = 10'b1001111100;
localparam [9:0] K28_1_RD_POS = 10'b0110000011;
localparam [31:0] BASE_CONTROL = {K28_5_RD_NEG, 22'd0} | 32'h0000_0007;
localparam [31:0] EXPECTED_ID = 32'h4f50_4353;
localparam [31:0] EXPECTED_VERSION = 32'h0001_0003;

reg s_axi_aclk = 1'b0;
reg s_axi_aresetn = 1'b0;
reg [11:0] s_axi_awaddr = 12'd0;
reg s_axi_awvalid = 1'b0;
wire s_axi_awready;
reg [31:0] s_axi_wdata = 32'd0;
reg [3:0] s_axi_wstrb = 4'd0;
reg s_axi_wvalid = 1'b0;
wire s_axi_wready;
wire [1:0] s_axi_bresp;
wire s_axi_bvalid;
reg s_axi_bready = 1'b0;
reg [11:0] s_axi_araddr = 12'd0;
reg s_axi_arvalid = 1'b0;
wire s_axi_arready;
wire [31:0] s_axi_rdata;
wire [1:0] s_axi_rresp;
wire s_axi_rvalid;
reg s_axi_rready = 1'b0;

reg refclk625_p = 1'b0;
wire refclk625_n = ~refclk625_p;
wire sgmii_txp;
wire sgmii_txn;
wire sgmii_rxp = sgmii_txp;
wire sgmii_rxn = sgmii_txn;
wire mdio_mdc;
wire mdio_o;
wire mdio_t;
reg phy_mdio_drive = 1'b1;
reg phy_mdio_enable = 1'b0;
wire mdio_line = phy_mdio_enable ? phy_mdio_drive : 1'b1;
wire phy_reset_n;
wire gmii_clk125;
reg [7:0] gmii_txd = 8'd0;
reg gmii_tx_en = 1'b0;
reg gmii_tx_er = 1'b0;
wire [7:0] gmii_rxd;
wire gmii_rx_dv;
wire gmii_rx_er;

integer failures = 0;
integer checks = 0;
reg [31:0] value;
reg [63:0] captured_frame;
reg [45:0] captured_header;
reg [15:0] phy_read_value;
reg mdio_drive_violation;
integer bit_number;
integer codec_byte;
integer codec_rd;
integer gmii_index;
integer gmii_rx_count;
reg gmii_frame_pass;
reg codec_exhaustive_pass;
reg [7:0] codec_data = 8'd0;
reg codec_control = 1'b0;
reg codec_encoder_disparity = 1'b0;
reg codec_decoder_disparity = 1'b0;
wire [9:0] codec_symbol;
wire codec_encoder_disparity_out;
wire codec_encoder_error;
wire [7:0] codec_decoded_data;
wire codec_decoded_control;
wire codec_decoder_disparity_out;
wire codec_disparity_error;
wire codec_code_error;

// 150 MHz AXI, 625 MHz SGMII reference, and a standalone 125 MHz MAC clock.
always #3333 s_axi_aclk = ~s_axi_aclk;
always #800 refclk625_p = ~refclk625_p;

open_eth_8b10b_encoder codec_encoder (
    .data(codec_data), .is_control(codec_control),
    .disparity_in(codec_encoder_disparity), .symbol(codec_symbol),
    .disparity_out(codec_encoder_disparity_out),
    .code_error(codec_encoder_error));
open_eth_8b10b_decoder codec_decoder (
    .symbol(codec_symbol), .disparity_in(codec_decoder_disparity),
    .data(codec_decoded_data), .is_control(codec_decoded_control),
    .disparity_out(codec_decoder_disparity_out),
    .disparity_error(codec_disparity_error), .code_error(codec_code_error));

open_eth_sgmii_pcs_pma #(.FPGA_FAMILY("ULTRASCALE")) dut (
    .s_axi_aclk(s_axi_aclk), .s_axi_aresetn(s_axi_aresetn),
    .s_axi_awaddr(s_axi_awaddr), .s_axi_awvalid(s_axi_awvalid),
    .s_axi_awready(s_axi_awready), .s_axi_wdata(s_axi_wdata),
    .s_axi_wstrb(s_axi_wstrb), .s_axi_wvalid(s_axi_wvalid),
    .s_axi_wready(s_axi_wready), .s_axi_bresp(s_axi_bresp),
    .s_axi_bvalid(s_axi_bvalid), .s_axi_bready(s_axi_bready),
    .s_axi_araddr(s_axi_araddr), .s_axi_arvalid(s_axi_arvalid),
    .s_axi_arready(s_axi_arready), .s_axi_rdata(s_axi_rdata),
    .s_axi_rresp(s_axi_rresp), .s_axi_rvalid(s_axi_rvalid),
    .s_axi_rready(s_axi_rready), .refclk625_p(refclk625_p),
    .refclk625_n(refclk625_n), .sgmii_rxp(sgmii_rxp),
    .sgmii_rxn(sgmii_rxn), .sgmii_txp(sgmii_txp),
    .sgmii_txn(sgmii_txn), .mdio_mdc(mdio_mdc),
    .mdio_mdio_i(mdio_line), .mdio_mdio_o(mdio_o),
    .mdio_mdio_t(mdio_t), .phy_reset_n(phy_reset_n),
    .gmii_clk125(gmii_clk125),
    .gmii_txd(gmii_txd), .gmii_tx_en(gmii_tx_en),
    .gmii_tx_er(gmii_tx_er), .gmii_rxd(gmii_rxd),
    .gmii_rx_dv(gmii_rx_dv), .gmii_rx_er(gmii_rx_er));

task automatic check(input bit condition, input string description);
begin
    checks = checks + 1;
    if (!condition) begin
        failures = failures + 1;
        $display("FAIL: %s at %0t ps", description, $time);
    end else begin
        $display("PASS: %s", description);
    end
end
endtask

function automatic bit is_cyclic_rotation(input [9:0] observed,
                                           input [9:0] expected);
integer rotation;
reg [19:0] doubled;
begin
    doubled = {expected, expected};
    is_cyclic_rotation = 1'b0;
    for (rotation = 0; rotation < 10; rotation = rotation + 1)
        if (observed == doubled[rotation +: 10])
            is_cyclic_rotation = 1'b1;
end
endfunction

task automatic axi_send_aw(input [11:0] address);
begin
    @(negedge s_axi_aclk);
    s_axi_awaddr = address;
    s_axi_awvalid = 1'b1;
    do @(posedge s_axi_aclk); while (!s_axi_awready);
    @(negedge s_axi_aclk);
    s_axi_awvalid = 1'b0;
end
endtask

task automatic axi_send_w(input [31:0] data, input [3:0] strobe);
begin
    @(negedge s_axi_aclk);
    s_axi_wdata = data;
    s_axi_wstrb = strobe;
    s_axi_wvalid = 1'b1;
    do @(posedge s_axi_aclk); while (!s_axi_wready);
    @(negedge s_axi_aclk);
    s_axi_wvalid = 1'b0;
end
endtask

// order: 0 = simultaneous, 1 = address first, 2 = data first.
task automatic axi_write(input [11:0] address, input [31:0] data,
                         input [3:0] strobe, input integer order);
begin
    s_axi_bready = 1'b0;
    case (order)
        0: fork
            axi_send_aw(address);
            axi_send_w(data, strobe);
        join
        1: begin
            axi_send_aw(address);
            repeat (3) @(posedge s_axi_aclk);
            axi_send_w(data, strobe);
        end
        default: begin
            axi_send_w(data, strobe);
            repeat (3) @(posedge s_axi_aclk);
            axi_send_aw(address);
        end
    endcase
    wait (s_axi_bvalid === 1'b1);
    check(s_axi_bresp == 2'b00, "AXI write response is OKAY");
    @(negedge s_axi_aclk);
    s_axi_bready = 1'b1;
    @(posedge s_axi_aclk);
    @(negedge s_axi_aclk);
    s_axi_bready = 1'b0;
end
endtask

task automatic axi_read(input [11:0] address, output [31:0] data);
begin
    s_axi_rready = 1'b0;
    @(negedge s_axi_aclk);
    s_axi_araddr = address;
    s_axi_arvalid = 1'b1;
    do @(posedge s_axi_aclk); while (!s_axi_arready);
    @(negedge s_axi_aclk);
    s_axi_arvalid = 1'b0;
    wait (s_axi_rvalid === 1'b1);
    data = s_axi_rdata;
    check(s_axi_rresp == 2'b00, "AXI read response is OKAY");
    @(negedge s_axi_aclk);
    s_axi_rready = 1'b1;
    @(posedge s_axi_aclk);
    @(negedge s_axi_aclk);
    s_axi_rready = 1'b0;
end
endtask

task automatic wait_mdio_done;
integer timeout;
begin
    timeout = 0;
    while (!dut.mdio_done_latched && !dut.mdio_error_latched &&
           timeout < 20000) begin
        @(posedge s_axi_aclk);
        timeout = timeout + 1;
    end
    check(timeout < 20000, "MDIO transaction completed before timeout");
end
endtask

task automatic check_repeated_comma(input [9:0] symbol,
                                    input string description);
reg [31:0] count_before;
reg [31:0] count_after;
begin
    axi_read(12'h034, count_before);
    axi_write(12'h008, {symbol, 22'd0} | 32'h0000_0007, 4'hf, 0);
    repeat (120) @(posedge refclk625_p);
    axi_read(12'h034, count_after);
    check(count_after > count_before, description);
end
endtask

initial begin
    $display("OPEN_ETH_SGMII_PCS_PMA_SELFTEST=START");

    // Exhaust every data byte and valid control character at both running
    // disparities before exercising the integrated serial datapath.
    codec_exhaustive_pass = 1'b1;
    for (codec_rd = 0; codec_rd < 2; codec_rd = codec_rd + 1) begin
        for (codec_byte = 0; codec_byte < 256; codec_byte = codec_byte + 1) begin
            codec_data = codec_byte[7:0];
            codec_control = 1'b0;
            codec_encoder_disparity = codec_rd[0];
            codec_decoder_disparity = codec_rd[0];
            #1;
            if (codec_encoder_error || codec_code_error ||
                codec_disparity_error || codec_decoded_data != codec_data ||
                codec_decoded_control ||
                codec_decoder_disparity_out != codec_encoder_disparity_out)
                codec_exhaustive_pass = 1'b0;
        end
        for (codec_byte = 0; codec_byte < 256; codec_byte = codec_byte + 1) begin
            if ((codec_byte[4:0] == 5'd28) ||
                (codec_byte[7:5] == 3'd7 &&
                 (codec_byte[4:0] == 5'd23 || codec_byte[4:0] == 5'd27 ||
                  codec_byte[4:0] == 5'd29 || codec_byte[4:0] == 5'd30))) begin
                codec_data = codec_byte[7:0];
                codec_control = 1'b1;
                codec_encoder_disparity = codec_rd[0];
                codec_decoder_disparity = codec_rd[0];
                #1;
                if (codec_encoder_error || codec_code_error ||
                    codec_disparity_error || codec_decoded_data != codec_data ||
                    !codec_decoded_control ||
                    codec_decoder_disparity_out != codec_encoder_disparity_out)
                    codec_exhaustive_pass = 1'b0;
            end
        end
    end
    check(codec_exhaustive_pass,
          "8b/10b exhaustive data/control round-trip and disparity tracking");
    codec_data = 8'hbc;
    codec_control = 1'b1;
    codec_encoder_disparity = 1'b0;
    codec_decoder_disparity = 1'b0;
    #1;
    check(codec_symbol == K28_5_RD_NEG,
          "8b/10b K28.5 RD- matches the SelectIO serial convention");
    codec_encoder_disparity = 1'b1;
    codec_decoder_disparity = 1'b1;
    #1;
    check(codec_symbol == K28_5_RD_POS,
          "8b/10b K28.5 RD+ matches the SelectIO serial convention");
    codec_decoder_disparity = 1'b0;
    #1;
    check(codec_disparity_error,
          "8b/10b decoder detects a legal code at the wrong disparity");
    codec_data = 8'h00;
    codec_control = 1'b1;
    #1;
    check(codec_encoder_error, "8b/10b encoder rejects an invalid K character");

    repeat (10) @(posedge s_axi_aclk);
    check(phy_reset_n === 1'b0, "PHY is held in reset by default");
    check(mdio_t === 1'b1, "MDIO is released while idle");
    check(gmii_rxd == 8'h00 && !gmii_rx_dv && !gmii_rx_er,
          "pre-packet GMII receive output is quiescent");

    s_axi_aresetn = 1'b1;
    axi_read(12'h000, value);
    check(value == EXPECTED_ID, "AXI core ID");
    axi_read(12'h004, value);
    check(value == EXPECTED_VERSION, "AXI ABI and Stage 3 version");
    axi_read(12'h02c, value);
    check(value == 32'h0000_000f,
          "capabilities advertise MDIO/raw/codec and GMII packets");

    // Exercise independent AXI address/data channels and byte strobes.
    axi_write(12'h060, 32'h1122_3344, 4'hf, 1);
    axi_write(12'h060, 32'haabb_ccdd, 4'b0101, 2);
    axi_read(12'h060, value);
    check(value == 32'h11bb_33dd,
          "AXI accepts independent AW/W channels and byte strobes");
    axi_write(12'h060, 32'h5aa5_c33c, 4'hf, 0);
    axi_read(12'h060, value);
    check(value == 32'h5aa5_c33c, "simultaneous AXI write/readback");
    axi_read(12'hffc, value);
    check(value == 32'd0, "unimplemented AXI register reads as zero");

    // Wait for MMCM lock and count-mode IDELAY availability.
    wait (dut.clocks_ready === 1'b1);
    axi_read(12'h00c, value);
    check(value[8] && !value[7],
          "clock-ready status is set while PHY remains reset");
    check(sgmii_txp === 1'b0 && sgmii_txn === 1'b1,
          "serial transmitter has a deterministic disabled level");

    axi_write(12'h020, 32'd17, 4'hf, 0);
    axi_read(12'h020, value);
    check(value[8:0] == 9'd17, "programmable RX IDELAY register");
    axi_write(12'h020, 32'd511, 4'hf, 0);
    axi_read(12'h020, value);
    check(value[8:0] == 9'd511, "RX IDELAY accepts its maximum count");
    axi_write(12'h020, 32'd0, 4'hf, 0);

    // Speed up simulation: 150 MHz/(2*(1+1)) = 37.5 MHz MDC.
    axi_write(12'h01c, 32'd1, 4'h3, 0);
    axi_read(12'h01c, value);
    check(value[15:0] == 16'd1, "programmable MDC divider");

    // Integrated AXI-to-MDIO Clause 22 write transaction.
    captured_frame = 64'd0;
    mdio_drive_violation = 1'b0;
    fork
        begin
            wait (dut.mdio_busy === 1'b1);
            for (bit_number = 63; bit_number >= 0; bit_number = bit_number - 1) begin
                @(posedge mdio_mdc);
                captured_frame[bit_number] = mdio_o;
                if (mdio_t !== 1'b0) mdio_drive_violation = 1'b1;
            end
        end
        begin
            axi_write(12'h010, (7 << 8) | (1 << 7) | 22, 4'hf, 0);
            axi_write(12'h014, 32'h0000_1234, 4'h3, 0);
            axi_write(12'h008, 32'h0000_0100, 4'hf, 0);
            wait_mdio_done();
        end
    join
    check(!mdio_drive_violation, "MDIO write drives every frame bit");
    check(captured_frame == {32'hffff_ffff, 2'b01, 2'b01,
          5'd7, 5'd22, 2'b10, 16'h1234},
          "complete Clause 22 write frame contents");
    axi_read(12'h00c, value);
    check(value[5] && !value[6] && !value[4],
          "MDIO write reports done without error or busy");

    // Integrated Clause 22 read. The PHY model supplies TA=Z0 and 0xa5c3.
    phy_read_value = 16'ha5c3;
    captured_header = 46'd0;
    mdio_drive_violation = 1'b0;
    axi_write(12'h008, 32'h0000_0200, 4'hf, 0);
    fork
        begin
            wait (dut.mdio_busy === 1'b1);
            for (bit_number = 63; bit_number >= 18; bit_number = bit_number - 1) begin
                @(posedge mdio_mdc);
                captured_header[bit_number-18] = mdio_o;
                if (mdio_t !== 1'b0) mdio_drive_violation = 1'b1;
            end
            @(negedge mdio_mdc);
            phy_mdio_enable = 1'b0;
            @(posedge mdio_mdc);
            check(mdio_t === 1'b1, "MDIO read releases first turnaround bit");
            @(negedge mdio_mdc);
            phy_mdio_enable = 1'b1;
            phy_mdio_drive = 1'b0;
            @(posedge mdio_mdc);
            check(mdio_t === 1'b1, "MDIO read releases second turnaround bit");
            for (bit_number = 15; bit_number >= 0; bit_number = bit_number - 1) begin
                @(negedge mdio_mdc);
                phy_mdio_drive = phy_read_value[bit_number];
                @(posedge mdio_mdc);
                if (mdio_t !== 1'b1) mdio_drive_violation = 1'b1;
            end
            @(negedge mdio_mdc);
            phy_mdio_enable = 1'b0;
        end
        begin
            axi_write(12'h010, (7 << 8) | 3, 4'hf, 0);
            axi_write(12'h008, 32'h0000_0100, 4'hf, 0);
            wait_mdio_done();
        end
    join
    check(!mdio_drive_violation,
          "MDIO read drives header and releases every data bit");
    check(captured_header == {32'hffff_ffff, 2'b01, 2'b10, 5'd7, 5'd3},
          "complete Clause 22 read header contents");
    axi_read(12'h018, value);
    check(value[15:0] == phy_read_value, "Clause 22 read data through AXI");
    axi_read(12'h00c, value);
    check(value[5] && !value[6] && !value[4],
          "MDIO read reports valid turnaround and completion");

    // A PHY that fails to drive the required zero turnaround bit must set
    // the sticky MDIO error indication, which remains visible through AXI.
    axi_write(12'h008, 32'h0000_0200, 4'hf, 0);
    fork
        begin
            wait (dut.mdio_busy === 1'b1);
            repeat (46) @(posedge mdio_mdc);
            @(negedge mdio_mdc);
            phy_mdio_enable = 1'b0;
            @(posedge mdio_mdc);
            @(negedge mdio_mdc);
            phy_mdio_enable = 1'b1;
            phy_mdio_drive = 1'b1;
            @(posedge mdio_mdc);
            for (bit_number = 15; bit_number >= 0; bit_number = bit_number - 1) begin
                @(negedge mdio_mdc);
                phy_mdio_drive = 1'b0;
                @(posedge mdio_mdc);
            end
            @(negedge mdio_mdc);
            phy_mdio_enable = 1'b0;
        end
        begin
            axi_write(12'h010, (7 << 8) | 4, 4'hf, 0);
            axi_write(12'h008, 32'h0000_0100, 4'hf, 0);
        end
    join
    repeat (3) @(posedge s_axi_aclk);
    axi_read(12'h00c, value);
    check(value[6] && value[5] && !value[4],
          "invalid MDIO read turnaround latches an AXI-visible error");
    axi_write(12'h008, 32'h0000_0200, 4'hf, 0);
    axi_read(12'h00c, value);
    check(!value[6] && !value[5], "MDIO clear command clears sticky status");

    // Enable the raw loopback path with a repeated comma test symbol.
    axi_write(12'h008, BASE_CONTROL, 4'hf, 0);
    repeat (200) @(posedge refclk625_p);
    check(phy_reset_n === 1'b1, "AXI control releases PHY reset");
    axi_read(12'h028, value);
    check(value[9:0] == K28_5_RD_NEG, "raw TX diagnostic symbol readback");
    axi_read(12'h030, value);
    check(value > 0, "raw receive word counter advances in loopback");
    axi_read(12'h034, value);
    check(value > 0, "comma detector recognizes repeated K28.5 encoding");
    axi_read(12'h024, value);
    check(is_cyclic_rotation(value[9:0], K28_5_RD_NEG),
          "DDR loopback contains the raw symbol before word alignment");
    check_repeated_comma(K28_5_RD_POS,
                         "comma detector recognizes K28.5 positive disparity");
    check_repeated_comma(K28_1_RD_NEG,
                         "comma detector recognizes K28.1 negative disparity");
    check_repeated_comma(K28_1_RD_POS,
                         "comma detector recognizes K28.1 positive disparity");

    // Restart the receive logic and use the encoded diagnostic transmitter.
    // Alternating K28.5 disparity must acquire and retain symbol sync without
    // accumulating code or disparity errors.
    axi_write(12'h008, 32'd0, 4'hf, 0);
    repeat (100) @(posedge refclk625_p);
    axi_write(12'h044, 32'h0000_01bc, 4'hf, 0);
    axi_write(12'h008, BASE_CONTROL | 32'h0000_0008, 4'hf, 0);
    repeat (1200) @(posedge refclk625_p);
    axi_read(12'h040, value);
    check(value[11] && value[12],
          "comma alignment and valid-code synchronization acquire lock");
    check(value[8] && value[7:0] == 8'hbc,
          "aligned 8b/10b receive path decodes K28.5");
    axi_read(12'h048, value);
    check(value > 32'd16, "aligned decode counter advances");
    axi_read(12'h04c, value);
    check(value == 32'd0, "encoded loopback has no code errors");
    axi_read(12'h050, value);
    check(value == 32'd0, "encoded loopback has no disparity errors");
    axi_read(12'h054, value);
    check(value == 32'd0, "encoded loopback retains synchronization");

    // Four consecutive illegal symbols must force loss of both sync and
    // alignment so a later comma can establish a fresh boundary.
    axi_write(12'h008, 32'h0000_0007, 4'hf, 0);
    repeat (300) @(posedge refclk625_p);
    axi_read(12'h040, value);
    check(!value[11] && !value[12],
          "invalid symbols force loss of alignment and synchronization");
    axi_read(12'h04c, value);
    check(value >= 32'd4, "invalid symbols increment the code-error counter");
    axi_read(12'h054, value);
    check(value == 32'd1, "synchronization loss is counted once");

    // MAC-side counters remain observable even before packet transport exists.
    @(negedge gmii_clk125);
    gmii_tx_en = 1'b1;
    for (bit_number = 0; bit_number < 5; bit_number = bit_number + 1) begin
        gmii_txd = bit_number;
        @(posedge gmii_clk125);
        @(negedge gmii_clk125);
    end
    gmii_tx_en = 1'b0;
    repeat (8) @(posedge s_axi_aclk);
    axi_read(12'h038, value);
    check(value == 32'd5, "GMII transmit byte counter");
    axi_read(12'h03c, value);
    check(value == 32'd1, "GMII transmit frame counter");

    // Select the packet PCS, allow its idle ordered sets to reacquire receive
    // synchronization, and loop a complete GMII frame through both elastic
    // clock crossings and the serial SelectIO path.
    axi_write(12'h008, 32'd0, 4'hf, 0);
    repeat (100) @(posedge refclk625_p);
    axi_write(12'h008, 32'h0000_0017, 4'hf, 0);
    repeat (1600) @(posedge refclk625_p);
    check(dut.rx_synced, "packet PCS idle ordered sets acquire synchronization");

    gmii_rx_count = 0;
    gmii_frame_pass = 1'b1;
    fork
        begin
            wait (gmii_rx_dv === 1'b1);
            while (gmii_rx_dv === 1'b1) begin
                @(negedge gmii_clk125);
                if (gmii_rx_dv) begin
                    if (gmii_rx_er)
                        gmii_frame_pass = 1'b0;
                    if (gmii_rx_count < 7) begin
                        if (gmii_rxd != 8'h55) gmii_frame_pass = 1'b0;
                    end else if (gmii_rx_count == 7) begin
                        if (gmii_rxd != 8'hd5) gmii_frame_pass = 1'b0;
                    end else if (gmii_rxd != gmii_rx_count[7:0]) begin
                        gmii_frame_pass = 1'b0;
                    end
                    gmii_rx_count = gmii_rx_count + 1;
                end
            end
        end
        begin
            @(negedge gmii_clk125);
            gmii_tx_en = 1'b1;
            gmii_tx_er = 1'b0;
            for (gmii_index = 0; gmii_index < 24;
                 gmii_index = gmii_index + 1) begin
                if (gmii_index < 7)
                    gmii_txd = 8'h55;
                else if (gmii_index == 7)
                    gmii_txd = 8'hd5;
                else
                    gmii_txd = gmii_index[7:0];
                @(negedge gmii_clk125);
            end
            gmii_tx_en = 1'b0;
            gmii_txd = 8'd0;
        end
    join
    check(gmii_rx_count == 24,
          "GMII packet loopback preserves frame length");
    check(gmii_frame_pass,
          "GMII packet loopback preserves preamble, SFD, and payload");

    // Reset must return every externally consequential output to safety.
    @(negedge s_axi_aclk);
    s_axi_aresetn = 1'b0;
    repeat (5) @(posedge s_axi_aclk);
    check(phy_reset_n === 1'b0, "reset reasserts external PHY reset");
    check(mdio_t === 1'b1, "reset releases MDIO bus");
    check(gmii_rxd == 8'h00 && !gmii_rx_dv && !gmii_rx_er,
          "reset keeps pre-packet GMII receive quiescent");
    s_axi_aresetn = 1'b1;
    wait (dut.clocks_ready === 1'b1);
    axi_read(12'h00c, value);
    check(value[8] && !value[7],
          "clocking recovers after reset without releasing PHY");
    axi_read(12'h000, value);
    check(value == EXPECTED_ID, "AXI interface recovers after reset");

    if (failures == 0) begin
        $display("OPEN_ETH_SGMII_PCS_PMA_SELFTEST=PASS checks=%0d", checks);
        $finish;
    end
    $fatal(1, "OPEN_ETH_SGMII_PCS_PMA_SELFTEST=FAIL failures=%0d checks=%0d",
           failures, checks);
end

initial begin
    #2_000_000_000;
    $fatal(1, "OPEN_ETH_SGMII_PCS_PMA_SELFTEST=TIMEOUT");
end

endmodule
