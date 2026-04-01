// ============================================================
//  Testbench — 4-Bit Ripple-Carry Adder
//  Self-checking: exhaustively tests all 512 input combos
//  (a[3:0], b[3:0], cin) and reports PASS/FAIL per case.
// ============================================================
`timescale 1ns/1ps
 
module tb_adder4;
 
    // ── DUT ports ────────────────────────────────────────────
    reg  [3:0] a, b;
    reg        cin;
    wire [3:0] sum;
    wire       cout;
 
    // ── Instantiate DUT ──────────────────────────────────────
    adder4 dut (
        .a    (a),
        .b    (b),
        .cin  (cin),
        .sum  (sum),
        .cout (cout)
    );
 
    // ── Bookkeeping ──────────────────────────────────────────
    integer i;
    integer pass_cnt, fail_cnt;
    reg [4:0] expected;   // 5 bits: {cout_exp, sum_exp}
 
    // ── Test stimulus ────────────────────────────────────────
    initial begin
        pass_cnt = 0;
        fail_cnt = 0;
 
        $display("============================================");
        $display("  4-Bit Adder Exhaustive Testbench");
        $display("============================================");
        $display(" A     B    Cin | Sum  Cout | Expected | Result");
        $display("------------------------------------------------");
 
        // Sweep all 512 combinations of {a, b, cin}
        for (i = 0; i < 512; i = i + 1) begin
            {a, b, cin} = i[8:0];
            #10;  // allow combinational logic to settle
 
            expected = a + b + cin;  // reference model (5-bit)
 
            if ({cout, sum} === expected) begin
                pass_cnt = pass_cnt + 1;
                // Uncomment the line below to see every passing case:
                // $display("%04b + %04b + %b  | %04b  %b    | %05b    | PASS", a, b, cin, sum, cout, expected);
            end else begin
                fail_cnt = fail_cnt + 1;
                $display("FAIL: %04b + %04b + %b => got {cout,sum}=%b%04b, expected %05b",
                         a, b, cin, cout, sum, expected);
            end
        end
 
        // ── Summary ──────────────────────────────────────────
        $display("============================================");
        $display("  Results: %0d PASSED, %0d FAILED  (of 512)", pass_cnt, fail_cnt);
        if (fail_cnt == 0)
            $display("  *** ALL TESTS PASSED ***");
        else
            $display("  *** FAILURES DETECTED — see above ***");
        $display("============================================");
 
        $finish;
    end
 
    // ── Optional waveform dump ───────────────────────────────
    initial begin
        $dumpfile("adder4.vcd");
        $dumpvars(0, tb_adder4);
    end
 
endmodule