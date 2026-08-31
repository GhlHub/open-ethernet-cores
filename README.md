# Open Ethernet Cores

Open Ethernet Cores provides two independently packaged Vivado IP cores for a
fixed-speed 1 Gb/s Ethernet link:

| IP core | VLNV | Function |
| --- | --- | --- |
| Open Ethernet 1G MAC | `GhlHub.org:ethernet:open_eth_mac_1g:1.0` | AXI4-Stream packet interface, AXI4-Lite control, and GMII |
| Open Ethernet SGMII PCS/PMA | `GhlHub.org:ethernet:open_eth_sgmii_pcs_pma:1.0` | GMII to clock-forwarded SGMII over LVDS SelectIO |

The cores were extracted from the hardware-tested VCU108 Ethernet design in
[`GhlHub/versal_miners`](https://github.com/GhlHub/versal_miners). They can be
used together through their Vivado GMII interfaces or independently.

## Capabilities

The MAC is a fixed 1 Gb/s, full-duplex, store-and-forward implementation. It
adds and checks Ethernet FCS, pads short transmitted frames, filters receive
traffic by station/broadcast/multicast address, and rejects bad-FCS, runt,
errored, and oversized receive frames. Its four 32-bit AXI4-Stream channels
implement the data/control and data/status subset used by AMD AXI Ethernet
with AXI DMA. Circular packet queues share the complete 4 KiB TX and 16 KiB RX
BRAM capacities among queued frames; eight TX descriptors and sixteen RX
descriptors allow AXI and GMII to process different packets concurrently.

The SGMII core implements the 8b/10b PCS, comma alignment, running disparity,
clock-domain elastic buffers, Clause 22 MDIO master, programmable receive
delay, and an LVDS SelectIO PMA. It expects the external PHY to supply the
625 MHz forwarded clock used by clock-forwarded SGMII. The core produces a
125 MHz GMII clock for the MAC.

The SGMII customization parameter `FPGA_FAMILY` has two values:

- `ULTRASCALE` instantiates `MMCME3_ADV` and UltraScale SelectIO models.
- `ULTRASCALE_PLUS` instantiates `MMCME4_ADV` and UltraScale+ SelectIO models.

The selection controls elaborated RTL, not just simulation metadata. Both
configurations are covered by out-of-context synthesis regression tests.

## Known limits

- Only 1 Gb/s full-duplex packet operation is implemented.
- 10/100 Mb/s SGMII symbol replication is not implemented.
- In-core SGMII auto-negotiation is not implemented. Configure the external
  PHY's SGMII side for fixed 1 Gb/s full duplex.
- The PMA requires a clock-forwarded LVDS SGMII connection. It is not a GT
  transceiver wrapper.
- Board pin assignments, I/O standards, and PHY-specific timing constraints
  must be supplied by the integrating design.

## Using the Vivado IP repository

Add the repository's `ip` directory to the project:

```tcl
set_property ip_repo_paths /path/to/open-ethernet-cores/ip [current_project]
update_ip_catalog
```

Both cores then appear under **Communication & Networking / Ethernet** in the
IP catalog. Select the FPGA architecture in the SGMII core customization GUI
before generating output products.

## Development

Vivado must be available as `vivado`, or supplied through `VIVADO`:

```sh
make test
make synth
make package
```

`make test` runs the self-checking MAC and PCS/PMA XSim regressions. `make
synth` checks the MAC plus the SGMII implementation on UltraScale and
UltraScale+ parts. `make package` regenerates the checked-in `component.xml`
and XGUI files.

See [MAC registers](docs/mac-registers.md) and [SGMII registers](docs/sgmii-registers.md)
for the software-visible interfaces.

## License

GPL-3.0-or-later. See [LICENSE](LICENSE).
