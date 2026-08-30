# SGMII PCS/PMA registers

All registers are 32-bit AXI4-Lite locations relative to the assigned base
address.

| Offset | Name | Purpose |
| ---: | --- | --- |
| `0x00` | Core ID | `0x4f504353` (`OPCS`) |
| `0x04` | Version | ABI in bits 31:16 and implementation revision in bits 15:0 |
| `0x08` | Control | Core, PHY reset, transmit, packet mode, test, and MDIO controls |
| `0x0c` | Status | Clock/PHY state and latched MDIO completion/error |
| `0x10` | MDIO command | PHY address, read/write selection, and register address |
| `0x14` | MDIO write data | Clause 22 write payload |
| `0x18` | MDIO read data | Clause 22 read result |
| `0x1c` | MDIO divider | Defaults to 29, producing 2.5 MHz MDC from 150 MHz |
| `0x20` | RX delay | Nine-bit IDELAY count; writing loads the new value |
| `0x24` | Raw RX word | Latest 10-bit diagnostic receive word |
| `0x28` | Raw TX word | Current 10-bit test symbol from control bits 31:22 |
| `0x2c` | Capabilities | MDIO, raw-symbol, codec, and GMII capability flags |
| `0x30` | RX words | Captured raw-word count |
| `0x34` | Commas | Recognized comma count |
| `0x38` | GMII TX bytes | Bytes presented to the transmit path |
| `0x3c` | GMII TX frames | Transmit-frame starts observed |
| `0x40` | RX PCS status | Byte/K/error, alignment, sync, phase, and disparity state |
| `0x44` | TX test code | Diagnostic byte in bits 7:0 and K flag in bit 8 |
| `0x48` | Decoded symbols | Aligned symbols decoded |
| `0x4c` | Code errors | Invalid 8b/10b symbol count |
| `0x50` | Disparity errors | Running-disparity violation count |
| `0x54` | Sync losses | Synchronization-loss count |
| `0x58` | Aligned RX word | Latest aligned 10-bit symbol |
| `0x5c` | FIFO status | TX/RX elastic-buffer levels and overflow/underflow state |
| `0x60` | Scratch | AXI read/write diagnostic register |

Control bit 0 enables the core, bit 1 releases `phy_reset_n`, bit 2 enables
serial transmission, and bit 4 selects GMII packet mode. Bit 3 selects encoded
test data instead of the raw symbol in bits 31:22. Bit 8 starts an MDIO
transaction and bit 9 clears latched MDIO completion/error state. Start with
the control register at zero while configuring the external PHY and choosing
the receive delay.
