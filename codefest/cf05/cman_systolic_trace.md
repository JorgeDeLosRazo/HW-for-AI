# CMAN Codefeast #5

A 2×2 weight-stationary systolic array computes C = A × B where: A = [[1, 2], [3, 4]], B = [[5, 6], [7, 8]], expected C = [[19, 22], [43, 50]]. In weight-stationary dataflow, weights are pre-loaded into PEs and stay fixed; inputs stream in from the left; partial sums accumulate downward.

1) **Draw the 2×2 array of processing elements (PEs). Label each PE with its preloaded weight: PE[0][0] = B[0][0] = 5, PE[0][1] = B[0][1] = 6, PE[1][0] = B[1][0] = 7, PE[1][1] = B[1][1] = 8.**

+----+
|----|



2)  **Fill in a cycle-by-cycle table (columns: Cycle, Input to row 0, Input to row 1, PE[0][0] partial sum, PE[0][1] partial sum, PE[1][0] partial sum, PE[1][1] partial sum, Output C values). Trace at least 4 cycles.**

3) **Count: (a) total MAC operations performed; (b) number of times each input value is reused; (c) number of off-chip memory accesses for A, B (as inputs), and C (as output).**

4) **if this were output-stationary instead, which values would stay fixed in the PEs? Give a one-sentence answer**