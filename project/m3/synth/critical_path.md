# Critical Path Analysis — crossbar_top

## Start Point
**Register:** `G[k][j]` — the conductance register array inside `memristor_crossbar`,
implemented as `$_SDFFE_PN0P_` cells (synchronous reset, enable, active-low reset).
Specifically, the 8-bit conductance value `G[k][col]` for the current row `k` and
each output column `col ∈ {0,1,2,3}`.

## End Point
**Register:** `result_N` (N ∈ {0,1,2,3}) — the 32-bit output latches at the bottom of
`memristor_crossbar`, implemented as `$_DFFE_PP_` cells. These are written on the
rising clock edge when `act_last=1` and `act_valid=1`, latching the final accumulated
column current `acc[j] + G[k][j] × act_data`.

## Logic Stages on the Critical Path

```
G[k][j]  ──→  sign_extend(8→32)  ──→  Mult(8×8 signed)  ──→  Add(acc[j] + product)  ──→  Mux(act_last)  ──→  result_N.D
```

| Stage | Logic | Estimated delay (sky130, tt/25°C) |
|-------|-------|----------------------------------|
| 1 | G[k][j] Q output → sign extension wires | ~0 ns |
| 2 | Signed 8×8 Wallace tree (4 XOR levels + partial products) | ~1.76 ns |
| 3 | 16-bit carry-propagate adder (partial products → sum) | ~0.80 ns |
| 4 | 32-bit accumulator adder (sum + acc[j]) | ~1.60 ns |
| 5 | 2:1 mux controlled by `act_last` | ~0.40 ns |
| 6 | Setup time at result_N.D | ~0.15 ns |
| **Total** | | **~4.71 ns** |

## Why This Is the Critical Path

This path is the longest because it chains three major arithmetic operations:
(1) an 8×8 signed multiply, (2) a 16→32-bit widening adder for the partial products,
and (3) a 32-bit accumulator add. All three execute combinationally between the G
register clock edge and the result register setup window. No other path in the design
comes close — the AXI4-Lite handshake logic consists only of register-to-mux-to-register
paths (~1–2 ns) and the conductance load path is a single register write (~0.5 ns).

The multiplier dominates because a signed 8×8 multiply in a generic techmap produces
a Wallace tree of 4 XOR stages plus carry-propagate adders. In sky130_fd_sc_hd, each
XOR2 gate is ~0.26 ns and each AND2 is ~0.18 ns; four levels of reduction give ~1.76 ns
before even reaching the accumulator.

## What Would Shorten It

1. **Pipeline the multiply-accumulate** — insert a register between the multiplier
   output and the accumulator input. This breaks the 4.71 ns path into two ~2.3 ns
   stages, raising the maximum frequency from ~200 MHz to ~430 MHz at the cost of
   one extra cycle of latency per MVM.

2. **Replace the generic multiplier with a DSP block** — on FPGA targets (Xilinx,
   Intel), a DSP48/DSP block performs an 8×8 signed MAC in a single clock at 200+ MHz
   with no logic-level delay. On sky130 (ASIC), no hardened DSP is available, so
   the only option is pipelining or Booth encoding to reduce partial products.

3. **Booth encoding** — a radix-4 Booth encoder reduces the number of partial products
   from 8 to 4, cutting the Wallace tree depth by one level (~0.4 ns saved) and
   shrinking the XOR count by ~30%.

4. **Reduce accumulator width** — if precision analysis (M2) confirms that 16-bit
   output is sufficient, halving the accumulator from 32→16 bits cuts the adder
   delay from ~1.60 ns to ~0.80 ns, giving a total path of ~3.91 ns → ~256 MHz.
