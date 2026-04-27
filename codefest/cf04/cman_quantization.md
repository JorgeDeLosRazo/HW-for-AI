# CMAN Codefest \#4

ou are given the following 4×4 FP32 weight matrix W:<br>


$$W = \begin{bmatrix} 
0.85 & -1.20 & 0.34 & 2.10 \\
-0.07 & 0.91 & -1.88 & 0.12 \\
1.55 & 0.03 & -0.44 & -2.31\\ 
-0.18 & 1.03 & 0.77 & 0.55\\  
\end{bmatrix}$$
       
1) **Scale factor. Compute S using symmetric per-tensor quantization: S = max(|W|) / 127. Show the max value and the computed S.**<br>
Note that max(|W|) = 2.31, therefore S is the following:<br>

$$ S = \frac{max(|W|)}{127} = \frac{2.31}{127} = 0.018188976378 $$

2) **Quantize. Quantize each element: W_q = round(W / S). Clamp to [−128, 127]. Write out the full 4×4 INT8 matrix.**

$$W_q = \begin{bmatrix} 
47 & -66 & 19 & 115\\
-4 & 50 & -103 & 7\\
85 & 2 & 24 & 127\\
-10 & 57 & 42 & 30\\
\end{bmatrix}$$

3) **Dequantize. Compute W_deq = W_q × S. Write out the 4×4 FP32 dequantized matrix.**

4) **Error analysis. Compute the per-element absolute error |W − W_deq|. Identify the element with the largest error and compute the Mean Absolute Error (MAE) across all 16 elements.**

5) **Bad scale experiment. Use S_bad = 0.01 (too small). Repeat quantization and dequantization. Compute the MAE. Explain in one sentence what goes wrong when S is too small**