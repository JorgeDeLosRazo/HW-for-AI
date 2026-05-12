
# CMAN Codefest 6

Consider the 2×2 resistive crossbar below. Rows carry input voltages; columns carry output currents. Cell
resistances are fixed: R[0][0] = 1 kΩ, R[0][1] = 2 kΩ, R[1][0] = 2 kΩ, R[1][1] = 1 kΩ. The low-resistance cells
(1 kΩ) encode “on” weights; the high-resistance cells (2 kΩ) encode “off” weights.

![](../../images/cf06-crossbar.png)

1) **Ideal read. Apply V_row0 = 1 V to row 0. Assume col 0 is held at virtual ground (0 V) for current sensing, and that row 1 and col 1 are also grounded. Compute the ideal output current I_col0.**

$$I_{col0} = \frac{V_{row0}}{1k\Omega} = \frac{1V}{1k\Omega} = 1\text{mA}$$

2) **Sneak path read. Now apply V_row0 = 1 V to row 0 and hold col 0 at 0 V, but leave row 1 and col 1 floating (undriven). Use Kirchhoff's Current Law (KCL) to find the floating node voltages V_row1 and V_col1, then compute the actual current I_col0 including the sneak path contribution.**

KCL at Column 1:
   
 $$
 \begin{align*}
 \frac{V_{row0} - V_{col1}}{R[0][1]} + \frac{V_{row1} - V_{col1}}{R[1][1]} &= 0\\
 \frac{1 - V_{col1}}{2k\Omega} + \frac{V_{row1} - V_{col1}}{1k\Omega} &= 0\\
 2V_{row1} - 3V_{col1} &= -1\\
 \end{align*}
 $$


KCL at Row 1:

 $$
 \begin{align*}
 \frac{V_{row1} - V_{col0}}{R[1][0]} + \frac{V_{row1} - V_{col1}}{R[1][1]} &= 0\\
 \frac{V_{row1} - 0}{2k\Omega} + \frac{V_{row1} - V_{col1}}{1k\Omega} &= 0\\
 3V_{row1} - 2V_{col1} = 0//
 \end{align*}
 $$

 Using the KCL euqations for Column 1 and Row 1 and solving for $V_{row1}$ and $V_{col1}$, we get the following voltages:

 $$
 \begin{align*}
 V_{col1} &= 0.03V//
 V_{row1} &= 0.2V//
 \end{align*}
  

4) **In 2–3 sentences, explain why the sneak path current corrupts the intended Matrix Vector Multiplication (MVM) result and what it implies for reading large crossbar arrays.**

 
