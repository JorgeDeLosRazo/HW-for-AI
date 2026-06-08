# HW4AI — Hardware for Artificial Intelligence and Machine Learning
## ECE 410/510, Spring 2026 — Portland State University

This repository contains all coursework for ECE 410/510 HW4AI, including
codefest assignments and the semester project.

---

## Project: Memristor Crossbar Analog AI Accelerator

**[-> Go to M4 deliverables](project/m4/README.md)**
**[-> Design Justification Report (PDF)](project/m4/report/design_justification.pdf)**

The project builds an analog AI accelerator based on a 4x4 resistive memristor crossbar.
The accelerator performs matrix-vector multiplication (MVM) using Ohm's law in-memory
compute (I = G x V), targeting the aten::addmm linear projection kernel that accounts
for 63.2% of GPT-2 inference time on CPU (M1 profiling). The digital RTL model is
verified end-to-end via AXI4-Lite co-simulation and characterized using yowasp-yosys
synthesis on the sky130A PDK.

Key results:
- 4x4 MVM in 5 clock cycles at 100 MHz = 0.64 TOPS effective throughput
- ~9.8x speedup on linear projection kernel vs Intel i5-8350U CPU baseline
- ~0.65 mW estimated power vs ~15 W CPU TDP (~23,000x lower)
- ~39 pJ per 4x4 MVM

---

## Repository Structure

```
project/
  heilmeier.md          Project proposal (Heilmeier questions)
  m1/                   Milestone 1: Interface selection and roofline
  m2/                   Milestone 2: RTL modules (compute_core + axi_interface)
  m3/                   Milestone 3: Integration, co-simulation, synthesis attempt
  m4/                   Milestone 4: Final RTL, benchmarks, design report  <- HERE
codefest/
  cf06/                 Sneak paths in resistive crossbar (CMAN) + 4x4 MAC (CLLM)
  cf08/                 AER communication protocol analysis (CMAN)
```

| Milestone | Content |
|-----------|---------|
| M1 | AXI4-Lite interface selection; roofline analysis of GPT-2 addmm kernel |
| M2 | compute_core (4x4 MAC) + axi_interface RTL; separate module testbenches |
| M3 | Scope change to analog crossbar; integrated top.sv; co-sim PASS; OpenLane attempt |
| M4 | Final 3-file RTL split; benchmarks; roofline plot; design justification report |
