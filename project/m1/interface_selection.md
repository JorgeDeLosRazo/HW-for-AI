# Interface Selection — Milestone 1

## Selected Protocol: AXI4-Lite

The accelerator uses an **AXI4-Lite slave** interface.

**Rationale:** AXI4-Lite is a lightweight, widely-supported memory-mapped register
protocol suitable for the control plane of a compute accelerator. The host CPU
writes weights and activation data into registers and reads results back.
Data volumes are small (a few 32-bit words per inference pass), so the
low-overhead register access model of AXI4-Lite is appropriate; a full AXI4
streaming interface would be unnecessarily complex at this scale.

**Address width:** 8-bit (covers 64-byte register space)  
**Data width:** 32-bit  
**Clock polarity:** rising-edge, AMBA-standard  
