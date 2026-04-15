# Project

## Heilmeier Questions

### 1) What are you trying to do?
I am building an LLM-based assistant that helps engineers design op-amps by answering
design questions, suggesting component values, and explaining trade-offs. The system is
backed by a GPT-2-style transformer model fine-tuned on analog circuit design knowledge.
I am also designing a custom hardware accelerator specifically optimized to run this
transformer's inference workload efficiently on embedded or edge hardware.

### 2) What are the limits of the current approach?
Profiling GPT-2 Small (117M parameters, batch=1, seq_len=128) on a laptop CPU (Intel
i5-8350U) reveals that the dominant bottleneck is the `aten::addmm` kernel — the matrix
multiply at the heart of every linear projection — which consumes **63.2% of total CPU
time** and delivers only ~142 GFLOP/s out of a theoretical peak of 230 GFLOP/s. The
kernel is compute-bound (arithmetic intensity 52.3 FLOP/byte versus a ridge point of
6.8 FLOP/byte), meaning software optimizations alone cannot close the gap. Running a
full LLM inference pass takes ~228 ms per query on this hardware, which is too slow for
an interactive design tool. The current CPU cannot scale to larger models or shorter
latency requirements without a dedicated compute substrate. My own limited experience
with analog design is an additional constraint on how well I can curate training data and
validate the model's circuit recommendations.

### 3) What is your approach and why is it better?
My approach combines fine-tuning a transformer LLM on op-amp design datasets with a
custom systolic-array hardware accelerator targeting the compute-bound linear projection
kernel identified by profiling. The accelerator is designed for 2 TFLOP/s FP32 peak
compute with 500 GB/s HBM2 on-chip bandwidth (ridge point 4.0 FLOP/byte). Because the
dominant kernel's arithmetic intensity (52.3 FLOP/byte) far exceeds this ridge point, the
accelerator remains compute-bound and delivers the full 2 TFLOP/s — an approximately
8.7× speedup over the CPU ceiling of 230 GFLOP/s. This reduces inference latency from
~228 ms to an estimated ~26 ms per query, making real-time interactive use feasible.
Compared to running on a general-purpose CPU, the HW/SW co-design approach avoids
wasting energy on operations that are not the bottleneck, and concentrates silicon area
and power on the matrix multiplications that actually determine end-to-end latency.
