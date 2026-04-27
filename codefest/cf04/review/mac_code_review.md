# MAC Code Review — Codefest 4 CLLM

## LLM Attribution

| File | LLM | Model version |
|---|---|---|
| `mac_llm_A.v` | Claude | claude-sonnet-4-6 |
| `mac_llm_B.v` | GPT-4o | gpt-4o-2024-08-06 |
| `mac_correct.v` | Hand-corrected | — |

---

## Compilation Results

All three files compiled without errors under `iverilog -g2012 -Wall`:

```
iverilog -g2012 -Wall mac_llm_A.v   → exit 0 (no errors)
iverilog -g2012 -Wall mac_llm_B.v   → exit 0 (no errors)
iverilog -g2012 -Wall mac_correct.v → exit 0 (no errors)
```

No compile errors means **both bugs are silent** — they are not caught at elaboration time,
only exposed by simulation with signed inputs.

---

## Simulation Results

### mac_llm_A.v

```
PASS cycle 1: out = 12
PASS cycle 2: out = 24
PASS cycle 3: out = 36
PASS reset:   out = 0
FAIL cycle 5: expected -10, got 502
FAIL cycle 6: expected -20, got 1004
2 TEST(S) FAILED
```

### mac_llm_B.v

```
PASS cycle 1: out = 12
PASS cycle 2: out = 24
PASS cycle 3: out = 36
PASS reset:   out = 0
FAIL cycle 5: expected -10, got 33554422
FAIL cycle 6: expected -20, got 67108844
2 TEST(S) FAILED
```

### mac_correct.v

```
PASS cycle 1: out = 12
PASS cycle 2: out = 24
PASS cycle 3: out = 36
PASS reset:   out = 0
PASS cycle 5: out = -10
PASS cycle 6: out = -20
ALL TESTS PASSED
```

---

## Issue 1 — Missing `signed` on input ports (mac_llm_A.v)

### Offending lines

```systemverilog
input  logic [7:0]  a,   // line 9
input  logic [7:0]  b,   // line 10
```

### Why it is wrong

The specification requires `a` and `b` to be **8-bit signed** operands. Without the `signed`
qualifier, `a` and `b` are treated as unsigned `logic [7:0]`. When the accumulator computes
`a * b`, the multiplication is unsigned. The value `-5` (8'hFB) is interpreted as unsigned
`251` instead. The product `251 × 2 = 502` is accumulated instead of `-10`, which explains
the observed simulation failure.

The test cases with positive operands (a=3, b=4) all pass because positive values have the
same binary representation whether signed or unsigned.

### Corrected version

```systemverilog
input  logic signed [7:0]  a,
input  logic signed [7:0]  b,
```

---

## Issue 2 — Incorrect sign-extension width in manual concatenation (mac_llm_B.v)

### Offending lines

```systemverilog
out <= out + {{16{a[7]}}, a} * {{16{b[7]}}, b};   // line 20
```

### Why it is wrong

The intent is to sign-extend the 8-bit operands to 32 bits before multiplying. However,
`{16{a[7]}, a}` produces only **24 bits** (16 sign bits + 8 data bits), not 32. The resulting
multiplication is performed on 24-bit values, producing a 48-bit intermediate that is then
truncated when assigned to the 32-bit `out` register.

For `a = -5` (8'hFB) and `b = 2`:
- `{{16{a[7]}}, a}` = 24'hFFFFFB = 16,777,211 (treated as unsigned in a 24-bit context)
- 16,777,211 × 2 = 33,554,422 — matching the observed wrong output exactly.

The correct sign-extension for 32 bits requires **24 sign bits** prefix: `{{24{a[7]}}, a}`.

### Corrected version

```systemverilog
out <= out + (32'(signed'(a)) * 32'(signed'(b)));
```

---

## Issue 3 — `always` instead of `always_ff` (mac_llm_B.v)

### Offending lines

```systemverilog
always @(posedge clk) begin    // line 16
```

### Why it is wrong

The specification requires `always_ff`. Plain `always` with an explicit sensitivity list is
Verilog-2001 style and is accepted by simulators, but `always_ff` is the SystemVerilog
construct specifically intended for sequential flip-flop logic. Synthesis and formal tools
(Yosys, Synopsys DC, JasperGold) use `always_ff` as a hint that this block **must** infer
registers. Using plain `always` removes that guarantee and may produce warnings or incorrect
inferences. It also prevents lint tools from flagging missing sensitivity list entries.

### Corrected version

```systemverilog
always_ff @(posedge clk) begin
```

---

## mac_correct.v — Final corrected implementation

```systemverilog
module mac (
    input  logic        clk,
    input  logic        rst,
    input  logic signed [7:0]  a,
    input  logic signed [7:0]  b,
    output logic signed [31:0] out
);

    always_ff @(posedge clk) begin
        if (rst) begin
            out <= 32'sd0;
        end else begin
            out <= out + (32'(signed'(a)) * 32'(signed'(b)));
        end
    end

endmodule
```

Key corrections:
- `logic signed [7:0]` on both inputs — preserves sign semantics
- `32'(signed'(a))` — sign-extends each operand to 32 bits before multiplying
- `always_ff` — correct SystemVerilog sequential construct
- `32'sd0` — typed signed zero for reset (consistent with output type)
