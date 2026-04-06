# Profiling of ResNet-18
ResNet-18 is a Convolutional Neural Network (CNN) architecture with 18 layers. It is widely used for computer vision tasks like image classification. `torchinfo` will be used to profile ResNet-18 on a single FP32 forward pass (batch=1, input 3×224×224).

## Code
The following code was used to profile ResNet-18

```
import torch
import torchvision.models as models
from torch.profiler import profile, record_function, ProfilerActivity

model = models.resnet18(weights=None).eval()
x = torch.randn(1, 3, 224, 224)  # batch=1, FP32

# Warmup (optional but good practice)
with torch.no_grad():
    model(x)

# Profile
with profile(
    activities=[ProfilerActivity.CPU],
    record_shapes=True,
    with_flops=True,
) as prof:
    with record_function("forward"):
        with torch.no_grad():
            model(x)

print(prof.key_averages().table(sort_by="cpu_time_total", row_limit=20))
```
 
 The text output of the above code was stored at `resnet18_analysis.txt`.


## Top 5 Layers by MAC Count

Profiled using `torchinfo` on a single FP32 forward pass (batch=1, input 3×224×224).

| Rank | Layer | MACs (M) | Parameters |
|------|-------|----------|------------|
| 1 | Conv2d (conv1): 1-1 | 118.01 | 9,408 |
| 2 | Conv2d (conv1): 3-1 | 115.61 | 36,864 |
| 3 | Conv2d (conv2): 3-4 | 115.61 | 36,864 |
| 4 | Conv2d (conv1): 3-7 | 115.61 | 36,864 |
| 5 | Conv2d (conv2): 3-10 | 115.61 | 36,864 |

## Arithmetic Intensity of the Most MAC-Intensive Layer

The most MAC-intensive layer is **Conv2d (conv1): 1-1** — the stem convolution of ResNet-18.

**Layer parameters:**
- Input: 3 × 224 × 224 (C_in × H_in × W_in)
- Output: 64 × 112 × 112 (C_out × H_out × W_out)
- Kernel: 7 × 7

**Calculation** 
(FP32 = 4 bytes per value, no weight/activation reuse assumed):

| Component | Calculation | Size |
|-----------|-------------|------|
| FLOPs | 2 × 118.01 MMACs | 236.03 MFLOPs |
| Weights | 3 × 64 × 7 × 7 × 4 B | 0.0376 MB |
| Input activations | 3 × 224 × 224 × 4 B | 0.6021 MB |
| Output activations | 64 × 112 × 112 × 4 B | 3.2113 MB |
| **Total bytes** | | **3.8510 MB** |

**Arithmetic Intensity = FLOPs / Bytes = 236,027,904 / 3,851,008 = 61.29 FLOPs/Byte**

This layer is **memory-bound** — modern GPUs have a ridge point of ~200–300 FLOPs/Byte, so at 61.29 FLOPs/Byte the bottleneck is DRAM bandwidth, not compute. The large output activation (3.21 MB) is the dominant data movement cost.
