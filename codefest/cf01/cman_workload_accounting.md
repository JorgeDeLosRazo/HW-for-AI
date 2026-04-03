# CMAN for Codefest #1
You are given a 3-layer fully connected network with dimensions [784 → 256 → 128 → 10], batch size 1,
all weights and activations in FP32 (4 bytes each). No bias terms. 

![](../../images/cf01-neural-network.png)

**Tasks**
1) For each layer, compute the number of multiply-accumulate operations (MACs). Show the formula and the substituted values.\\

    The number of MACs for a particular layer is given by the multiplying the inputs `I` with the outputs `0`. For the network provided below we get the following:
    1) Layer 1: $$784 \times 256 = 200,704$$
    2) Layer 2: $$256 \times 128 = 32,768$$ 
    3) Layer 3: $$128 \times 10 = 1,280$$ 

2) Sum the MACs across all three layers to get the total MACs for one forward pass.

    The sum of the total MACs for the three layers is given by summing the MACs for each individual layer, which for our network is given by the following: <br>
        <p align="center">
        $$\text{MAC}_{\text{tot}} = 200,704 + 32,768 + 1,280 = 234,752$$
        <p>
        
3) Compute the total number of trainable parameters (weights only, no biases).



4) Compute the total weight memory in bytes (FP32).



5) Compute the total activation memory in bytes needed to store the input and all layer outputs simultaneously (FP32).

    

6) Compute arithmetic intensity as: (2 × total MACs) / (weight bytes + activation bytes).





