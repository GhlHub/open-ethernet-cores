# SPDX-License-Identifier: GPL-3.0-or-later
# The open MAC crosses complete packets between the independent 150 MHz AXI
# and 125 MHz GMII domains. Gray-coded ring pointers announce committed packet
# descriptors and reclaimed data-buffer space. Descriptor metadata remains
# stable from publication until the destination advances its read pointer.
set mac_cdc_first_d [get_pins -quiet -hierarchical -regexp \
  {(^|.*/)(gtx_tx_reset_sync_reg\[0\]|gtx_rx_reset_sync_reg\[0\]|tx_enable_sync_reg\[0\]|rx_enable_sync_reg\[0\]|station_mac_meta_reg\[[0-9]+\]|rx_promiscuous_sync_reg\[0\]|snapshot_request_sync_reg\[0\]|snapshot_ack_sync_reg\[0\]|tx_data_rd_gray_sync1_reg\[[0-9]+\]|tx_desc_rd_gray_sync1_reg\[[0-9]+\]|tx_desc_wr_gray_sync1_reg\[[0-9]+\]|rx_data_rd_gray_sync1_reg\[[0-9]+\]|rx_desc_rd_gray_sync1_reg\[[0-9]+\]|rx_desc_wr_gray_sync1_reg\[[0-9]+\])/D$}]
set_false_path -to $mac_cdc_first_d

# These descriptor fields are held unchanged by the source until a synchronized
# Gray pointer announces the entry and the destination eventually consumes it.
set mac_bundled_capture_d [get_pins -quiet -hierarchical -regexp \
  {(^|.*/)(tx_start_gmii_reg\[[0-9]+\]|tx_length_gmii_reg\[[0-9]+\]|rx_start_axis_reg\[[0-9]+\]|rx_words_axis_reg\[[0-9]+\]|rx_length_axis_reg\[[0-9]+\]|rx_status3_axis_reg\[[0-9]+\]|rx_destination_axis_reg\[[0-9]+\]|rx_multicast_axis_reg)/D$}]
set_false_path -to $mac_bundled_capture_d

# The requested counter selector is stable before the synchronized request is
# observed. The resulting source snapshot is stable before snapshot_ack crosses
# two synchronizer stages and AXI captures it as read data.
set mac_snapshot_select_regs [get_cells -quiet -hierarchical -regexp \
  {(^|.*/)snapshot_select_reg\[[0-9]+\]$}]
set mac_snapshot_source_regs [get_cells -quiet -hierarchical -regexp \
  {(^|.*/)snapshot_value_reg\[[0-9]+\]$}]
set mac_snapshot_capture_regs [get_cells -quiet -hierarchical -regexp \
  {(^|.*/)s_axi_rdata_reg\[[0-9]+\]$}]
set_false_path -from $mac_snapshot_select_regs -to $mac_snapshot_source_regs
set_false_path -from $mac_snapshot_source_regs -to $mac_snapshot_capture_regs
