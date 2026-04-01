// ============================================================
//  4-Bit Ripple-Carry Adder with Carry-Out
// ============================================================
module adder4 (
    input  [3:0] a,      // 4-bit operand A
    input  [3:0] b,      // 4-bit operand B
    input        cin,    // carry-in
    output [3:0] sum,    // 4-bit sum
    output       cout    // carry-out
);
    assign {cout, sum} = a + b + cin;
endmodule
