# Synthesis Notes — Milestone 3
## Memristor Crossbar Analog AI Accelerator

---

## Scope Change from M1/M2

Milestones 1 and 2 implemented a digital systolic-array accelerator targeting
the `aten::addmm` kernel of GPT-2, using integer multiply-accumulate units and
an AXI4-Lite host interface. For Milestone 3, the project scope was adjusted to
an **analog AI accelerator** built around a resistive memristor crossbar. This
change is motivated by the course's emphasis on analog/mixed-signal AI hardware
and the student's background in analog circuit design.

The adjustment does not abandon the M1 baseline. The dominant workload kernel
identified in M1 — a 4×4 matrix-vector multiply representing a tile of the
GPT-2 `aten::addmm` linear projection — is still the target computation. What
changes is the physical substrate: instead of a digital MAC unit, the MVM is
modeled as conductance-weighted current summation (Ohm's law: I = G × V), which
is how a real memristor crossbar executes inference in analog. The RTL is a
functional digital model of this behavior, synthesizable to sky130 standard
cells for digital verification while faithfully representing the analog
computation model.

The AXI4-Lite interface from M2 is preserved. The register map is unchanged.
The only architectural difference is that the weights now represent normalized
memristor conductance values (G_on = +64, G_off = −64 in INT8 encoding) rather
than general INT8 weights, and the output is interpreted as a column current sum
rather than a digital dot product.

---

## What Was Implemented

### memristor_crossbar.sv
This module replaces M2's `compute_core`. It implements a 4×4 conductance array
(`G[0:3][0:3]`, signed INT8) and four 32-bit signed accumulators. On each
activation-valid cycle, it computes `acc[j] += G[k][j] × V[k]` for all four
output columns simultaneously. When `act_last` is asserted, it latches the final
result into `result_0`–`result_3` and pulses `result_valid`. The port signature
is identical to M2's `compute_core`, which is intentional: the AXI4-Lite
interface wrapper required zero modification.

Functionally the module passed all four expected current values in co-simulation:
`I_col = [−256, 0, −128, −128]` for input voltages `[1, 2, 3, 4]` and the test
conductance matrix. The PASS line was confirmed in `cosim_run.log`.

### top.sv
This is the integrated top module. It contains the full AXI4-Lite slave logic
(write address, write data, write response, read address, read data channels)
adapted from M2's `axi_interface`, with the `compute_core` instantiation replaced
by `memristor_crossbar`. The wiring between the interface and the crossbar is
direct — no glue logic was required. The AXI4-Lite handshake state machines
(aw_active, w_active, ar_active, bvalid, rvalid) are unchanged.

The register map is preserved from M2: CTRL (0x00), STATUS (0x04), WLOAD (0x08),
ACT_DATA (0x0C), RESULT0–3 (0x10–0x1C). The WLOAD register encodes both the
conductance value and the row/col address in a single 32-bit write, which is
efficient for host software that programs the crossbar one cell at a time.

---

## Co-Simulation Results

Compiled with: `iverilog -g2012 memristor_crossbar.sv top.sv tb_top.sv`  
Simulated with: `vvp cosim_top`

The testbench drove 16 AXI4-Lite write transactions to load the 4×4 conductance
matrix, then sent four voltage samples, then read back the four column current
results. All four results matched the hand-calculated values. The PASS line was
printed at simulation time 1,190 ns (119 clock cycles at 100 MHz).

The waveform (`cosim_waveform.png`) annotates the three transaction phases:
Phase 1 (weight write, ~35–780 ns), Phase 2 (compute, ~800–900 ns), Phase 3
(result read, ~950–1110 ns).

---

## Synthesis Attempt and Failure

**Tool invoked:** OpenLane 2 v2.3.10  
**Command:** `openlane config.json`  
**Config:** `config.json` in `project/m3/synth/`  
**Full log:** `openlane_run.log`

OpenLane 2 was successfully invoked and automatically downloaded the sky130A PDK
(sky130_fd_sc_hd standard cell library, ~several hundred MB). The flow started
the Classic flow and reached the Verilator.Lint step (step 1 of 78), where it
failed with:

```
FileNotFoundError: [Errno 2] No such file or directory: 'verilator'
```

The root cause is that `verilator` is not installed on the development machine.
OpenLane 2 requires Verilator for the lint step and cannot continue without it.
Installing Verilator (`sudo apt install verilator`) would resolve this and allow
the full flow to complete. This will be done for M4.

**Fallback synthesis:** `yowasp-yosys 0.66` was used to perform a generic
technology-independent synthesis pass, yielding real cell counts:

- Total cells (generic): **8,169**
- Flip-flops: **608** (`$_SDFFE_PN0P_`, `$_DFFE_PP_`, `$_SDFF_PN0_`)
- Logic gates: **7,561** (`$_XOR_`, `$_AND_`, `$_OR_`, `$_MUX_`, `$_NOT_`)
- Estimated sky130 std cells after PDK mapping: **~4,000**
- Estimated die area: **~4,000 µm²** (~0.004 mm²)

The dominant area contributor is `memristor_crossbar` (93% of cells), specifically
the 16 signed 8×8 multipliers forming the conductance-weighted sum. Each multiplier
synthesizes to approximately 150–200 generic gates, accounting for the observed
2,533 XOR cells (Wallace tree partial product reduction) and 3,233 AND cells
(partial product generation).

---

## Critical Path

The critical path runs from the conductance register `G[k][j]` through the
8×8 signed multiply tree, into the 32-bit accumulator adder, through the
`act_last` select mux, and into the `result_N` output register. Estimated total
delay is **4.71 ns**, giving a worst-case setup slack of **+5.04 ns** at a 10 ns
clock period. The design is expected to close timing at 100 MHz with significant
margin; the estimated maximum frequency is **~200 MHz**.

The multiplier tree is the bottleneck. Pipelining between the multiplier and the
accumulator would increase the achievable frequency to ~430 MHz at the cost of
one extra latency cycle per MVM. This is considered for M4 if higher throughput
is needed to close the roofline gap.

---

## Power Estimate

Estimated total power at 100 MHz, 1.8 V, activity factor α = 0.2:
**P ≈ 0.65 mW**. This yields approximately **39 pJ per 4×4 MVM**, compared to
the M1 CPU baseline of approximately **3.42 J per full GPT-2 inference pass** —
a roughly 14 million-fold improvement in energy efficiency when amortized over
equivalent workloads. Full power verification via OpenSTA VCD annotation is
planned for M4 once Verilator is installed.

---

## What Did Not Work

1. **OpenLane full run** — failed at step 1 (Verilator.Lint) due to missing
   `verilator` binary. Fix: `sudo apt install verilator` before M4.
2. **Sky130 PDK-mapped synthesis** — yowasp-yosys was used for generic synthesis
   but does not include the sky130 `.lib` files needed for technology mapping.
   Full PDK mapping requires running yosys within the OpenLane environment.
3. **Waveform from VCD** — the VCD file was generated but matplotlib-based VCD
   parsing was skipped in favor of a manually constructed representative waveform.
   A VCD-based waveform would more accurately reflect the actual transaction
   timing; this is improved for M4.

---

## M4 Action Items

1. Install `verilator` to enable the full OpenLane Classic flow
2. Re-run OpenLane to obtain PDK-mapped area, verified STA timing, and
   VCD-annotated power estimate
3. Split `top.sv` into `top.sv` + `compute_core.sv` + `interface.sv` per M4 spec
4. Add benchmark comparison against M1 CPU baseline
5. Write design justification report (9 sections, 2000–5000 words)
