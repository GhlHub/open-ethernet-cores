// SPDX-License-Identifier: GPL-3.0-or-later
`timescale 1ns/1ps
module tb_open_eth_mac_1g;
reg axis_clk=0, gtx_clk=0;
always #3.333 axis_clk = ~axis_clk;
always #4 gtx_clk = ~gtx_clk;
reg resetn=0;
reg [31:0] txd_data=0, txc_data=0;
reg [3:0] txd_keep=0, txc_keep=4'hf;
reg txd_last=0, txd_valid=0, txc_last=0, txc_valid=0;
wire txd_ready, txc_ready;
wire [31:0] rxd_data, rxs_data;
wire [3:0] rxd_keep, rxs_keep;
wire rxd_last, rxd_valid, rxs_last, rxs_valid;
reg rxd_ready=1, rxs_ready=1;
reg [17:0] awaddr=0, araddr=0;
reg awvalid=0, wvalid=0, bready=1, arvalid=0, rready=1;
reg [31:0] wdata=0; reg [3:0] wstrb=4'hf;
wire awready,wready,bvalid,arready,rvalid; wire [1:0] bresp,rresp; wire [31:0] rdata;
reg [7:0] gmii_rxd=0; reg gmii_rx_dv=0, gmii_rx_er=0;
wire [7:0] gmii_txd; wire gmii_tx_en,gmii_tx_er,interrupt,mac_irq;

open_eth_mac_1g dut (
 .axis_clk(axis_clk),.s_axi_lite_clk(axis_clk),.gtx_clk(gtx_clk),.clk_en(1'b1),
 .axi_txd_arstn(resetn),.axi_txc_arstn(resetn),.axi_rxd_arstn(resetn),
 .axi_rxs_arstn(resetn),.s_axi_lite_resetn(resetn),
 .s_axis_txd_tdata(txd_data),.s_axis_txd_tkeep(txd_keep),.s_axis_txd_tlast(txd_last),
 .s_axis_txd_tvalid(txd_valid),.s_axis_txd_tready(txd_ready),
 .s_axis_txc_tdata(txc_data),.s_axis_txc_tkeep(txc_keep),.s_axis_txc_tlast(txc_last),
 .s_axis_txc_tvalid(txc_valid),.s_axis_txc_tready(txc_ready),
 .m_axis_rxd_tdata(rxd_data),.m_axis_rxd_tkeep(rxd_keep),.m_axis_rxd_tlast(rxd_last),
 .m_axis_rxd_tvalid(rxd_valid),.m_axis_rxd_tready(rxd_ready),
 .m_axis_rxs_tdata(rxs_data),.m_axis_rxs_tkeep(rxs_keep),.m_axis_rxs_tlast(rxs_last),
 .m_axis_rxs_tvalid(rxs_valid),.m_axis_rxs_tready(rxs_ready),
 .s_axi_awaddr(awaddr),.s_axi_awvalid(awvalid),.s_axi_awready(awready),
 .s_axi_wdata(wdata),.s_axi_wstrb(wstrb),.s_axi_wvalid(wvalid),.s_axi_wready(wready),
 .s_axi_bresp(bresp),.s_axi_bvalid(bvalid),.s_axi_bready(bready),
 .s_axi_araddr(araddr),.s_axi_arvalid(arvalid),.s_axi_arready(arready),
 .s_axi_rdata(rdata),.s_axi_rresp(rresp),.s_axi_rvalid(rvalid),.s_axi_rready(rready),
 .gmii_rxd(gmii_rxd),.gmii_rx_dv(gmii_rx_dv),.gmii_rx_er(gmii_rx_er),
 .gmii_txd(gmii_txd),.gmii_tx_en(gmii_tx_en),.gmii_tx_er(gmii_tx_er),
 .interrupt(interrupt),.mac_irq(mac_irq));

integer errors=0, i, tx_cap_count=0, rx_cap_count=0, status_count=0;
reg [7:0] tx_capture[0:5000], rx_capture[0:20000];
reg [31:0] status_capture[0:5];
reg rx_store_forward_violation=0;
reg tx_frame_active=0;
reg [31:0] tx_check_crc;

function automatic [31:0] crc_byte(input [31:0] crc,input [7:0] data);
 integer j; reg [31:0] c;
 begin c=crc; for(j=0;j<8;j=j+1) c=(c[0]^data[j])?((c>>1)^32'hedb88320):(c>>1); crc_byte=c; end
endfunction

always @(posedge gtx_clk) begin
 if (gmii_tx_en) begin
  tx_frame_active=1;
  tx_capture[tx_cap_count]=gmii_txd; tx_cap_count=tx_cap_count+1;
  if (gmii_tx_er) begin $display("ERROR: TX_ER asserted"); errors=errors+1; end
 end else if (tx_frame_active) begin
  if (tx_cap_count!=72) begin $display("ERROR: GMII bubble at byte %0d",tx_cap_count); errors=errors+1; end
  tx_frame_active=0;
 end
end
always @(posedge axis_clk) begin
 if (rxd_valid && rxd_ready) begin
   for (i=0;i<4;i=i+1) if(rxd_keep[i]) begin
     rx_capture[rx_cap_count]=rxd_data[i*8 +: 8]; rx_cap_count=rx_cap_count+1;
   end
   if (gmii_rx_dv) rx_store_forward_violation=1;
 end
 if (rxs_valid && rxs_ready) begin
   if(status_count<6) status_capture[status_count]=rxs_data;
   status_count=status_count+1;
   if (gmii_rx_dv) rx_store_forward_violation=1;
 end
end

task automatic axi_write(input [17:0] addr,input [31:0] value);
 begin
  @(posedge axis_clk); awaddr<=addr; awvalid<=1; wdata<=value; wvalid<=1;
  while(!(awready&&awvalid)) @(posedge axis_clk); awvalid<=0;
  while(!(wready&&wvalid)) @(posedge axis_clk); wvalid<=0;
  while(!bvalid) @(posedge axis_clk); @(posedge axis_clk);
 end
endtask

task automatic send_control;
 begin
  for(i=0;i<6;i=i+1) begin
   @(posedge axis_clk); txc_data <= (i==0)?32'ha0000000:0; txc_last <= (i==5); txc_valid<=1;
   while(!txc_ready) @(posedge axis_clk);
  end
  @(posedge axis_clk); txc_valid<=0; txc_last<=0;
 end
endtask

task automatic send_tx_frame(input integer length);
 integer p,n,lane; reg [31:0] word; reg [3:0] keep;
 begin
  send_control(); p=0;
  while(p<length) begin
   word=0; keep=0;
   for(lane=0;lane<4;lane=lane+1) if(p+lane<length) begin word[lane*8 +: 8]=(p+lane); keep[lane]=1; end
   @(posedge axis_clk); txd_data<=word; txd_keep<=keep; txd_last<=(p+4>=length); txd_valid<=1;
   while(!txd_ready) @(posedge axis_clk);
   if (gmii_tx_en) begin $display("ERROR: GMII started before TX TLAST"); errors=errors+1; end
   p=p+4;
  end
  @(posedge axis_clk); txd_valid<=0; txd_last<=0; txd_keep<=0;
 end
endtask

reg [7:0] frame[0:16383];
task automatic make_frame(input [47:0] dst,input integer length);
 reg [31:0] crc; integer k;
 begin
  frame[0]=dst[47:40]; frame[1]=dst[39:32]; frame[2]=dst[31:24];
  frame[3]=dst[23:16]; frame[4]=dst[15:8]; frame[5]=dst[7:0];
  frame[6]=8'h02; frame[7]=8'h10; frame[8]=8'h20; frame[9]=8'h30; frame[10]=8'h40; frame[11]=8'h50;
  frame[12]=8'h08; frame[13]=8'h00;
  for(k=14;k<length;k=k+1) frame[k]=k^8'h5a;
  crc=32'hffffffff; for(k=0;k<length;k=k+1) crc=crc_byte(crc,frame[k]); crc=~crc;
  frame[length]=crc[7:0]; frame[length+1]=crc[15:8]; frame[length+2]=crc[23:16]; frame[length+3]=crc[31:24];
 end
endtask

task automatic send_rx_frame(input [47:0] dst,input integer length);
 integer k;
 begin
  make_frame(dst,length);
  @(posedge gtx_clk); gmii_rx_dv<=1;
  for(k=0;k<7;k=k+1) begin gmii_rxd<=8'h55; @(posedge gtx_clk); end
  gmii_rxd<=8'hd5; @(posedge gtx_clk);
  for(k=0;k<length+4;k=k+1) begin gmii_rxd<=frame[k]; @(posedge gtx_clk); end
  gmii_rx_dv<=0; gmii_rxd<=0; @(posedge gtx_clk);
 end
endtask

task automatic send_rx_bad_fcs(input [47:0] dst,input integer length);
 integer k;
 begin
  make_frame(dst,length);
  frame[length+3]=frame[length+3]^8'h01;
  @(posedge gtx_clk); gmii_rx_dv<=1;
  for(k=0;k<7;k=k+1) begin gmii_rxd<=8'h55; @(posedge gtx_clk); end
  gmii_rxd<=8'hd5; @(posedge gtx_clk);
  for(k=0;k<length+4;k=k+1) begin gmii_rxd<=frame[k]; @(posedge gtx_clk); end
  gmii_rx_dv<=0; gmii_rxd<=0; @(posedge gtx_clk);
 end
endtask

task automatic send_rx_gmii_error(input [47:0] dst,input integer length);
 integer k;
 begin
  make_frame(dst,length);
  @(posedge gtx_clk); gmii_rx_dv<=1;
  for(k=0;k<7;k=k+1) begin gmii_rxd<=8'h55; @(posedge gtx_clk); end
  gmii_rxd<=8'hd5; @(posedge gtx_clk);
  for(k=0;k<length+4;k=k+1) begin
   gmii_rxd<=frame[k]; gmii_rx_er<=(k==20); @(posedge gtx_clk);
  end
  gmii_rx_dv<=0; gmii_rx_er<=0; gmii_rxd<=0; @(posedge gtx_clk);
 end
endtask

task automatic wait_rx(input integer expected);
 integer timeout;
 begin
  timeout=0; while((rx_cap_count<expected || status_count<6) && timeout<10000) begin @(posedge axis_clk); timeout=timeout+1; end
  if(timeout>=10000) begin
   $display("ERROR: RX timeout data=%0d status=%0d state=%0d done=%0b/%0b ack=%0b/%0b active=%0b len=%0d",
    rx_cap_count,status_count,dut.rx_state,
    dut.rx_done_toggle,dut.rx_done_seen,dut.rx_ack_toggle_axis,dut.rx_ack_sync[1],
    dut.rx_axis_active,dut.rx_length_gmii);
   errors=errors+1;
  end
 end
endtask

task automatic clear_rx_capture;
 begin rx_cap_count=0; status_count=0; rx_store_forward_violation=0; repeat(20) @(posedge axis_clk); end
endtask

initial begin
 repeat(8) @(posedge axis_clk); resetn<=1; repeat(5) @(posedge axis_clk);
 // Station address 02:00:00:00:00:01 in Xilinx byte ordering.
 axi_write(18'h00700,32'h00000002); axi_write(18'h00704,32'h00000100);
 axi_write(18'h00408,32'h10000000); axi_write(18'h00404,32'h12000000);

 send_tx_frame(20);
 while(tx_cap_count<72) @(posedge gtx_clk);
 if(tx_capture[0]!==8'h55 || tx_capture[7]!==8'hd5) begin $display("ERROR: TX preamble"); errors=errors+1; end
 for(i=0;i<20;i=i+1) if(tx_capture[8+i]!==i[7:0]) begin $display("ERROR: TX byte %0d",i); errors=errors+1; end
 for(i=28;i<68;i=i+1) if(tx_capture[i]!==0) begin $display("ERROR: TX padding %0d",i); errors=errors+1; end
 tx_check_crc=32'hffffffff;
 for(i=8;i<68;i=i+1) tx_check_crc=crc_byte(tx_check_crc,tx_capture[i]);
 tx_check_crc=~tx_check_crc;
 for(i=0;i<4;i=i+1) if(tx_capture[68+i]!==tx_check_crc[i*8 +: 8]) begin
   $display("ERROR: TX FCS byte %0d",i); errors=errors+1;
 end

 clear_rx_capture();
 send_rx_frame(48'h020000000001,60); wait_rx(60);
 if(rx_store_forward_violation) begin $display("ERROR: RX streamed before end of GMII frame"); errors=errors+1; end
 for(i=0;i<60;i=i+1) if(rx_capture[i]!==frame[i]) begin $display("ERROR: RX station byte %0d",i); errors=errors+1; end
 if(status_capture[0]!==32'h50000000 || status_capture[5][13:0]!==60 || !status_capture[3][6]) begin
   $display("ERROR: RX status %08x %08x %08x",status_capture[0],status_capture[3],status_capture[5]); errors=errors+1;
 end

 clear_rx_capture(); send_rx_frame(48'hffffffffffff,60); wait_rx(60);
 if(!status_capture[3][9]) begin $display("ERROR: broadcast flag"); errors=errors+1; end
 clear_rx_capture(); send_rx_frame(48'h01005e000001,60); wait_rx(60);
 if(!status_capture[3][10]) begin $display("ERROR: multicast flag"); errors=errors+1; end
 clear_rx_capture(); send_rx_frame(48'h001122334455,60); repeat(200) @(posedge axis_clk);
 if(rx_cap_count!=0 || status_count!=0) begin $display("ERROR: foreign unicast forwarded"); errors=errors+1; end
 clear_rx_capture(); send_rx_bad_fcs(48'h020000000001,60); repeat(200) @(posedge axis_clk);
 if(rx_cap_count!=0 || status_count!=0) begin $display("ERROR: bad-FCS frame forwarded"); errors=errors+1; end
 clear_rx_capture(); send_rx_gmii_error(48'h020000000001,60); repeat(200) @(posedge axis_clk);
 if(rx_cap_count!=0 || status_count!=0) begin $display("ERROR: GMII-error frame forwarded"); errors=errors+1; end
 clear_rx_capture(); send_rx_frame(48'h020000000001,40); repeat(200) @(posedge axis_clk);
 if(rx_cap_count!=0 || status_count!=0) begin $display("ERROR: runt frame forwarded"); errors=errors+1; end
 clear_rx_capture(); send_rx_frame(48'h020000000001,1518); wait_rx(1518);
 if(rx_cap_count!=1518 || status_capture[5][13:0]!=1518) begin $display("ERROR: maximum frame rejected or truncated"); errors=errors+1; end
 if(rx_store_forward_violation) begin $display("ERROR: maximum RX frame streamed before GMII completion"); errors=errors+1; end
 clear_rx_capture(); send_rx_frame(48'h020000000001,1519); repeat(200) @(posedge axis_clk);
 if(rx_cap_count!=0 || status_count!=0) begin $display("ERROR: oversized frame forwarded"); errors=errors+1; end

 if(errors==0) $display("PASS: AXI Ethernet replacement TX/RX/filter test");
 else $display("FAIL: %0d errors",errors);
 $finish(errors!=0);
end
endmodule
