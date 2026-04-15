# HW/SW Partition Proposal — GPT-2 Small for Op-Amp Design Assistance

## (a) Which kernel(s) to accelerate in hardware and why

The `aten::addmm` kernel — the batched matrix-multiply-plus-bias operation implementing all
linear projections in GPT-2 — will be accelerated in hardware. It accounts for 63.2% of total
CPU execution time and represents 217,432 MFLOPs across 10 inference runs, far exceeding every
other operation. The roofline analysis confirms the case: with an arithmetic intensity of
52.3 FLOP/byte and a CPU ridge point of only 6.8 FLOP/byte, the kernel is firmly
compute-bound. The CPU already achieves ~142 GFLOP/s (62% of its 230 GFLOP/s AVX2+FMA peak),
meaning it is near its practical ceiling and cannot be improved by software tuning alone.
Dedicating a systolic-array accelerator to these matrix multiplications directly targets the
dominant bottleneck.

## (b) What the software baseline will continue to handle

The CPU software path will retain all non-matrix operations: tokenization and embedding lookups,
scaled dot-product attention softmax, layer normalization, GELU activations, positional encoding,
and final logit sampling. Collectively these account for under 15% of runtime. They are
memory-latency-sensitive, control-flow-heavy, or low-trip-count operations that do not map well
onto a matrix accelerator and are not worth the overhead of off-loading.

## (c) Interface bandwidth requirement to avoid becoming interface-bound

At the accelerator's target throughput of 2 TFLOP/s, the required interface bandwidth is:

```
Required BW = Peak Compute / AI = 2,000 GFLOP/s / 52.3 FLOP/byte ≈ 38.2 GB/s
```

The proposed accelerator uses HBM2 at 500 GB/s on-chip, which is well above this requirement.
The CPU-to-accelerator interface (e.g., PCIe 4.0 x16 at ~32 GB/s, or direct die integration
at higher bandwidth) must sustain at least 38.2 GB/s to avoid becoming the bottleneck. A direct
integration with an on-package interconnect exceeding 50 GB/s would be sufficient.

## (d) Bound classification: current hardware vs. accelerator design

On the i5-8350U CPU, the `aten::addmm` kernel is **compute-bound** (AI = 52.3 >> ridge point
= 6.8 FLOP/byte). The accelerator is designed to increase peak compute from 230 GFLOP/s to
2 TFLOP/s (roughly 8.7×) while also raising the HBM bandwidth to 500 GB/s (ridge point = 4.0
FLOP/byte). Since the kernel's AI of 52.3 still exceeds the accelerator's ridge point of 4.0,
the kernel **remains compute-bound on the accelerator** — but now with a ceiling of 2,000
GFLOP/s instead of 230 GFLOP/s. This is the correct regime: we are not wasting bandwidth, and
the accelerator's extra compute throughput directly translates to faster inference.
