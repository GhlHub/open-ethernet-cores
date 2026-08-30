# SPDX-License-Identifier: GPL-3.0-or-later
# Internal implementation constraints for the open SGMII PCS/PMA. Pin
# assignments, I/O standards, and PHY-specific input/output delays belong in
# the board design that instantiates this IP.

# ISERDESE3/OSERDESE3 impose a maximum insertion-delay skew between CLK and
# CLKDIV. Keep their related global clock routes matched.
set open_eth_sgmii_serdes_clock_nets [get_nets -quiet -hierarchical -regexp \
  {(^|.*/)(clk625|clk156)$}]
set_property CLOCK_DELAY_GROUP OPEN_ETH_SGMII_SERDES \
  $open_eth_sgmii_serdes_clock_nets

# Cut only the asynchronous source-to-first-stage portion of each explicit
# synchronizer. Paths between synchronizer stages remain timed.
set open_eth_sgmii_cdc_first_d [get_pins -quiet -hierarchical -regexp \
  {(^|.*/)(ready_(156|axi|gmii)_sync_reg\[0\]|delay_toggle_sync_reg\[0\]|delay_value_sync_reg\[[0-9]+\]|core_enable_(serdes|gmii)_sync_reg\[0\]|packet_mode_(serdes|gmii)_sync_reg\[0\]|tx_enable_sync_reg\[0\]|tx_codec_mode_sync_reg\[0\]|tx_symbol_meta_reg\[[0-9]+\]|tx_code_meta_reg\[[0-9]+\]|rx_raw_meta_reg\[[0-9]+\]|rx_toggle_sync_reg\[0\]|comma_sync_reg\[0\]|rx_count_meta_reg\[[0-9]+\]|comma_count_meta_reg\[[0-9]+\]|tx_bytes_meta_reg\[[0-9]+\]|tx_frames_meta_reg\[[0-9]+\]|pcs_status_meta_reg\[[0-9]+\]|decoded_count_meta_reg\[[0-9]+\]|code_error_meta_reg\[[0-9]+\]|disparity_error_meta_reg\[[0-9]+\]|sync_loss_meta_reg\[[0-9]+\]|aligned_symbol_meta_reg\[[0-9]+\]|fifo_status_meta_reg\[[0-9]+\])/D$}]
set_false_path -to $open_eth_sgmii_cdc_first_d

# The packet elastic buffers use Gray pointers and show-ahead distributed RAM.
set open_eth_sgmii_fifo_pointer_meta_d [get_pins -quiet -hierarchical -regexp \
  {(^|.*/)(tx|rx)_gmii_fifo/(rd_gray_wr_meta_reg|wr_gray_rd_meta_reg)\[[0-9]+\]/D$}]
set_false_path -to $open_eth_sgmii_fifo_pointer_meta_d
