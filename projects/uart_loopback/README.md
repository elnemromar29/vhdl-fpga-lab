# UART Loopback

VHDL UART loopback project for Vivado.

## Contents

| Path | Purpose |
| --- | --- |
| `src/baud_gen.vhd` | Baud-rate tick generator |
| `src/fwft_fifo.vhd` | First-word fall-through FIFO |
| `src/uart.vhd` | UART wrapper with RX/TX FIFOs |
| `src/uart_rx.vhd` | UART receiver |
| `src/uart_tx.vhd` | UART transmitter |
| `src/uart_system_top.vhd` | Top-level loopback design |
| `sim/uart_tb.vhd` | Simulation testbench |
| `constraints/constraints.xdc` | Vivado constraints |
| `docs/README.docx` | Original project documentation |

## Vivado Notes

Add the files in `src/` as design sources, `sim/uart_tb.vhd` as a simulation source, and `constraints/constraints.xdc` as the constraints file.

The top-level entity is `uart_system_top`.
