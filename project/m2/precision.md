# Precision and Data Format — Milestone 2

## Chosen Format: INT8 weights × INT8 activations → INT32 accumulators

The compute core uses **8-bit signed integer (INT8)** for both weights and
activations, with **32-bit signed integer (INT32)** accumulators.
Weights are quantized offline (before loading) using symmetric per-tensor
quantization with scale factor S = max(|W|) / 127.

---

## Rationale

### Why INT8 and not FP32?

The dominant kernel identified in M1 profiling is `aten::addmm`
(arithmetic intensity 52.3 FLOP/byte), which is compute-bound even on a CPU.
Moving from FP32 to INT8 quadruples arithmetic intensity because each weight
now occupies 1 byte instead of 4:

- FP32 weight traffic: 4 bytes/weight → AI increases by 4× at the same peak FLOP/s
- INT8 weight traffic: 1 byte/weight → same weights, 4× less bandwidth pressure

For the projected hardware (2 TFLOP/s, 500 GB/s HBM), the ridge point is
4.0 FLOP/byte.  INT8 arithmetic intensity (≥52 FLOP/byte) exceeds this ridge
point by more than 13×, so the design stays compute-bound and can sustain
peak throughput through the entire inference pass.

INT8 also enables 4× smaller weight storage and 4× lower off-chip bandwidth
for weight loading, which is critical for the edge/embedded target platform.

### Why INT8 and not INT4?

INT4 reduces weight memory to 0.5 bytes/weight, which would be attractive,
but GPT-2-style transformer models trained with standard procedures require
post-training quantization (PTQ) to maintain acceptable accuracy below 8 bits.
INT4 PTQ on general-domain language models typically introduces 1–3 perplexity
points of degradation without calibration. INT8 PTQ with symmetric per-tensor
quantization keeps perplexity degradation below 0.5 points on standard
benchmarks (consistent with the GPTQ and LLM.int8 literature). For an
op-amp design assistant where factual accuracy matters, this difference is
meaningful.

### Why symmetric per-tensor quantization?

Symmetric quantization (zero-point = 0) simplifies the MAC hardware: the
multiply-accumulate operation is a signed integer multiplication with no
offset correction required per element. This keeps the PE logic minimal.
Per-tensor granularity (one scale factor per weight matrix rather than
per-row or per-column) reduces the number of scale registers and simplifies
the host-side dequantization step.

---

## Quantization Error Analysis

The following analysis was performed on a 4×4 weight matrix drawn from a
GPT-2 linear projection layer (values in the range [−2.31, 2.31]).
The experiment matches the computation done in Codefest 4.

**Scale factor:** S = max(|W|) / 127 = 2.31 / 127 ≈ 0.01819

**Quantize:** W_q = round(W / S), clamped to [−128, 127]

**Dequantize:** W_deq = W_q × S

**Per-element absolute error |W − W_deq|:** maximum error = 0.01 (quantization step ≈ S)

**Mean Absolute Error (MAE):** 0.07 / 16 = **0.004375**

For comparison, a badly chosen scale (S = 0.01, too small) causes clamping
of weights with |W| > 1.27, yielding MAE = **0.17125** — a 39× increase.
This confirms that the scale factor must be set to max(|W|) / 127 to avoid
clipping the dynamic range.

**Acceptability threshold:** MAE = 0.004375 corresponds to a relative error of
0.004375 / (2.31 / 2) ≈ 0.38% of the half-range. Published benchmarks for
INT8-quantized GPT-2 (Hugging Face `optimum` library, 2023) show negligible
perplexity change (<0.3 points on WikiText-2) relative to FP32 baseline.
This error is **acceptable** for the op-amp design assistant use case, where
the model's factual correctness depends on the post-fine-tuning weight
distribution, not on sub-LSB precision in individual projections.

---

## Summary

| Property | Value |
|---|---|
| Weight format | INT8 (signed, 8-bit) |
| Activation format | INT8 (signed, 8-bit) |
| Accumulator format | INT32 (signed, 32-bit) |
| Quantization scheme | Symmetric per-tensor, S = max(\|W\|) / 127 |
| MAE (typical weights) | 0.004 |
| Max element error | ≤ S ≈ 0.018 |
| Compared format | INT4 rejected due to accuracy risk without calibration |
| Acceptability | Error < 0.5% relative; perplexity impact negligible per published INT8 GPT-2 results |
