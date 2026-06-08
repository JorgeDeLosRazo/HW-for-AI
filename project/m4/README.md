# Milestone 4 — Memristor Crossbar Analog AI Accelerator

## M4 File Catalog

| Path | Description | Checklist item |
|------|-------------|---------------|
| `README.md` | This file — index, scope notes, reproduction guide | §1 README |
| `rtl/top.sv` | Integrated top module: AXI4-Lite interface + compute_core | §2 Source code |
| `rtl/compute_core.sv` | 4x4 memristor crossbar compute core (G[i][j] x V[i] MVM) | §2 Source code |
| `rtl/interface.sv` | AXI4-Lite slave with external compute_core control ports | §2 Source code |
| `tb/tb_top.sv` | End-to-end testbench (host-side AXI4-Lite only) | §2 Testbench |
| `sim/final_run.log` | Simulation transcript — ends with PASS | §2 Sim log |
| `sim/final_waveform.png` | Annotated end-to-end waveform (3 phases) | §2 Waveform |
| `synth/config.json` | OpenLane 2 configuration (sky130A, 10 ns clock) | §3 Synthesis |
| `synth/openlane_run.log` | Full OpenLane stdout/stderr — failure at Verilator.Lint | §3 Synthesis |
| `synth/timing_report.txt` | Critical path and slack estimates (sky130 model) | §3 Timing |
| `synth/area_report.txt` | Cell count from yosys + sky130 area estimates | §3 Area |
| `synth/power_report.txt` | Power estimate via switching-power model | §3 Power |
| `bench/benchmark.md` | Throughput, speedup, energy vs M1 CPU baseline | §4 Benchmark |
| `bench/benchmark_data.csv` | Raw measurements and derived values | §4 Benchmark |
| `bench/roofline_final.png` | Final roofline: CPU baseline, M4 accelerator, projected | §4 Roofline |
| `report/design_justification.pdf` | 9-section design justification report | §5 Report |
| `report/figures/roofline_final.png` | Roofline figure (referenced in report §2) | §5 Figures |
| `report/figures/final_waveform.png` | Waveform figure (referenced in report §6) | §5 Figures |

---

## RTL Changes from M3

M3 used a single `top.sv` containing the full AXI4-Lite logic plus `memristor_crossbar`
instantiation. M4 splits this into three files per the M4 spec:

- `interface.sv` — AXI4-Lite slave with compute_core ports exposed externally
- `compute_core.sv` — memristor crossbar (renamed from memristor_crossbar, same logic)
- `top.sv` — instantiates both and wires them together

No functional changes from M3. The same test case produces the same results.

---

## Reproducing the Final Simulation

**Simulator:** Icarus Verilog 12.0  
Install: `sudo apt install iverilog`

```bash
cd project/m4/sim

iverilog -g2012 -o final_sim \
  ../rtl/compute_core.sv \
  ../rtl/interface.sv \
  ../rtl/top.sv \
  ../tb/tb_top.sv

vvp final_sim
```

Expected last lines:
```
--- 4/4 checks passed ---
PASS
```

---

## Reproducing the Synthesis Run

**Tool:** OpenLane 2 v2.3.10  
Install: `pip install openlane`

**Known failure:** Requires `verilator` (`sudo apt install verilator`).  
After installing verilator:

```bash
cd project/m4/synth
openlane config.json
```

PDK (sky130A) is auto-downloaded on first run (~300 MB).

**yowasp-yosys fallback (no verilator needed):**
```bash
pip install yowasp-yosys
cd project/m4/synth
yowasp-yosys -p "read_verilog -sv ../rtl/compute_core.sv ../rtl/interface.sv ../rtl/top.sv; synth -top crossbar_top; stat"
```

---

## Design Justification Report

See [report/design_justification.pdf](report/design_justification.pdf) — 9 sections,
~2,800 words covering: problem and motivation, roofline analysis, precision/data format,
dataflow and architecture, hardware interface, verification, synthesis results,
benchmark results, and what did not work.
