# Open Ethernet SGMII PCS/PMA

Vivado VLNV: `GhlHub.org:ethernet:open_eth_sgmii_pcs_pma:1.0`

This core connects GMII to a clock-forwarded SGMII PHY using UltraScale or
UltraScale+ LVDS SelectIO. Set `FPGA_FAMILY` to match the project part before
generating output products.

The external PHY must provide the 625 MHz differential `refclk625` clock. The
core produces `gmii_clk125`. Its serial path remains disabled and
`phy_reset_n` remains asserted after reset until software enables the core and
releases the PHY through AXI4-Lite.

The integrating design must provide package pins, differential I/O standards,
and the timing relationship between the PHY's forwarded clock and receive
data. See [the root documentation](../../docs/sgmii-registers.md) for control
and diagnostic registers.
