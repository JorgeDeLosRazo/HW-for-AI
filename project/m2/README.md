# Milestone 2 — Reproducing the Simulation

## Simulator

**Icarus Verilog 12.0 (stable)**

Install on Ubuntu/Debian:
```
sudo apt install iverilog
```

## File layout

```
project/m2/
├── rtl/
│   ├── compute_core.sv   ← top-level compute module (module compute_core)
│   └── interface.sv      ← AXI4-Lite slave (module axi_interface)
├── tb/
│   ├── tb_compute_core.sv
│   └── tb_interface.sv
├── sim/
│   ├── compute_core_run.log
│   ├── interface_run.log
│   └── waveform.png
├── precision.md
└── README.md             ← this file
```

## Running the compute_core testbench

```bash
cd project/m2/sim
iverilog -g2012 -o sim_core ../tb/tb_compute_core.sv ../rtl/compute_core.sv
vvp sim_core
```

Expected output:
```
VCD info: dumpfile compute_core.vcd opened for output.
PASS
```

A VCD waveform file `compute_core.vcd` is also written.

## Running the interface testbench

```bash
cd project/m2/sim
iverilog -g2012 -o sim_iface ../tb/tb_interface.sv ../rtl/interface.sv ../rtl/compute_core.sv
vvp sim_iface
```

Expected output:
```
PASS
```

## Regenerating the waveform PNG

Requires Python 3 with matplotlib and numpy:
```
pip install matplotlib numpy
```

Then, from `project/m2/sim/` (after running the compute_core simulation to produce `compute_core.vcd`):

```bash
python3 gen_waveform.py
```

This writes `waveform.png`.

## Notes on module naming

`interface.sv` contains module `axi_interface` rather than `interface` because
`interface` is a reserved keyword in SystemVerilog. The file is named
`interface.sv` per the M2 submission specification.

## Deviations from M1 plan

No interface changes from M1. The AXI4-Lite slave matches the protocol
selected in `project/m1/interface_selection.md`.

The compute core implements a 4-input, 4-output weight-stationary MAC array
as a representative building block of the full systolic array described in the
Heilmeier document. Scaling to a larger array (N×N) requires only changing the
loop bounds and weight register depth; the interface register map remains the
same.
