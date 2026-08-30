# SPDX-License-Identifier: GPL-3.0-or-later
# The open MAC crosses complete packets between the independent 150 MHz AXI
# and 125 MHz GMII domains. Toggle handshakes guard bundled frame metadata;
# RX frame metadata is held stable until the destination acknowledges it.
set mac_cdc_first_d [get_pins -quiet -hierarchical -regexp \
  {(^|.*/)(gtx_tx_reset_sync_reg\[0\]|gtx_rx_reset_sync_reg\[0\]|tx_ack_sync_reg\[0\]|tx_request_sync_reg\[0\]|tx_enable_sync_reg\[0\]|rx_ack_sync_reg\[0\]|rx_enable_sync_reg\[0\]|rx_done_sync_reg\[0\]|station_mac_meta_reg\[[0-9]+\]|rx_promiscuous_sync_reg\[0\]|rx_byte_count_meta_reg\[[0-9]+\]|tx_byte_count_meta_reg\[[0-9]+\]|rx_frame_count_meta_reg\[[0-9]+\]|rx_fcs_error_count_meta_reg\[[0-9]+\]|rx_broadcast_count_meta_reg\[[0-9]+\]|rx_multicast_count_meta_reg\[[0-9]+\]|tx_frame_count_meta_reg\[[0-9]+\]|rx_filter_drop_meta_reg\[[0-9]+\]|rx_overflow_meta_reg\[[0-9]+\])/D$}]
set_false_path -to $mac_cdc_first_d

# These buses are held unchanged by the source until the synchronized toggle
# has been observed and the destination captures them two clocks later.
set mac_bundled_capture_d [get_pins -quiet -hierarchical -regexp \
  {(^|.*/)(tx_length_gmii_reg\[[0-9]+\]|rx_length_axis_reg\[[0-9]+\]|rx_status3_axis_reg\[[0-9]+\]|rx_destination_axis_reg\[[0-9]+\]|rx_multicast_axis_reg)/D$}]
set_false_path -to $mac_bundled_capture_d
