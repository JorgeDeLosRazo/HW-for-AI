/*
 * compute_core.sv
 * Weight-stationary 4x4 MAC array targeting the aten::addmm linear-projection
 * kernel identified in M1 profiling (63.2% of GPT-2 CPU time).
 *
 * Computes y[j] = sum_{k=0}^{3} x[k] * W[k][j]  for j in {0,1,2,3}
 * (one row of the output matrix per invocation).
 *
 * Port list:
 *   clk          in   1    rising-edge system clock
 *   rst_n        in   1    synchronous active-low reset
 *   wload_en     in   1    weight-load enable; one weight latched per cycle
 *   wload_row    in   2    weight matrix row  index k (0–3)
 *   wload_col    in   2    weight matrix col  index j (0–3)
 *   wload_data   in   8    signed INT8 weight value W[k][j]
 *   act_valid    in   1    activation input valid this cycle
 *   act_last     in   1    high on the 4th (final) activation; triggers output
 *   act_data     in   8    signed INT8 activation x[k]
 *   result_valid out  1    result registers hold valid output (1-cycle pulse)
 *   result_0     out  32   signed INT32 accumulated output y[0]
 *   result_1     out  32   signed INT32 accumulated output y[1]
 *   result_2     out  32   signed INT32 accumulated output y[2]
 *   result_3     out  32   signed INT32 accumulated output y[3]
 *
 * Reset:  synchronous, active-low (rst_n)
 * Clock:  single domain (clk), no crossings
 */

module compute_core (
    input  logic        clk,
    input  logic        rst_n,

    // Weight preload interface
    input  logic        wload_en,
    input  logic [1:0]  wload_row,
    input  logic [1:0]  wload_col,
    input  logic signed [7:0]  wload_data,

    // Activation stream
    input  logic        act_valid,
    input  logic        act_last,
    input  logic signed [7:0]  act_data,

    // Result outputs
    output logic        result_valid,
    output logic signed [31:0] result_0,
    output logic signed [31:0] result_1,
    output logic signed [31:0] result_2,
    output logic signed [31:0] result_3
);

    logic signed [7:0]  W   [0:3][0:3];  // W[row k][col j]
    logic signed [31:0] acc [0:3];
    logic [1:0]         k;               // activation counter (which row of W to use)

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            result_valid <= 1'b0;
            result_0     <= 32'sd0;
            result_1     <= 32'sd0;
            result_2     <= 32'sd0;
            result_3     <= 32'sd0;
            k            <= 2'd0;
            for (int r = 0; r < 4; r++)
                for (int c = 0; c < 4; c++)
                    W[r][c] <= 8'sd0;
            for (int j = 0; j < 4; j++)
                acc[j] <= 32'sd0;
        end else begin
            result_valid <= 1'b0;

            if (wload_en)
                W[wload_row][wload_col] <= wload_data;

            if (act_valid) begin
                if (act_last) begin
                    // Final activation: accumulate and latch results
                    result_0 <= acc[0] + (32'(signed'(act_data)) * 32'(signed'(W[k][0])));
                    result_1 <= acc[1] + (32'(signed'(act_data)) * 32'(signed'(W[k][1])));
                    result_2 <= acc[2] + (32'(signed'(act_data)) * 32'(signed'(W[k][2])));
                    result_3 <= acc[3] + (32'(signed'(act_data)) * 32'(signed'(W[k][3])));
                    for (int j = 0; j < 4; j++)
                        acc[j] <= 32'sd0;
                    result_valid <= 1'b1;
                    k <= 2'd0;
                end else begin
                    acc[0] <= acc[0] + (32'(signed'(act_data)) * 32'(signed'(W[k][0])));
                    acc[1] <= acc[1] + (32'(signed'(act_data)) * 32'(signed'(W[k][1])));
                    acc[2] <= acc[2] + (32'(signed'(act_data)) * 32'(signed'(W[k][2])));
                    acc[3] <= acc[3] + (32'(signed'(act_data)) * 32'(signed'(W[k][3])));
                    k <= k + 1;
                end
            end
        end
    end

endmodule
