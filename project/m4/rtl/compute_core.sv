/*
 * compute_core.sv  —  M4 memristor crossbar compute core
 *
 * Implements the 4×4 resistive crossbar MVM:
 *   I_col[j] = Σ_{i=0}^{3} G[i][j] × V_row[i]   (Ohm's law in-memory compute)
 *
 * G[i][j] is a signed INT8 conductance value representing the memristor state:
 *   G_on  = +64  (high-conductance, "on" cell  — encodes weight +1 in normalized form)
 *   G_off = −64  (low-conductance,  "off" cell — encodes weight −1 via differential)
 *
 * The computation is performed digitally each clock cycle. In a physical analog
 * crossbar, this MVM executes simultaneously in hardware via Kirchhoff's current
 * law; the RTL model captures the functional result for verification and synthesis.
 *
 * Port list:
 *   clk          in   1    rising-edge system clock (100 MHz nominal)
 *   rst_n        in   1    synchronous active-low reset
 *   wload_en     in   1    conductance-load strobe (one cell per clock)
 *   wload_row    in   2    row index i   (0–3)
 *   wload_col    in   2    column index j (0–3)
 *   wload_data   in   8    signed INT8 conductance G[i][j]
 *   act_valid    in   1    voltage input valid (V[k] presented this cycle)
 *   act_last     in   1    high on 4th voltage; triggers output latch
 *   act_data     in   8    signed INT8 voltage V[k]
 *   result_valid out  1    column current results valid (1-cycle pulse)
 *   result_0     out  32   signed INT32 I_col[0]
 *   result_1     out  32   signed INT32 I_col[1]
 *   result_2     out  32   signed INT32 I_col[2]
 *   result_3     out  32   signed INT32 I_col[3]
 */

module compute_core (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        wload_en,
    input  logic [1:0]  wload_row,
    input  logic [1:0]  wload_col,
    input  logic signed [7:0]  wload_data,

    input  logic        act_valid,
    input  logic        act_last,
    input  logic signed [7:0]  act_data,

    output logic        result_valid,
    output logic signed [31:0] result_0,
    output logic signed [31:0] result_1,
    output logic signed [31:0] result_2,
    output logic signed [31:0] result_3
);

    logic signed [7:0]  G   [0:3][0:3];   // conductance array G[row][col]
    logic signed [31:0] acc [0:3];         // column current accumulators
    logic [1:0]         k;                 // current voltage row pointer

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
                    G[r][c] <= 8'sd0;
            for (int j = 0; j < 4; j++)
                acc[j] <= 32'sd0;
        end else begin
            result_valid <= 1'b0;

            if (wload_en)
                G[wload_row][wload_col] <= wload_data;

            if (act_valid) begin
                if (act_last) begin
                    result_0 <= acc[0] + (32'(signed'(act_data)) * 32'(signed'(G[k][0])));
                    result_1 <= acc[1] + (32'(signed'(act_data)) * 32'(signed'(G[k][1])));
                    result_2 <= acc[2] + (32'(signed'(act_data)) * 32'(signed'(G[k][2])));
                    result_3 <= acc[3] + (32'(signed'(act_data)) * 32'(signed'(G[k][3])));
                    for (int j = 0; j < 4; j++) acc[j] <= 32'sd0;
                    result_valid <= 1'b1;
                    k <= 2'd0;
                end else begin
                    acc[0] <= acc[0] + (32'(signed'(act_data)) * 32'(signed'(G[k][0])));
                    acc[1] <= acc[1] + (32'(signed'(act_data)) * 32'(signed'(G[k][1])));
                    acc[2] <= acc[2] + (32'(signed'(act_data)) * 32'(signed'(G[k][2])));
                    acc[3] <= acc[3] + (32'(signed'(act_data)) * 32'(signed'(G[k][3])));
                    k <= k + 1;
                end
            end
        end
    end

endmodule
