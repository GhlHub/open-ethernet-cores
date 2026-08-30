# SPDX-License-Identifier: GPL-3.0-or-later
# Behavioral XSim regressions for the MAC and SGMII PCS/PMA.

set repo_dir [file normalize [file join [file dirname [info script]] ..]]
set build_dir [file join $repo_dir build simulation]
file mkdir $build_dir

proc run_test {repo_dir build_dir name part sources testbench pass_marker} {
  set project_dir [file join $build_dir $name]
  create_project -force $name $project_dir -part $part
  set_property target_simulator XSim [current_project]
  add_files -norecurse $sources
  add_files -fileset sim_1 -norecurse $testbench
  set_property top tb_$name [get_filesets sim_1]
  set_property xsim.simulate.runtime all [get_filesets sim_1]
  update_compile_order -fileset sources_1
  update_compile_order -fileset sim_1
  launch_simulation
  run all
  set log_path [file join $project_dir $name.sim sim_1 behav xsim simulate.log]
  set log_file [open $log_path r]
  set log_contents [read $log_file]
  close $log_file
  if {[string first $pass_marker $log_contents] < 0} {
    error "$name did not report '$pass_marker'; inspect $log_path"
  }
  close_sim
  close_project
  puts "[string toupper $name]_XSIM=PASS"
}

run_test $repo_dir $build_dir open_eth_mac_1g xcvu095-ffva2104-2-e \
  [list [file join $repo_dir ip open_eth_mac_1g hdl open_eth_mac_1g.sv]] \
  [file join $repo_dir tests tb_open_eth_mac_1g.sv] \
  {PASS: AXI Ethernet replacement TX/RX/filter test}

run_test $repo_dir $build_dir open_eth_sgmii_pcs_pma xcvu095-ffva2104-2-e \
  [list \
    [file join $repo_dir ip open_eth_sgmii_pcs_pma hdl open_eth_8b10b.sv] \
    [file join $repo_dir ip open_eth_sgmii_pcs_pma hdl open_eth_async_fifo.sv] \
    [file join $repo_dir ip open_eth_sgmii_pcs_pma hdl open_eth_mdio_master.sv] \
    [file join $repo_dir ip open_eth_sgmii_pcs_pma hdl open_eth_sgmii_pcs_pma.sv]] \
  [file join $repo_dir tests tb_open_eth_sgmii_pcs_pma.sv] \
  {OPEN_ETH_SGMII_PCS_PMA_SELFTEST=PASS}
exit
