// Testbench for crossbar_mac — 4x4 binary-weight crossbar MAC
//
// Weight matrix weight[i][j] loaded:
//   row0: [ +1, -1, +1, -1 ]
//   row1: [ +1, +1, -1, -1 ]
//   row2: [ -1, +1, +1, -1 ]
//   row3: [ -1, -1, -1, +1 ]
//
// Input vector: in = [10, 20, 30, 40]
//
// Hand-calculated expected outputs (out[j] = sum_i weight[i][j]*in[i]):
//   out[0] = (+1)(10)+(+1)(20)+(-1)(30)+(-1)(40) = 10+20-30-40 = -40
//   out[1] = (-1)(10)+(+1)(20)+(+1)(30)+(-1)(40) = -10+20+30-40 =  0
//   out[2] = (+1)(10)+(-1)(20)+(+1)(30)+(-1)(40) = 10-20+30-40  = -20
//   out[3] = (-1)(10)+(-1)(20)+(-1)(30)+(+1)(40) = -10-20-30+40 = -20

`timescale 1ns/1ps

module crossbar_tb;

    localparam N     = 4;
    localparam IN_W  = 8;
    localparam OUT_W = 11;

    localparam signed [1:0] WP = 2'sb01;   // +1
    localparam signed [1:0] WN = 2'sb11;   // -1

    logic                         clk       = 1'b0;
    logic                         rst_n     = 1'b0;
    logic                         weight_wr  = 1'b0;
    logic [1:0]                   weight_row = 2'b00;
    logic [1:0]                   weight_col = 2'b00;
    logic signed [1:0]            weight_in  = 2'sb01;
    logic signed [N*IN_W-1:0]     in_flat    = '0;
    logic signed [N*OUT_W-1:0]    out_flat;

    crossbar_mac #(.N(N), .IN_W(IN_W), .OUT_W(OUT_W)) dut (.*);

    always #5 clk = ~clk;  // 100 MHz

    // Helper task: write one weight
    task automatic write_weight(input [1:0] r, input [1:0] c, input signed [1:0] w);
        @(negedge clk);
        weight_wr  = 1'b1;
        weight_row = r;
        weight_col = c;
        weight_in  = w;
    endtask

    integer j;
    integer pass_cnt, fail_cnt;
    logic signed [OUT_W-1:0] got, exp_val;

    // Expected results per column
    logic signed [OUT_W-1:0] expected [0:N-1];

    initial begin
        expected[0] = -11'd40;
        expected[1] =  11'd0;
        expected[2] = -11'd20;
        expected[3] = -11'd20;

        // Reset
        rst_n = 1'b0;
        repeat(3) @(posedge clk);
        @(negedge clk); rst_n = 1'b1;

        // Load weight matrix row by row
        //   row0: [ +1, -1, +1, -1 ]
        write_weight(2'd0, 2'd0, WP);
        write_weight(2'd0, 2'd1, WN);
        write_weight(2'd0, 2'd2, WP);
        write_weight(2'd0, 2'd3, WN);
        //   row1: [ +1, +1, -1, -1 ]
        write_weight(2'd1, 2'd0, WP);
        write_weight(2'd1, 2'd1, WP);
        write_weight(2'd1, 2'd2, WN);
        write_weight(2'd1, 2'd3, WN);
        //   row2: [ -1, +1, +1, -1 ]
        write_weight(2'd2, 2'd0, WN);
        write_weight(2'd2, 2'd1, WP);
        write_weight(2'd2, 2'd2, WP);
        write_weight(2'd2, 2'd3, WN);
        //   row3: [ -1, -1, -1, +1 ]
        write_weight(2'd3, 2'd0, WN);
        write_weight(2'd3, 2'd1, WN);
        write_weight(2'd3, 2'd2, WN);
        write_weight(2'd3, 2'd3, WP);

        @(negedge clk); weight_wr = 1'b0;

        // Apply input vector [10, 20, 30, 40]
        // in_flat[i*IN_W +: IN_W] = in[i]
        in_flat[0*IN_W +: IN_W] = 8'sd10;
        in_flat[1*IN_W +: IN_W] = 8'sd20;
        in_flat[2*IN_W +: IN_W] = 8'sd30;
        in_flat[3*IN_W +: IN_W] = 8'sd40;

        @(posedge clk); #1;  // combinational output settles

        // Check and report
        $display("=== crossbar_mac simulation results ===");
        $display("Input: in[0]=10  in[1]=20  in[2]=30  in[3]=40");
        $display("out[j]   got   expected   status");

        pass_cnt = 0; fail_cnt = 0;
        for (j = 0; j < N; j = j+1) begin
            got     = $signed(out_flat[j*OUT_W +: OUT_W]);
            exp_val = $signed(expected[j]);
            if (got === exp_val) begin
                $display("out[%0d]  %5d  %5d      PASS", j, got, exp_val);
                pass_cnt = pass_cnt + 1;
            end else begin
                $display("out[%0d]  %5d  %5d      FAIL", j, got, exp_val);
                fail_cnt = fail_cnt + 1;
            end
        end

        $display("--- %0d/%0d checks passed ---", pass_cnt, N);
        if (fail_cnt == 0)
            $display("ALL TESTS PASSED");
        else
            $display("SOME TESTS FAILED");

        $finish;
    end

endmodule
