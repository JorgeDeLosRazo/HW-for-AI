# CMAN for Codefest #1
You are given a 3-layer fully connected network with dimensions [784 → 256 → 128 → 10], batch size 1,
all weights and activations in FP32 (4 bytes each). No bias terms. 

![](images/cf01-neural-network.png)

**Tasks**
1) For each layer, compute the number of multiply-accumulate operations (MACs). Show the formula
and the substituted values.
2) Sum the MACs across all three layers to get the total MACs for one forward pass.
3) Compute the total number of trainable parameters (weights only, no biases).
4) Compute the total weight memory in bytes (FP32).
5) Compute the total activation memory in bytes needed to store the input and all layer outputs
simultaneously (FP32).
6) Compute arithmetic intensity as: (2 × total MACs) / (weight bytes + activation bytes).

