/*
 * interface.sv  —  M4 AXI4-Lite slave interface
 *
 * AXI4-Lite slave exposing compute_core control ports externally so that
 * top.sv can instantiate compute_core independently and wire them together.
 * Protocol and register map are unchanged from M2/M3.
 *
 * Protocol: AXI4-Lite (ARM IHI0022E), 32-bit data, 8-bit address.
 * Reset: synchronous active-low (rst_n). Clock: single domain (clk).
 *
 * Register map (byte-addressed):
 *   0x00  CTRL      [1]=act_last [0]=act_valid  (write-only, self-clearing)
 *   0x04  STATUS    [0]=done     (sticky; cleared on STATUS read)
 *   0x08  WLOAD     [11:4]=conductance_data [3:2]=row [1:0]=col
 *   0x0C  ACT_DATA  [7:0]=voltage input (signed INT8)
 *   0x10  RESULT0   I_col[0]  (read-only, latched on result_valid)
 *   0x14  RESULT1   I_col[1]
 *   0x18  RESULT2   I_col[2]
 *   0x1C  RESULT3   I_col[3]
 *
 * External port list:
 *   clk      in  1    clock
 *   rst_n    in  1    synchronous active-low reset
 *   -- AXI4-Lite slave ports (ARM AMBA 32-bit, 8-bit addr) --
 *   awvalid  in  1    write address valid
 *   awready  out 1    write address ready
 *   awaddr   in  8    write byte address
 *   awprot   in  3    write protection (ignored)
 *   wvalid   in  1    write data valid
 *   wready   out 1    write data ready
 *   wdata    in  32   write data
 *   wstrb    in  4    write strobes (all bytes written)
 *   bvalid   out 1    write response valid
 *   bready   in  1    write response ready
 *   bresp    out 2    write response (OKAY = 2'b00)
 *   arvalid  in  1    read address valid
 *   arready  out 1    read address ready
 *   araddr   in  8    read byte address
 *   arprot   in  3    read protection (ignored)
 *   rvalid   out 1    read data valid
 *   rready   in  1    read data ready
 *   rdata    out 32   read data
 *   rresp    out 2    read response (OKAY = 2'b00)
 *   -- compute_core control ports (connected by top.sv) --
 *   cc_wload_en    out 1   conductance load strobe
 *   cc_wload_row   out 2   row index
 *   cc_wload_col   out 2   column index
 *   cc_wload_data  out 8   signed INT8 conductance
 *   cc_act_valid   out 1   voltage valid
 *   cc_act_last    out 1   last voltage flag
 *   cc_act_data    out 8   signed INT8 voltage
 *   cc_result_valid in  1  result ready pulse from compute_core
 *   cc_result_0    in  32  I_col[0]
 *   cc_result_1    in  32  I_col[1]
 *   cc_result_2    in  32  I_col[2]
 *   cc_result_3    in  32  I_col[3]
 */

