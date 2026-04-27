// Correct synthesizable SystemVerilog MAC unit
// Fixes: explicit sign extension via 32-bit cast on signed operands before multiply,
//        always_ff, logic types throughout.

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
            // Sign-extend both operands to 32 bits before multiplying.
            // This guarantees the product is a 32-bit signed value and that
            // the accumulation preserves sign for all negative inputs.
            out <= out + (32'(signed'(a)) * 32'(signed'(b)));
        end
    end

endmodule
