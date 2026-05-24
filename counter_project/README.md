# VHDL Octal Counter

This project implements a four-digit octal up/down counter in VHDL. The counter is designed for a 100 MHz FPGA clock and drives a multiplexed four-digit seven-segment display.

## Features

- Four octal digits, `0000` through `7777`
- 1 Hz count tick generated from the system clock
- Count up, count down, hold, and synchronous reset controls
- Asynchronous active-high reset
- Switch and push-button synchronization/debouncing
- Seven-segment display scanning
- Testbenches for the counter, IO controller, and top-level design

## Directory Structure

```text
vhdl/   Synthesizable VHDL source files
tb/     Simulation testbenches
impl/   Place for FPGA implementation files
sim/    Place for simulator outputs
```

## Controls

The top-level entity is `cntr_top`.

| Signal | Function |
| --- | --- |
| `sw_i(0)` | Hold counter when high |
| `sw_i(1)` | Count up when high |
| `sw_i(2)` | Count down when high |
| `sw_i(3)` | Synchronous reset to `0000` when high |
| `reset_i` | Asynchronous active-high reset |
| `led_o` | Mirrors synchronized switch values |

Reset has highest priority, then hold, then count up, then count down.

## Source Files

| File | Description |
| --- | --- |
| `vhdl/cntr.vhd` | Counter entity declaration |
| `vhdl/cntr_rtl.vhd` | Octal counter and clock-divider implementation |
| `vhdl/io_ctrl.vhd` | IO controller entity declaration |
| `vhdl/io_ctrl_rtl.vhd` | Seven-segment display scanning and input synchronization |
| `vhdl/cntr_top.vhd` | Top-level entity declaration |
| `vhdl/cntr_top_rtl.vhd` | Top-level integration |

## Simulation

If GHDL is installed, analyze the design with VHDL-2008 enabled:

```sh
ghdl -a --std=08 vhdl/cntr.vhd vhdl/cntr_rtl.vhd
ghdl -a --std=08 vhdl/io_ctrl.vhd vhdl/io_ctrl_rtl.vhd
ghdl -a --std=08 vhdl/cntr_top.vhd vhdl/cntr_top_rtl.vhd
ghdl -a --std=08 tb/tb_cntr.vhd tb/tb_io_ctrl.vhd tb/tb_cntr_top.vhd
```

Run individual testbenches with:

```sh
ghdl -e --std=08 tb_counter
ghdl -r --std=08 tb_counter --assert-level=error

ghdl -e --std=08 tb_io_ctrl
ghdl -r --std=08 tb_io_ctrl --assert-level=error

ghdl -e --std=08 tb_counter_top
ghdl -r --std=08 tb_counter_top --assert-level=error
```

The counter and IO controller use generics so testbenches can run quickly while the hardware defaults remain 100 MHz, 1 Hz counting, and a 2 kHz display refresh enable.

## Notes

- Seven-segment outputs are active low.
- The implementation assumes a four-digit active-low display select.
- The `impl/` and `sim/` folders are intended for local tool output and are ignored by Git except for placeholder files.
