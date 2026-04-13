# Codefest #2
Use the following hardware specification: peak compute = 10 TFLOPS (FP32), peak DRAM bandwidth = 320 GB/s, ridge point = 10,000/320 ≈ 31.25 FLOP/byte.

1) On log-log axes (x: FLOP/byte, y: GFLOP/s), draw the roofline: the diagonal bandwidth-limited segment and the flat compute-limited ceiling. Label the ridge point coordinates.

![](images/roofline_plot.png)

2) Kernel A — Dense GEMM: two FP32 matrices of size 1024×1024 multiplied together. Compute FLOPs (2×N³ for square matmul), bytes transferred assuming all three matrices (A, B, C) are loaded/stored from DRAM with no cache reuse, arithmetic intensity, and plot the point on your roofline. 

    * **Number of FLOPs** : $$\text{FLOPs} = 2 \times N^2 = 2 \times (1024)^2 = 2.147 GFLOP$$
    * **Bytes Transferred** : $$\text{Bytes} = 3 times N^2 \times 4 \text{ Bytes} = 3 \times 1024^2 \times 4 = 12.58\text{MB}$$


3) Kernel B — Vector addition: two FP32 vectors of length 4,194,304 added element-wise. Compute FLOPs, bytes transferred, arithmetic intensity, and plot the point.

4) For each kernel, state: (a) memory-bound or compute-bound on this hardware; (b) attainable performance ceiling in GFLOP/s; (c) what architectural change would most improve performance.




