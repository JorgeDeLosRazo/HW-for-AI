// Testbench for mac module
// Sequence: a=3,b=4 for 3 cycles; assert rst; a=-5,b=2 for 2 cycles
`timescale 1ns/1ps

module mac_tb;

    logic        clk;
    logic        rst;
    logic signed [7:0]  a;
    logic signed [7:0]  b;
    logic signed [31:0] out;

    mac dut (
        .clk(clk),
        .rst(rst),
        .a(a),
        .b(b),
        .out(out)
    );

    // 10 ns clock
    initial clk = 0;
    always #5 clk = ~clk;

    integer errors = 0;

    task check(input signed [31:0] expected, input [63:0] cycle_num);
        @(posedge clk); #1;
        if (out !== expected) begin
            $display("FAIL cycle %0d: expected %0d, got %0d", cycle_num, expected, out);
            errors = errors + 1;
        end else begin
            $display("PASS cycle %0d: out = %0d", cycle_num, out);
        end
    endtask

    initial begin
        // Reset
        rst = 1; a = 0; b = 0;
        @(posedge clk); #1;
        rst = 0;

        // Phase 1: a=3, b=4 for 3 cycles  → accumulates 12, 24, 36
        a = 8'sd3; b = 8'sd4;
        check(32'sd12,  1);
        check(32'sd24,  2);
        check(32'sd36,  3);

        // Assert reset → out must clear to 0
        rst = 1;
        @(posedge clk); #1;
        if (out !== 32'sd0) begin
            $display("FAIL reset: expected 0, got %0d", out);
            errors = errors + 1;
        end else
            $display("PASS reset: out = 0");
        rst = 0;

        // Phase 2: a=-5, b=2 for 2 cycles → accumulates -10, -20
        a = -8'sd5; b = 8'sd2;
        check(-32'sd10, 5);
        check(-32'sd20, 6);

        if (errors == 0)
            $display("ALL TESTS PASSED");
        else
            $display("%0d TEST(S) FAILED", errors);

        $finish;
    end

endmodule
