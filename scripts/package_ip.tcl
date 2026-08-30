# SPDX-License-Identifier: GPL-3.0-or-later
# Generate Vivado component.xml and XGUI metadata for both cores.

set repo_dir [file normalize [file join [file dirname [info script]] ..]]
set build_dir [file join $repo_dir build packaging]
file mkdir $build_dir

proc package_core {repo_dir build_dir core_name top part sources xdc_file \
                   display_name description} {
  set core_dir [file join $repo_dir ip $core_name]
  set project_dir [file join $build_dir $core_name]
  file delete -force $project_dir [file join $core_dir component.xml] \
    [file join $core_dir xgui]

  create_project package_$core_name $project_dir -part $part -force
  set_property target_language Verilog [current_project]
  add_files -norecurse $sources
  set_property top $top [current_fileset]
  add_files -fileset constrs_1 -norecurse $xdc_file
  set_property USED_IN {implementation} [get_files $xdc_file]
  set_property PROCESSING_ORDER LATE [get_files $xdc_file]
  update_compile_order -fileset sources_1

  ipx::package_project -root_dir $core_dir -vendor GhlHub.org \
    -library ethernet -taxonomy /Communication_&_Networking/Ethernet \
    -set_current true
  set core [ipx::current_core]
  set_property name $core_name $core
  set_property version 1.0 $core
  set_property display_name $display_name $core
  set_property description $description $core
  set_property vendor_display_name {GhlHub} $core
  set_property company_url \
    {https://github.com/GhlHub/open-ethernet-cores} $core
  if {$core_name eq "open_eth_sgmii_pcs_pma"} {
    set family_param [ipx::get_user_parameters FPGA_FAMILY -of_objects $core]
    set_property display_name {FPGA architecture} $family_param
    set_property description \
      {Selects architecture-correct MMCM and SelectIO primitives} $family_param
    set_property value_validation_type list $family_param
    set_property value_validation_list \
      {ULTRASCALE ULTRASCALE_PLUS} $family_param
  }

  ipx::create_xgui_files $core
  # Vivado emits two trailing blank lines in generated XGUI Tcl. Normalize the
  # file so regenerated metadata remains clean under git diff --check.
  set xgui_file [file join $core_dir xgui ${core_name}_v1_0.tcl]
  set xgui_handle [open $xgui_file r]
  set xgui_contents [read $xgui_handle]
  close $xgui_handle
  set xgui_handle [open $xgui_file w]
  puts $xgui_handle [string trimright $xgui_contents]
  close $xgui_handle
  ipx::update_checksums $core
  ipx::save_core $core
  set integrity [ipx::check_integrity -quiet $core]
  puts "OPEN_ETH_IP_PACKAGE=$core_name integrity=$integrity"
  close_project
}

package_core $repo_dir $build_dir open_eth_mac_1g open_eth_mac_1g \
  xcvu095-ffva2104-2-e \
  [list [file join $repo_dir ip open_eth_mac_1g hdl open_eth_mac_1g.sv]] \
  [file join $repo_dir ip open_eth_mac_1g xdc open_eth_mac_1g.xdc] \
  {Open Ethernet 1G MAC} \
  {1 Gb/s full-duplex AXI-Stream Ethernet MAC with GMII and AXI4-Lite control}

package_core $repo_dir $build_dir open_eth_sgmii_pcs_pma \
  open_eth_sgmii_pcs_pma xcvu095-ffva2104-2-e \
  [list \
    [file join $repo_dir ip open_eth_sgmii_pcs_pma hdl open_eth_8b10b.sv] \
    [file join $repo_dir ip open_eth_sgmii_pcs_pma hdl open_eth_async_fifo.sv] \
    [file join $repo_dir ip open_eth_sgmii_pcs_pma hdl open_eth_mdio_master.sv] \
    [file join $repo_dir ip open_eth_sgmii_pcs_pma hdl open_eth_sgmii_pcs_pma.sv]] \
  [file join $repo_dir ip open_eth_sgmii_pcs_pma xdc open_eth_sgmii_pcs_pma.xdc] \
  {Open Ethernet SGMII PCS/PMA} \
  {1 Gb/s SGMII/1000BASE-X PCS/PMA over LVDS SelectIO for UltraScale and UltraScale+}
exit
