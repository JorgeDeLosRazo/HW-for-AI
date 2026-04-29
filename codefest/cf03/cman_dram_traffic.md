# CMAN for Codefest #3

## Tasks
1) **Naive triple loop (ijk order): for computing one output element C[i][j] = Σ A[i][k]×B[k][j], how many times is each element of B accessed? Across the full N×N output, how many total element accesses are made to A and B? Compute total DRAM traffic in bytes for the full matrix multiply, assuming every element access goes to DRAM (no data reuse).**

    * **How many times is each element of B accessed?** <br>
        The amount of times the matrix elemts of B will be read form 
        DRAM is given by 
        <p align="center">
        $$B_{reads} = N \times N \times N = 32^3 = 32,768$$
        <p>

    * **How many total element accesses are made to A and B?**<br>
        The amount of times the matrx elenents of A plus the amount of times the matrix elements of B were read gives you the total number of accesses. Let $$R_{tot}$$ be the total number of accesses made for elenmts in A and B.$$
        <p align="center">
        $$R_{tot} = A_{reads} + B_{reads} = 2 \times 32,768 = 65,536$$
        <p>

    * **Compute the total DRAM traffic in bytes for the full matrix multiply, assuming every element access goes to DRAM (no data reuse)**<br>

        <p align="center">
        $$\text{READS}_{\text{bytes}} = A_{tot} \times 4 \text{ bytes} = 262,144 \text{ bytes}$$
        <p>

        There will be $262$ KB of reads to produce $4.1$ KB of outputs.


2) **Tiled loop (tile size T=8): the computation is blocked into T×T tiles. Compute the number of DRAM loads for A and B tiles across the full computation. Compute total DRAM traffic in bytes.**

    * **Compute the number of DRAM loads for A and B tiles across the full computation.**<br>

        To compute the number of DRAM loads is obtained in the same way as in Question 1). 
        <p align="center">
        $$R_{tot} = A_{loads} + B_{loads} = 2 \times 32^2 = 2,048$$
        <p>


    * **Compute the total DRAM traffic in bytes**<br>
        <p align="center">
        $$\text{READS}_{\text{bytes}} = R_{tot} \times 4 \text{ bytes} = 2,048 \times 4 = 8,192 \text{ bytes}$$
        <p>

3) **Compute the ratio of naive DRAM traffic to tiled DRAM traffic. Explain in one sentence why this ratio equals N/T.**

    <p align="center">
    $$\frac{262,144}{8,192} = 32$ = \frac{N}{T} = \frac{32}{8} = 4$$
    <p>
    


4) **If DRAM bandwidth is 320 GB/s and compute is 10 TFLOPS, compute execution time for the naive case (memory-bound) and the tiled case. For each, state whether the bottleneck is compute or memory.**





