// 4x4 binary-weight crossbar MAC unit
// out[j] = sum_i( weight[i][j] * in[i] )  (combinational output, registered weights)
// Weights: +1 = 2'sb01, -1 = 2'sb11 (signed 2-bit)
// Inputs: 8-bit signed; Outputs: 11-bit signed (range ±508 fits in 11 bits)

module crossbar_mac #(
    parameter N     = 4,
    parameter IN_W  = 8,
    parameter OUT_W = 11
)(
    input  logic                    clk,
    input  logic                    rst_n,
    input  logic                    weight_wr,
    input  logic [1:0]              weight_row,
    input  logic [1:0]              weight_col,
    input  logic signed [1:0]       weight_in,
    // Flattened packed input bus: in_flat[i] = in_vec[i]
    input  logic signed [N*IN_W-1:0]  in_flat,
    output logic signed [N*OUT_W-1:0] out_flat
);

    logic signed [1:0] weights [0:N-1][0:N-1];  // weights[row_i][col_j]

    integer idx_i, idx_j;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (idx_i = 0; idx_i < N; idx_i = idx_i+1)
                for (idx_j = 0; idx_j < N; idx_j = idx_j+1)
                    weights[idx_i][idx_j] <= 2'sb01;
        end else if (weight_wr) begin
            weights[weight_row][weight_col] <= weight_in;
        end
    end

    // Helper wires for each input element (signed, sign-extended to OUT_W)
    wire signed [OUT_W-1:0] sx [0:N-1];
    genvar k;
    generate
        for (k = 0; k < N; k = k+1) begin : sx_gen
            assign sx[k] = {{(OUT_W-IN_W){in_flat[k*IN_W + IN_W-1]}},
                             in_flat[k*IN_W +: IN_W]};
        end
    endgenerate

    // MAC for each output column
    logic signed [OUT_W-1:0] col_acc [0:N-1];
    genvar gj;
    generate
        for (gj = 0; gj < N; gj = gj+1) begin : col_loop
            always_comb begin
                col_acc[gj] = '0;
                for (idx_i = 0; idx_i < N; idx_i = idx_i+1) begin
                    if (weights[idx_i][gj] == 2'sb01)
                        col_acc[gj] = col_acc[gj] + sx[idx_i];
                    else
                        col_acc[gj] = col_acc[gj] - sx[idx_i];
                end
            end
            assign out_flat[gj*OUT_W +: OUT_W] = col_acc[gj];
        end
    endgenerate

endmodule