module axi_interface (
    input  logic        clk,
    input  logic        rst_n,

    // AXI4-Lite write address channel
    input  logic        awvalid,
    output logic        awready,
    input  logic [7:0]  awaddr,
    input  logic [2:0]  awprot,

    // AXI4-Lite write data channel
    input  logic        wvalid,
    output logic        wready,
    input  logic [31:0] wdata,
    input  logic [3:0]  wstrb,

    // AXI4-Lite write response channel
    output logic        bvalid,
    input  logic        bready,
    output logic [1:0]  bresp,

    // AXI4-Lite read address channel
    input  logic        arvalid,
    output logic        arready,
    input  logic [7:0]  araddr,
    input  logic [2:0]  arprot,

    // AXI4-Lite read data channel
    output logic        rvalid,
    input  logic        rready,
    output logic [31:0] rdata,
    output logic [1:0]  rresp,

    // Compute core control interface (wired by top.sv)
    output logic        cc_wload_en,
    output logic [1:0]  cc_wload_row,
    output logic [1:0]  cc_wload_col,
    output logic signed [7:0]  cc_wload_data,
    output logic        cc_act_valid,
    output logic        cc_act_last,
    output logic signed [7:0]  cc_act_data,
    input  logic        cc_result_valid,
    input  logic signed [31:0] cc_result_0,
    input  logic signed [31:0] cc_result_1,
    input  logic signed [31:0] cc_result_2,
    input  logic signed [31:0] cc_result_3
);

    logic signed [7:0]  act_data_r;
    logic               done_r;
    logic signed [31:0] res_r [0:3];

    logic        aw_active;
    logic [7:0]  aw_addr_r;
    logic        w_active;
    logic [31:0] wr_data_r;
    logic        write_en;

    assign write_en = aw_active & w_active & !bvalid;
    assign awready  = !aw_active;
    assign wready   = !w_active;
    assign bresp    = 2'b00;

    always_ff @(posedge clk) begin
        if (!rst_n) begin aw_active <= 1'b0; aw_addr_r <= 8'h00; end
        else begin
            if (awvalid & awready) begin aw_active <= 1'b1; aw_addr_r <= awaddr; end
            else if (write_en) aw_active <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin w_active <= 1'b0; wr_data_r <= 32'h0; end
        else begin
            if (wvalid & wready) begin w_active <= 1'b1; wr_data_r <= wdata; end
            else if (write_en) w_active <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) bvalid <= 1'b0;
        else begin
            if (write_en) bvalid <= 1'b1;
            else if (bvalid & bready) bvalid <= 1'b0;
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            act_data_r    <= 8'sd0;
            cc_wload_en   <= 1'b0;
            cc_wload_row  <= 2'd0;
            cc_wload_col  <= 2'd0;
            cc_wload_data <= 8'sd0;
            cc_act_valid  <= 1'b0;
            cc_act_last   <= 1'b0;
            cc_act_data   <= 8'sd0;
        end else begin
            cc_wload_en  <= 1'b0;
            cc_act_valid <= 1'b0;
            cc_act_last  <= 1'b0;
            if (write_en) begin
                case (aw_addr_r[4:0])
                    5'h00: if (wr_data_r[0]) begin
                        cc_act_valid <= 1'b1;
                        cc_act_last  <= wr_data_r[1];
                        cc_act_data  <= act_data_r;
                    end
                    5'h08: begin
                        cc_wload_en   <= 1'b1;
                        cc_wload_col  <= wr_data_r[1:0];
                        cc_wload_row  <= wr_data_r[3:2];
                        cc_wload_data <= wr_data_r[11:4];
                    end
                    5'h0C: act_data_r <= wr_data_r[7:0];
                    default: ;
                endcase
            end
        end
    end

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            done_r <= 1'b0; res_r[0] <= 32'sd0; res_r[1] <= 32'sd0;
            res_r[2] <= 32'sd0; res_r[3] <= 32'sd0;
        end else begin
            if (cc_result_valid) begin
                done_r <= 1'b1; res_r[0] <= cc_result_0; res_r[1] <= cc_result_1;
                res_r[2] <= cc_result_2; res_r[3] <= cc_result_3;
            end
            if (rvalid & rready & (ar_addr_r[4:0] == 5'h04)) done_r <= 1'b0;
        end
    end

    logic        ar_active;
    logic [7:0]  ar_addr_r;

    assign arready = !ar_active;
    assign rresp   = 2'b00;

    always_ff @(posedge clk) begin
        if (!rst_n) begin
            ar_active <= 1'b0; ar_addr_r <= 8'h00; rvalid <= 1'b0; rdata <= 32'h0;
        end else begin
            if (arvalid & arready) begin ar_active <= 1'b1; ar_addr_r <= araddr; end
            if (ar_active & !rvalid) begin
                ar_active <= 1'b0; rvalid <= 1'b1;
                case (ar_addr_r[4:0])
                    5'h04: rdata <= {31'h0, done_r};
                    5'h10: rdata <= res_r[0];
                    5'h14: rdata <= res_r[1];
                    5'h18: rdata <= res_r[2];
                    5'h1C: rdata <= res_r[3];
                    default: rdata <= 32'h0;
                endcase
            end
            if (rvalid & rready) rvalid <= 1'b0;
        end
    end

endmodule
