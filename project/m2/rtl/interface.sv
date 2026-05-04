/*
 * interface.sv
 * AXI4-Lite slave interface wrapping compute_core.
 *
 * Note: module is named axi_interface because "interface" is a reserved
 * keyword in SystemVerilog.  The file is named interface.sv per the M2
 * submission spec.
 *
 * Protocol: AXI4-Lite (ARM IHI0022E), 32-bit data, 8-bit address.
 * Clock polarity/phase: rising edge, AMBA-standard.
 * Reset: synchronous active-low (aresetn).
 * Clock domain: single (aclk), no crossings.
 *
 * Register map (byte-addressed, 32-bit words):
 *   0x00  CTRL      R/W  [1]=act_last, [0]=act_valid.  Writing with [0]=1
 *                        pulses act_valid to compute_core for 1 cycle,
 *                        using the value in ACT_DATA.  Self-clearing.
 *   0x04  STATUS    RO   [0]=done (sticky; set when result_valid fires,
 *                        cleared on any read of STATUS).
 *   0x08  WLOAD     R/W  [11:4]=weight_data (signed INT8), [3:2]=wload_row,
 *                        [1:0]=wload_col.  Write pulses wload_en for 1 cycle.
 *   0x0C  ACT_DATA  R/W  [7:0]=act_data (signed INT8).  Stored; used when
 *                        CTRL is written with act_valid=1.
 *   0x10  RESULT0   RO   y[0] from compute_core (latched on result_valid)
 *   0x14  RESULT1   RO   y[1]
 *   0x18  RESULT2   RO   y[2]
 *   0x1C  RESULT3   RO   y[3]
 *
 * AXI4-Lite port list:
 *   aclk     in  1    clock
 *   aresetn  in  1    synchronous active-low reset
 *   awvalid  in  1    write address valid
 *   awready  out 1    write address ready
 *   awaddr   in  8    write byte address
 *   awprot   in  3    write protection (ignored, tied to OKAY)
 *   wvalid   in  1    write data valid
 *   wready   out 1    write data ready
 *   wdata    in  32   write data
 *   wstrb    in  4    write strobes (ignored; all bytes written)
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
 */

