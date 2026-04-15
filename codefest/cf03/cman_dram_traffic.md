# CMAN for Codefest #3

## Tasks
1) Naive triple loop (ijk order): for computing one output element C[i][j] = Σ A[i][k]×B[k][j], how many times is each element of B accessed? Across the full N×N output, how many total element accesses are made to A and B? Compute total DRAM traffic in bytes for the full matrix multiply, assuming every element access goes to DRAM (no data reuse).