# Arithmetic Intensity Calculation — GPT-2 Small Dominant Kernel

## Project Algorithm
GPT-2 Small (117M parameters) inference, used as the LLM backbone for op-amp design assistance.  
Profiling configuration: batch size B = 1, sequence length T = 128, 10 runs, CPU only.

---

## Dominant Kernel Identification

From `project_profile.txt`, the `aten::addmm` operation dominates:

| Kernel | Self CPU % | Total MFLOPs (10 runs) |
|---|---|---|
| `aten::addmm` | **63.21%** | **217,432.7** |
| `aten::mul` | 6.61% | 188.7 |
| `aten::add` | 3.90% | 118.9 |

`aten::addmm` implements all linear projections in GPT-2: the Q/K/V and output projections
in attention, plus both MLP feed-forward layers. It accounts for 480 total calls across
10 runs (48 calls per forward pass).

---

## FLOPs Calculation

### Model dimensions (GPT-2 Small)
- Number of layers: **L = 12**
- Model dimension: **d = 768**
- Feed-forward dimension: **d_ff = 3072** (= 4d)
- Sequence length: **T = 128**
- Batch size: **B = 1**

### Linear layer breakdown per forward pass (48 `addmm` calls)

In HuggingFace GPT-2, each layer has 4 `addmm` calls:

| Projection | Input shape | Weight shape | FLOPs formula | FLOPs per layer |
|---|---|---|---|---|
| QKV fused (`c_attn`) | (T × d) | (d × 3d) | 2 × B × T × d × 3d | 2 × 1 × 128 × 768 × 2304 = 452,984,832 |
| Output (`c_proj`) | (T × d) | (d × d) | 2 × B × T × d × d | 2 × 1 × 128 × 768 × 768 = 150,994,944 |
| MLP up (`c_fc`) | (T × d) | (d × d_ff) | 2 × B × T × d × d_ff | 2 × 1 × 128 × 768 × 3072 = 603,979,776 |
| MLP down (`c_proj`) | (T × d_ff) | (d_ff × d) | 2 × B × T × d_ff × d | 2 × 1 × 128 × 3072 × 768 = 603,979,776 |

### Total FLOPs (12 layers)

```
FLOPs_c_attn  = 12 × 452,984,832  =  5,435,817,984
FLOPs_c_proj  = 12 × 150,994,944  =  1,811,939,328
FLOPs_c_fc    = 12 × 603,979,776  =  7,247,757,312
FLOPs_mlp_proj= 12 × 603,979,776  =  7,247,757,312
─────────────────────────────────────────────────────
Total FLOPs   =                     21,743,272,936
              ≈ 21.74 GFLOPs per forward pass
```

**Verification:** Profiler reports 217,432.7 MFLOPs over 10 runs = **21,743.3 MFLOPs/run** ✓

---

## Bytes Transferred Calculation

Assuming all operands are loaded from DRAM with no cache reuse. FP32 = **4 bytes** per element.  
For each `addmm(input, weight, bias)`:
- Load input: B × T × in_dim × 4 bytes  
- Load weight: out_dim × in_dim × 4 bytes  
- Load bias: out_dim × 4 bytes  
- Store output: B × T × out_dim × 4 bytes  

### Per-projection bytes (12 layers each)

**c_attn** (in_dim = 768, out_dim = 2304):
```
Load input:   1 × 128 × 768  × 4 =    393,216 bytes
Load weight:  2304 × 768     × 4 =  7,077,888 bytes
Load bias:    2304           × 4 =      9,216 bytes
Store output: 1 × 128 × 2304 × 4 =  1,179,648 bytes
Per layer total:                     8,659,968 bytes
12 layers:                         103,919,616 bytes ≈ 103.9 MB
```

**c_proj / attention output** (in_dim = 768, out_dim = 768):
```
Load input:   1 × 128 × 768 × 4 =   393,216 bytes
Load weight:  768 × 768     × 4 = 2,359,296 bytes
Load bias:    768           × 4 =     3,072 bytes
Store output: 1 × 128 × 768 × 4 =   393,216 bytes
Per layer total:                   3,148,800 bytes
12 layers:                        37,785,600 bytes ≈ 37.8 MB
```

**c_fc / MLP up** (in_dim = 768, out_dim = 3072):
```
Load input:   1 × 128 × 768  × 4 =    393,216 bytes
Load weight:  3072 × 768     × 4 =  9,437,184 bytes
Load bias:    3072           × 4 =     12,288 bytes
Store output: 1 × 128 × 3072 × 4 =  1,572,864 bytes
Per layer total:                    11,415,552 bytes
12 layers:                         136,986,624 bytes ≈ 137.0 MB
```

**MLP down proj** (in_dim = 3072, out_dim = 768):
```
Load input:   1 × 128 × 3072 × 4 =  1,572,864 bytes
Load weight:  768 × 3072     × 4 =  9,437,184 bytes
Load bias:    768            × 4 =      3,072 bytes
Store output: 1 × 128 × 768  × 4 =    393,216 bytes
Per layer total:                    11,406,336 bytes
12 layers:                         136,876,032 bytes ≈ 136.9 MB
```

### Total Bytes

```
Bytes_c_attn   = 103,919,616
Bytes_c_proj   =  37,785,600
Bytes_c_fc     = 136,986,624
Bytes_mlp_down = 136,876,032
─────────────────────────────
Total Bytes    = 415,567,872 bytes ≈ 415.6 MB per forward pass
```

---

## Arithmetic Intensity

```
AI = Total FLOPs / Total Bytes
   = 21,743,272,936 FLOPs / 415,567,872 bytes
   = 52.3 FLOP/byte
```

---

## Bound Classification on Target Hardware (Intel i5-8350U)

| Parameter | Value | Source |
|---|---|---|
| Peak compute (FP32, AVX2+FMA) | ~230 GFLOP/s | 4 cores × 2 FMAs × 8 floats × 3.6 GHz |
| Peak DRAM bandwidth (DDR4-2133, dual-channel) | ~34 GB/s | Spec sheet |
| Ridge point | 230 / 34 ≈ **6.8 FLOP/byte** | Computed |

Since **AI = 52.3 FLOP/byte >> ridge point = 6.8 FLOP/byte**, the dominant kernel is
**compute-bound** on the i5-8350U.

Attainable performance ceiling = Peak Compute = **230 GFLOP/s**

Observed from profiler: 21,743 MFLOPs / 152.9 ms per run ≈ **142 GFLOP/s** (62% of peak),
consistent with compute-bound execution with realistic AVX2 utilization.