module axi_interface (
    input  logic        aclk,
    input  logic        aresetn,

    // Write address channel
    input  logic        awvalid,
    output logic        awready,
    input  logic [7:0]  awaddr,
    input  logic [2:0]  awprot,

    // Write data channel
    input  logic        wvalid,
    output logic        wready,
    input  logic [31:0] wdata,
    input  logic [3:0]  wstrb,

    // Write response channel
    output logic        bvalid,
    input  logic        bready,
    output logic [1:0]  bresp,

    // Read address channel
    input  logic        arvalid,
    output logic        arready,
    input  logic [7:0]  araddr,
    input  logic [2:0]  arprot,

    // Read data channel
    output logic        rvalid,
    input  logic        rready,
    output logic [31:0] rdata,
    output logic [1:0]  rresp
);

    // -------------------------------------------------------------------------
    // Internal registers
    // -------------------------------------------------------------------------
    logic signed [7:0]  act_data_r;   // ACT_DATA register
    logic               done_r;       // sticky done flag
    logic signed [31:0] res_r [0:3];  // latched results

    // -------------------------------------------------------------------------
    // Compute core wiring
    // -------------------------------------------------------------------------
    logic        cc_wload_en;
    logic [1:0]  cc_wload_row, cc_wload_col;
    logic signed [7:0]  cc_wload_data;
    logic        cc_act_valid, cc_act_last;
    logic signed [7:0]  cc_act_data;
    logic        cc_result_valid;
    logic signed [31:0] cc_result_0, cc_result_1, cc_result_2, cc_result_3;

    compute_core u_core (
        .clk          (aclk),
        .rst_n        (aresetn),
        .wload_en     (cc_wload_en),
        .wload_row    (cc_wload_row),
        .wload_col    (cc_wload_col),
        .wload_data   (cc_wload_data),
        .act_valid    (cc_act_valid),
        .act_last     (cc_act_last),
        .act_data     (cc_act_data),
        .result_valid (cc_result_valid),
        .result_0     (cc_result_0),
        .result_1     (cc_result_1),
        .result_2     (cc_result_2),
        .result_3     (cc_result_3)
    );

    // -------------------------------------------------------------------------
    // AXI4-Lite write path
    // Latch AW and W phases independently; perform register write when both
    // have been received; hold BVALID until master asserts BREADY.
    // -------------------------------------------------------------------------
    logic        aw_active;
    logic [7:0]  aw_addr_r;
    logic        w_active;
    logic [31:0] wr_data_r;
    logic        write_en;

    assign write_en = aw_active & w_active & !bvalid;
    assign awready  = !aw_active;
    assign wready   = !w_active;
    assign bresp    = 2'b00;

    // Write address latch
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            aw_active <= 1'b0;
            aw_addr_r <= 8'h00;
        end else begin
            if (awvalid & awready) begin
                aw_active <= 1'b1;
                aw_addr_r <= awaddr;
            end else if (write_en) begin
                aw_active <= 1'b0;
            end
        end
    end

    // Write data latch
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            w_active  <= 1'b0;
            wr_data_r <= 32'h0;
        end else begin
            if (wvalid & wready) begin
                w_active  <= 1'b1;
                wr_data_r <= wdata;
            end else if (write_en) begin
                w_active <= 1'b0;
            end
        end
    end

    // Write response
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            bvalid <= 1'b0;
        end else begin
            if (write_en)
                bvalid <= 1'b1;
            else if (bvalid & bready)
                bvalid <= 1'b0;
        end
    end

    // Register write + compute_core control pulses
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            act_data_r    <= 8'sd0;
            cc_wload_en   <= 1'b0;
            cc_wload_row  <= 2'd0;
            cc_wload_col  <= 2'd0;
            cc_wload_data <= 8'sd0;
            cc_act_valid  <= 1'b0;
            cc_act_last   <= 1'b0;
            cc_act_data   <= 8'sd0;
        end else begin
            // Self-clear control pulses every cycle
            cc_wload_en  <= 1'b0;
            cc_act_valid <= 1'b0;
            cc_act_last  <= 1'b0;

            if (write_en) begin
                case (aw_addr_r[4:0])
                    5'h00: begin  // CTRL
                        if (wr_data_r[0]) begin
                            cc_act_valid <= 1'b1;
                            cc_act_last  <= wr_data_r[1];
                            cc_act_data  <= act_data_r;
                        end
                    end
                    5'h08: begin  // WLOAD
                        cc_wload_en   <= 1'b1;
                        cc_wload_col  <= wr_data_r[1:0];
                        cc_wload_row  <= wr_data_r[3:2];
                        cc_wload_data <= wr_data_r[11:4];
                    end
                    5'h0C: begin  // ACT_DATA
                        act_data_r <= wr_data_r[7:0];
                    end
                    default: ;
                endcase
            end
        end
    end

    // Latch results when compute_core fires result_valid
    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            done_r   <= 1'b0;
            res_r[0] <= 32'sd0;
            res_r[1] <= 32'sd0;
            res_r[2] <= 32'sd0;
            res_r[3] <= 32'sd0;
        end else begin
            if (cc_result_valid) begin
                done_r   <= 1'b1;
                res_r[0] <= cc_result_0;
                res_r[1] <= cc_result_1;
                res_r[2] <= cc_result_2;
                res_r[3] <= cc_result_3;
            end
            // STATUS read clears done
            if (rvalid & rready & (ar_addr_r[4:0] == 5'h04))
                done_r <= 1'b0;
        end
    end

    // -------------------------------------------------------------------------
    // AXI4-Lite read path
    // Accept read address; return data one cycle later.
    // -------------------------------------------------------------------------
    logic        ar_active;
    logic [7:0]  ar_addr_r;

    assign arready = !ar_active;
    assign rresp   = 2'b00;

    always_ff @(posedge aclk) begin
        if (!aresetn) begin
            ar_active <= 1'b0;
            ar_addr_r <= 8'h00;
            rvalid    <= 1'b0;
            rdata     <= 32'h0;
        end else begin
            if (arvalid & arready) begin
                ar_active <= 1'b1;
                ar_addr_r <= araddr;
            end

            if (ar_active & !rvalid) begin
                ar_active <= 1'b0;
                rvalid    <= 1'b1;
                case (ar_addr_r[4:0])
                    5'h00: rdata <= 32'h0;          // CTRL (WO view)
                    5'h04: rdata <= {31'h0, done_r}; // STATUS
                    5'h08: rdata <= 32'h0;           // WLOAD (WO)
                    5'h0C: rdata <= {24'h0, act_data_r}; // ACT_DATA
                    5'h10: rdata <= res_r[0];         // RESULT0
                    5'h14: rdata <= res_r[1];         // RESULT1
                    5'h18: rdata <= res_r[2];         // RESULT2
                    5'h1C: rdata <= res_r[3];         // RESULT3
                    default: rdata <= 32'hDEADBEEF;
                endcase
            end

            if (rvalid & rready)
                rvalid <= 1'b0;
        end
    end

endmodule
