# 1G MAC registers

The MAC implements the subset of AMD AXI Ethernet registers needed by the
no-checksum-offload AXI DMA data path. Software that depends on unlisted AXI
Ethernet features must not assume those features are present.

| Offset | Name | Notes |
| ---: | --- | --- |
| `0x0000` | RAF | Reset/address-filter control; counter reset is self-clearing |
| `0x000c` | Interrupt status | Write one to clear implemented events |
| `0x0010` | Pending interrupts | Status masked by interrupt enable |
| `0x0014` | Interrupt enable | Enables `mac_irq` sources |
| `0x0200` | RX bytes | Receive-byte counter |
| `0x0208` | TX bytes | Transmit-byte counter |
| `0x0250` | RX overflow | Dropped receive frames due to buffer limits |
| `0x0288` | TX oversized | Dropped oversized transmit frames |
| `0x0290` | RX frames | Accepted receive frames |
| `0x0298` | RX FCS errors | Frames rejected for bad FCS |
| `0x02a0` | RX broadcasts | Accepted broadcast frames |
| `0x02a8` | RX multicasts | Accepted multicast frames |
| `0x02d8` | TX frames | Transmitted frames |
| `0x0400` | RCW0 | Receive configuration word 0 |
| `0x0404` | RCW1 | Receive enable is bit 28 |
| `0x0408` | TC | Transmit enable is bit 28 |
| `0x040c` | FCC | Flow-control compatibility register |
| `0x0410` | EMMC | Fixed 1 Gb/s mode compatibility register |
| `0x0414` | RXFC | Reports the 16 KiB receive capacity |
| `0x0418` | TXFC | Reports the 4 KiB transmit capacity |
| `0x04f8` | Core ID | `0x4f4d4143` (`OMAC`) |
| `0x04fc` | Version | `0x00000001` |
| `0x0700` | UAW0 | Station address low word in AXI Ethernet byte ordering |
| `0x0704` | UAW1 | Station address high 16 bits |
| `0x0708` | FMI | Bit 31 enables promiscuous receive mode |

Reads of GMII-domain statistics use a request/acknowledge snapshot handshake.
The AXI read response is delayed by several clock cycles while the selected
counter is captured and held stable across the clock-domain crossing. The
AXI4-Lite master must therefore wait for `RVALID` rather than assuming a fixed
read latency. The TX-oversized counter, which already resides in the AXI clock
domain, does not require a snapshot.

The receive path accepts the programmed station address, broadcast, and all
multicast destinations. It validates destination, length, GMII error, and FCS
before committing a packet descriptor. The receive data and status streams may
drain independently; their shared ring allocation is reclaimed after both have
completed. The transmit path commits a descriptor only after the entire AXI
packet reaches `TLAST`, then emits preamble, payload, padding, FCS, and
interpacket gap on GMII.

The 4 KiB TX and 16 KiB RX memories are circular word-addressed buffers rather
than single-packet slots. They can hold multiple variable-length packets up to
the available byte capacity. Separate descriptor rings hold up to eight TX
packets and sixteen RX packets. RX admission reserves enough free ring space
for a maximum-size frame before accepting its SFD; a valid frame is counted as
an RX overflow if either the descriptor ring or that reserved data capacity is
unavailable.
