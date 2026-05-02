# CLLM Codefeast #5

A 2×2 weight-stationary systolic array computes C = A × B where: A = [[1, 2], [3, 4]], B = [[5, 6], [7, 8]], expected C = [[19, 22], [43, 50]]. In weight-stationary dataflow, weights are pre-loaded into PEs and stay fixed; inputs stream in from the left; partial sums accumulate downward.

1) **Draw the 2×2 array of processing elements (PEs). Label each PE with its preloaded weight: PE[0][0] = B[0][0] = 5, PE[0][1] = B[0][1] = 6, PE[1][0] = B[1][0] = 7, PE[1][1] = B[1][1] = 8.**<br>


```
+----------+----------+
| PE[0][0] | PE[0][1] |
|  w = 5   |  w = 6   |
|----------|----------|
| PE[1][0] | PE[1][1] |
|  w = 7   |  w = 8   |
|----------|----------|
```


2)  **Fill in a cycle-by-cycle table (columns: Cycle, Input to row 0, Input to row 1, PE[0][0] partial sum, PE[0][1] partial sum, PE[1][0] partial sum, PE[1][1] partial sum, Output C values). Trace at least 4 cycles.**<br>



| Cycle   |Row 0 Input   | Row 1 Input    | PE[0][0] partial sum | PE[0][1] partial sum | PE[1][0] partial sum  |  PE[1][1] partial sum |  Output C | 
|---------|--------------|----------------|----------------------|----------------------|-----------------------|-----------------------|-----------| 
| 1       | A[0][0] = 1  |                |  A[0][0] x 5 = 5     | P[0][0] x 6 = 6      |                       |                       |           | 
| 2       | A[1][0] = 3  | A[0][1] = 2    |  A[1][0] x 5 = 15    | A[1][0] x 6 = 18     | 5 + (2 x 7) = 19      |  6 + (2 x 8) = 22     |[19, 22]   | 
| 3       |              | A[1][1] = 4    |                      |                      | 15 + (4 x 7) = 43     |  18 + (4 x 8) = 50    |[43, 50]   | 
| 4       |              |                |                      |                      |                       |                       |           | 

3) **Count: (a) total MAC operations performed; (b) number of times each input value is reused; (c) number of off-chip memory accesses for A, B (as inputs), and C (as output).**

(a) **Total Number of MACs**<br>
    
Let $$C_i$$ be the number of MACs for the $i$ th cycle.<br>
    

$$\begin{align*}
\text{MACs} &=  C_1 + C_2 + C_3 + C_4\\
            &= 2 + 4 + 2 + 0\\
            &= 8\\
\end{align*}$$ 

The total number of MACs is $$\text{MACs} = 8$$.<br>

(b) **Number of Times Each input Value is Reused**

    By looking at the table from Quesiton 2, we see each input is reaused twice.



4) **if this were output-stationary instead, which values would stay fixed in the PEs? Give a one-sentence answer**
