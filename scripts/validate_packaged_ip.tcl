# SPDX-License-Identifier: GPL-3.0-or-later
# Instantiate the checked-in IP catalog entries and synthesize generated output
# products for both selectable SGMII architectures.

set repo_dir [file normalize [file join [file dirname [info script]] ..]]
set build_dir [file join $repo_dir build packaged_ip_validation]
file mkdir $build_dir

proc validate_sgmii {repo_dir build_dir label part family} {
  set project_dir [file join $build_dir $label]
  create_project -force validate_$label $project_dir -part $part
  set_property ip_repo_paths [file join $repo_dir ip] [current_project]
  update_ip_catalog

  set sgmii_name sgmii_$label
  create_ip -vlnv GhlHub.org:ethernet:open_eth_sgmii_pcs_pma:1.0 \
    -module_name $sgmii_name
  set_property -dict [list CONFIG.FPGA_FAMILY $family] [get_ips $sgmii_name]
  if {[get_property CONFIG.FPGA_FAMILY [get_ips $sgmii_name]] ne $family} {
    error "FPGA_FAMILY customization did not persist for $sgmii_name"
  }
  generate_target all [get_ips $sgmii_name]
  synth_design -top $sgmii_name -part $part -mode out_of_context
  set expected_mmcm [expr {$family eq "ULTRASCALE" ? \
    "MMCME3_ADV" : "MMCME4_ADV"}]
  if {[llength [get_cells -quiet -hierarchical -filter \
      "REF_NAME == $expected_mmcm"]] != 1} {
    error "$sgmii_name did not synthesize exactly one $expected_mmcm"
  }
  close_design

  puts "OPEN_ETH_PACKAGED_IP=PASS family=$family part=$part"
  close_project
}

proc validate_mac {repo_dir build_dir part} {
  set project_dir [file join $build_dir mac]
  create_project -force validate_mac $project_dir -part $part
  set_property ip_repo_paths [file join $repo_dir ip] [current_project]
  update_ip_catalog
  create_ip -vlnv GhlHub.org:ethernet:open_eth_mac_1g:1.0 \
    -module_name mac_packaged
  generate_target all [get_ips mac_packaged]
  synth_design -top mac_packaged -part $part -mode out_of_context
  close_design
  puts "OPEN_ETH_PACKAGED_MAC=PASS part=$part"
  close_project
}

validate_mac $repo_dir $build_dir xcvu095-ffva2104-2-e
validate_sgmii $repo_dir $build_dir ultrascale xcvu095-ffva2104-2-e \
  ULTRASCALE
validate_sgmii $repo_dir $build_dir ultrascale_plus xcku5p-ffvb676-2-e \
  ULTRASCALE_PLUS
exit
