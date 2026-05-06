# FPGA VHDL Projects

This repository contains FPGA/VHDL projects intended for Vivado.

## Projects

| Project | Description |
| --- | --- |
| `uart_loopback` | UART loopback design with RX/TX cores, baud generator, FIFO buffering, testbench, and Vivado constraints. |

## Repository Layout

```text
projects/
  uart_loopback/
    src/          VHDL design sources
    sim/          VHDL simulation testbenches
    constraints/  Vivado XDC constraints
    docs/         Project notes and exported documentation
```

Add future VHDL projects under `projects/<project_name>/` using the same folder pattern.
