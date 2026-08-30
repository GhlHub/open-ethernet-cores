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

The receive path accepts the programmed station address, broadcast, and all
multicast destinations. It validates destination, length, GMII error, and FCS
before producing AXI4-Stream data or status. The transmit path buffers the
entire packet before emitting preamble, payload, padding, FCS, and interpacket
gap on GMII.
