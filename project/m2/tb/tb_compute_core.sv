/*
 * tb_compute_core.sv
 * Testbench for compute_core.sv
 *
 * Two test vectors (derived from Python reference — see README):
 *   Test 1: Identity matrix, x=[1,2,3,4] → expected y=[1,2,3,4]
 *   Test 2: Signed weights and activations,
 *           W=[[2,-1,0,1],[-1,2,1,0],[0,1,2,-1],[1,0,-1,2]],
 *           x=[3,-2,1,4] → expected y=[12,-6,-4,10]
 *
 * Prints PASS or FAIL on stdout.
 * Dumps waveform to compute_core.vcd.
 */
`timescale 1ns/1ps

module tb_compute_core;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    logic        clk, rst_n;
    logic        wload_en;
    logic [1:0]  wload_row, wload_col;
    logic signed [7:0]  wload_data;
    logic        act_valid, act_last;
    logic signed [7:0]  act_data;
    logic        result_valid;
    logic signed [31:0] result_0, result_1, result_2, result_3;

    // -------------------------------------------------------------------------
    // DUT instantiation
    // -------------------------------------------------------------------------
    compute_core dut (
        .clk         (clk),
        .rst_n       (rst_n),
        .wload_en    (wload_en),
        .wload_row   (wload_row),
        .wload_col   (wload_col),
        .wload_data  (wload_data),
        .act_valid   (act_valid),
        .act_last    (act_last),
        .act_data    (act_data),
        .result_valid(result_valid),
        .result_0    (result_0),
        .result_1    (result_1),
        .result_2    (result_2),
        .result_3    (result_3)
    );

    // -------------------------------------------------------------------------
    // Clock: 10 ns period (100 MHz)
    // -------------------------------------------------------------------------
    initial clk = 1'b0;
    always #5 clk = ~clk;

    // -------------------------------------------------------------------------
    // VCD dump
    // -------------------------------------------------------------------------
    initial begin
        $dumpfile("compute_core.vcd");
        $dumpvars(0, tb_compute_core);
    end

    // -------------------------------------------------------------------------
    // Helpers
    // -------------------------------------------------------------------------
    integer errors;

    // Load one weight (asserts wload_en for the current cycle)
    task automatic load_w(input [1:0] row, col,
                          input signed [7:0] val);
        @(posedge clk); #1;
        wload_en   = 1'b1;
        wload_row  = row;
        wload_col  = col;
        wload_data = val;
    endtask

    // Send one activation
    task automatic send_a(input signed [7:0] val, input logic last);
        @(posedge clk); #1;
        act_valid = 1'b1;
        act_last  = last;
        act_data  = val;
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    initial begin
        errors    = 0;
        rst_n     = 1'b0;
        wload_en  = 1'b0;
        act_valid = 1'b0;
        act_last  = 1'b0;
        act_data  = 8'sd0;
        wload_row = 2'd0; wload_col = 2'd0; wload_data = 8'sd0;

        // Hold reset for 3 cycles
        repeat (3) @(posedge clk);
        #1; rst_n = 1'b1;

        // ==================================================================
        // Test 1: Identity weight matrix, activations [1,2,3,4]
        // Expected result: y = [1, 2, 3, 4]
        // Reference: y[j] = sum_k x[k]*I[k][j] = x[j]
        // ==================================================================

        // Load W = identity
        load_w(2'd0, 2'd0, 8'sd1); load_w(2'd0, 2'd1, 8'sd0);
        load_w(2'd0, 2'd2, 8'sd0); load_w(2'd0, 2'd3, 8'sd0);
        load_w(2'd1, 2'd0, 8'sd0); load_w(2'd1, 2'd1, 8'sd1);
        load_w(2'd1, 2'd2, 8'sd0); load_w(2'd1, 2'd3, 8'sd0);
        load_w(2'd2, 2'd0, 8'sd0); load_w(2'd2, 2'd1, 8'sd0);
        load_w(2'd2, 2'd2, 8'sd1); load_w(2'd2, 2'd3, 8'sd0);
        load_w(2'd3, 2'd0, 8'sd0); load_w(2'd3, 2'd1, 8'sd0);
        load_w(2'd3, 2'd2, 8'sd0); load_w(2'd3, 2'd3, 8'sd1);

        @(posedge clk); #1;
        wload_en = 1'b0;

        // Stream activations x = [1, 2, 3, 4]
        send_a(8'sd1, 1'b0);
        send_a(8'sd2, 1'b0);
        send_a(8'sd3, 1'b0);
        send_a(8'sd4, 1'b1);  // last

        // Deassert and collect result (available 1 cycle after act_last edge)
        @(posedge clk); #1;
        act_valid = 1'b0;
        act_last  = 1'b0;

        if (result_valid !== 1'b1) begin
            $display("TEST1 FAIL: result_valid not asserted");
            errors = errors + 1;
        end
        if (result_0 !== 32'sd1) begin
            $display("TEST1 FAIL: result_0=%0d expected 1", result_0);
            errors = errors + 1;
        end
        if (result_1 !== 32'sd2) begin
            $display("TEST1 FAIL: result_1=%0d expected 2", result_1);
            errors = errors + 1;
        end
        if (result_2 !== 32'sd3) begin
            $display("TEST1 FAIL: result_2=%0d expected 3", result_2);
            errors = errors + 1;
        end
        if (result_3 !== 32'sd4) begin
            $display("TEST1 FAIL: result_3=%0d expected 4", result_3);
            errors = errors + 1;
        end

        // ==================================================================
        // Test 2: Signed weights with negative activations
        // W = [[2,-1,0,1],[-1,2,1,0],[0,1,2,-1],[1,0,-1,2]]
        // x = [3,-2,1,4]
        // y[0] = 3*2 + (-2)*(-1) + 1*0 + 4*1 = 12
        // y[1] = 3*(-1) + (-2)*2 + 1*1 + 4*0 = -6
        // y[2] = 3*0 + (-2)*1 + 1*2 + 4*(-1) = -4
        // y[3] = 3*1 + (-2)*0 + 1*(-1) + 4*2 = 10
        // ==================================================================

        // Reload W for test 2
        load_w(2'd0, 2'd0,  8'sd2); load_w(2'd0, 2'd1, -8'sd1);
        load_w(2'd0, 2'd2,  8'sd0); load_w(2'd0, 2'd3,  8'sd1);
        load_w(2'd1, 2'd0, -8'sd1); load_w(2'd1, 2'd1,  8'sd2);
        load_w(2'd1, 2'd2,  8'sd1); load_w(2'd1, 2'd3,  8'sd0);
        load_w(2'd2, 2'd0,  8'sd0); load_w(2'd2, 2'd1,  8'sd1);
        load_w(2'd2, 2'd2,  8'sd2); load_w(2'd2, 2'd3, -8'sd1);
        load_w(2'd3, 2'd0,  8'sd1); load_w(2'd3, 2'd1,  8'sd0);
        load_w(2'd3, 2'd2, -8'sd1); load_w(2'd3, 2'd3,  8'sd2);

        @(posedge clk); #1;
        wload_en = 1'b0;

        // Stream activations x = [3, -2, 1, 4]
        send_a( 8'sd3, 1'b0);
        send_a(-8'sd2, 1'b0);
        send_a( 8'sd1, 1'b0);
        send_a( 8'sd4, 1'b1);  // last

        @(posedge clk); #1;
        act_valid = 1'b0;
        act_last  = 1'b0;

        if (result_valid !== 1'b1) begin
            $display("TEST2 FAIL: result_valid not asserted");
            errors = errors + 1;
        end
        if (result_0 !== 32'sd12) begin
            $display("TEST2 FAIL: result_0=%0d expected 12", result_0);
            errors = errors + 1;
        end
        if (result_1 !== -32'sd6) begin
            $display("TEST2 FAIL: result_1=%0d expected -6", result_1);
            errors = errors + 1;
        end
        if (result_2 !== -32'sd4) begin
            $display("TEST2 FAIL: result_2=%0d expected -4", result_2);
            errors = errors + 1;
        end
        if (result_3 !== 32'sd10) begin
            $display("TEST2 FAIL: result_3=%0d expected 10", result_3);
            errors = errors + 1;
        end

        // ==================================================================
        // Summary
        // ==================================================================
        repeat (2) @(posedge clk);
        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL: %0d error(s)", errors);

        $finish;
    end

endmodule
