# SPDX-License-Identifier: GPL-3.0-or-later
# Out-of-context synthesis checks for both packaged cores.

set repo_dir [file normalize [file join [file dirname [info script]] ..]]
set report_dir [file join $repo_dir build reports]
file mkdir $report_dir

proc synth_mac {repo_dir report_dir part} {
  create_project -in_memory -part $part
  read_verilog -sv [file join $repo_dir ip open_eth_mac_1g hdl open_eth_mac_1g.sv]
  synth_design -mode out_of_context -top open_eth_mac_1g -part $part
  create_clock -name axis_clk -period 6.667 [get_ports axis_clk]
  create_clock -name s_axi_lite_clk -period 6.667 [get_ports s_axi_lite_clk]
  create_clock -name gtx_clk -period 8.000 [get_ports gtx_clk]
  read_xdc [file join $repo_dir ip open_eth_mac_1g xdc open_eth_mac_1g.xdc]
  report_utilization -file [file join $report_dir open_eth_mac_1g_utilization.rpt]
  report_timing_summary -file [file join $report_dir open_eth_mac_1g_timing.rpt]
  close_project
  puts "OPEN_ETH_MAC_1G_SYNTHESIS=PASS part=$part"
}

proc synth_sgmii {repo_dir report_dir part family label} {
  create_project -in_memory -part $part
  read_verilog -sv [list \
    [file join $repo_dir ip open_eth_sgmii_pcs_pma hdl open_eth_8b10b.sv] \
    [file join $repo_dir ip open_eth_sgmii_pcs_pma hdl open_eth_async_fifo.sv] \
    [file join $repo_dir ip open_eth_sgmii_pcs_pma hdl open_eth_mdio_master.sv] \
    [file join $repo_dir ip open_eth_sgmii_pcs_pma hdl open_eth_sgmii_pcs_pma.sv]]
  synth_design -mode out_of_context -top open_eth_sgmii_pcs_pma \
    -part $part -generic FPGA_FAMILY=$family
  create_clock -name s_axi_aclk -period 6.667 [get_ports s_axi_aclk]
  create_clock -name refclk625 -period 1.600 [get_ports refclk625_p]
  read_xdc [file join $repo_dir ip open_eth_sgmii_pcs_pma xdc open_eth_sgmii_pcs_pma.xdc]
  report_utilization -file \
    [file join $report_dir open_eth_sgmii_pcs_pma_${label}_utilization.rpt]
  report_timing_summary -file \
    [file join $report_dir open_eth_sgmii_pcs_pma_${label}_timing.rpt]
  close_project
  puts "OPEN_ETH_SGMII_PCS_PMA_SYNTHESIS=PASS family=$family part=$part"
}

synth_mac $repo_dir $report_dir xcvu095-ffva2104-2-e
synth_sgmii $repo_dir $report_dir xcvu095-ffva2104-2-e ULTRASCALE ultrascale
synth_sgmii $repo_dir $report_dir xcku5p-ffvb676-2-e ULTRASCALE_PLUS ultrascale_plus
exit
