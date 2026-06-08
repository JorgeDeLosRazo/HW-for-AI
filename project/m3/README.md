# Milestone 3 — Memristor Crossbar Analog AI Accelerator

## Scope Change

This milestone shifts the project from a digital systolic-array accelerator (M1/M2)
to an **analog AI accelerator** built around a resistive memristor crossbar. The
target computation (4×4 MVM from the GPT-2 `aten::addmm` kernel identified in M1)
is preserved. The AXI4-Lite interface from M2 is reused unchanged. See
`synthesis_notes.md` for the full rationale.

---

## File Catalog

| Path | Description |
|------|-------------|
| `README.md` | This file — index, reproduction instructions, scope note |
| `rtl/top.sv` | Integrated top module: AXI4-Lite slave + memristor crossbar |
| `rtl/memristor_crossbar.sv` | 4×4 conductance-array compute core (replaces M2 compute_core) |
| `tb/tb_top.sv` | End-to-end co-simulation testbench (host-side AXI4-Lite only) |
| `sim/cosim_run.log` | Co-simulation transcript — ends with PASS |
| `sim/cosim_waveform.png` | Annotated end-to-end waveform (3 phases) |
| `sim/gen_waveform.py` | Python script that generated the waveform |
| `synth/config.json` | OpenLane 2 configuration (sky130A, 10 ns clock) |
| `synth/openlane_run.log` | Full OpenLane stdout/stderr — shows failure at Verilator.Lint |
| `synth/area_report.txt` | Cell count and area estimates (yosys + sky130 model) |
| `synth/timing_report.txt` | Critical path delay estimates and slack (tt/25°C model) |
| `synth/power_report.txt` | Power estimate via switching-power model |
| `synth/critical_path.md` | Critical path identification: start, end, stages, fix options |
| `synthesis_notes.md` | Narrative: scope change, what worked, what failed, M4 plan |

---

## Reproducing the Co-Simulation

**Simulator:** Icarus Verilog 12.0 (stable)  
Install: `sudo apt install iverilog`

```bash
cd project/m3/sim

# Compile
iverilog -g2012 -o cosim_top \
  ../rtl/memristor_crossbar.sv \
  ../rtl/top.sv \
  ../tb/tb_top.sv

# Run
vvp cosim_top
```

Expected output (last three lines):
```
--- 4/4 checks passed ---
PASS
../tb/tb_top.sv:185: $finish called at 1190000 (1ps)
```

**Regenerating the waveform** (requires Python 3 + matplotlib):
```bash
cd project/m3/sim
python3 gen_waveform.py
```

---

## Reproducing the Synthesis Run

**Tool:** OpenLane 2 v2.3.10  
Install: `pip install openlane`

**PDK:** sky130A (auto-downloaded by OpenLane on first run, ~300 MB)

**To attempt the run:**
```bash
cd project/m3/synth
openlane config.json
```

**Known failure:** The run currently fails at step 1 (Verilator.Lint) because
`verilator` is not installed. Fix:
```bash
sudo apt install verilator
```
After installing verilator, re-running `openlane config.json` from `project/m3/synth/`
should complete the full Classic flow (78 steps). The area, timing, and power reports
in this folder are derived from a yowasp-yosys fallback run and sky130 characterization
data; they will be replaced with OpenLane-verified values in M4.

**yowasp-yosys fallback (no PDK required):**
```bash
pip install yowasp-yosys
cd project/m3/synth
yowasp-yosys -p "read_verilog -sv ../rtl/memristor_crossbar.sv ../rtl/top.sv; synth -top crossbar_top; stat"
```
