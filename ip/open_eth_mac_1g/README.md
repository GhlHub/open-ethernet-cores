# Open Ethernet 1G MAC

Vivado VLNV: `GhlHub.org:ethernet:open_eth_mac_1g:1.0`

This core is a fixed 1 Gb/s full-duplex Ethernet MAC with a GMII PHY-side
interface. Packet traffic uses the four-channel, 32-bit AXI4-Stream contract
used by AMD AXI Ethernet and AXI DMA. AXI4-Lite provides compatible control,
address-filter, interrupt, and statistics registers.

Required clocks are 150 MHz for `axis_clk` and `s_axi_lite_clk`, and 125 MHz
for `gtx_clk`. Assert all active-low resets until their respective clocks are
stable. Tie `clk_en` high for continuous 1 Gb/s operation.

The MAC has a 4 KiB transmit packet buffer and a 16 KiB receive packet buffer.
It accepts Ethernet payloads up to 1518 bytes after stripping the receive FCS.
See [the root documentation](../../docs/mac-registers.md) for registers and
limitations.
