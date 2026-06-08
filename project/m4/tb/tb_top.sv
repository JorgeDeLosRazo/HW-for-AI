/*
 * tb_top.sv  —  M3 end-to-end co-simulation testbench
 * Memristor Crossbar Analog AI Accelerator
 *
 * Tests data flow from host → AXI4-Lite interface → memristor crossbar → result.
 * The testbench drives ONLY AXI4-Lite transactions; no direct access to
 * compute-core ports. This mirrors what a real host CPU would do.
 *
 * Test case (dominant kernel: 4×4 MVM matching M1 profiled workload tile):
 *
 *   Conductance matrix G[i][j] (G_on=+64, G_off=-64):
 *     row0: [ +64, -64, +64, -64 ]
 *     row1: [ +64, +64, -64, -64 ]
 *     row2: [ -64, +64, +64, -64 ]
 *     row3: [ -64, -64, -64, +64 ]
 *
 *   Voltage input vector V: [1, 2, 3, 4]
 *
 *   Hand-calculated column currents I[j] = Σ_i G[i][j] × V[i]:
 *     I[0] = (+64)(1)+(+64)(2)+(-64)(3)+(-64)(4) = 64*(1+2-3-4) = -256
 *     I[1] = (-64)(1)+(+64)(2)+(+64)(3)+(-64)(4) = 64*(-1+2+3-4) =    0
 *     I[2] = (+64)(1)+(-64)(2)+(+64)(3)+(-64)(4) = 64*(1-2+3-4)  = -128
 *     I[3] = (-64)(1)+(-64)(2)+(-64)(3)+(+64)(4) = 64*(-1-2-3+4) = -128
 */

`timescale 1ns/1ps

module tb_top;

    // DUT signals
    logic        clk    = 1'b0;
    logic        rst_n  = 1'b0;
    logic        awvalid= 1'b0;
    logic        awready;
    logic [7:0]  awaddr = 8'h00;
    logic [2:0]  awprot = 3'b000;
    logic        wvalid = 1'b0;
    logic        wready;
    logic [31:0] wdata  = 32'h0;
    logic [3:0]  wstrb  = 4'hF;
    logic        bvalid;
    logic        bready = 1'b0;
    logic [1:0]  bresp;
    logic        arvalid= 1'b0;
    logic        arready;
    logic [7:0]  araddr = 8'h00;
    logic [2:0]  arprot = 3'b000;
    logic        rvalid;
    logic        rready = 1'b0;
    logic [31:0] rdata;
    logic [1:0]  rresp;

    crossbar_top dut (.*);

    always #5 clk = ~clk;   // 100 MHz

    // ------------------------------------------------------------------
    // AXI4-Lite write task
    // ------------------------------------------------------------------
    task automatic axi_write(input [7:0] addr, input [31:0] d);
        @(negedge clk);
        awvalid = 1'b1; awaddr = addr;
        wvalid  = 1'b1; wdata  = d;
        // Wait until both channels accepted
        fork
            begin @(posedge clk); while (!awready) @(posedge clk); end
            begin @(posedge clk); while (!wready)  @(posedge clk); end
        join
        @(negedge clk);
        awvalid = 1'b0; wvalid = 1'b0;
        // Wait for write response
        bready = 1'b1;
        @(posedge clk); while (!bvalid) @(posedge clk);
        @(negedge clk); bready = 1'b0;
    endtask

    // ------------------------------------------------------------------
    // AXI4-Lite read task
    // ------------------------------------------------------------------
    task automatic axi_read(input [7:0] addr, output [31:0] d);
        @(negedge clk);
        arvalid = 1'b1; araddr = addr;
        @(posedge clk); while (!arready) @(posedge clk);
        @(negedge clk); arvalid = 1'b0;
        rready = 1'b1;
        @(posedge clk); while (!rvalid) @(posedge clk);
        d = rdata;
        @(negedge clk); rready = 1'b0;
    endtask

    // ------------------------------------------------------------------
    // Load one conductance value via WLOAD register
    // WLOAD[11:4]=conductance [3:2]=row [1:0]=col
    // ------------------------------------------------------------------
    task automatic load_G(input [1:0] row, input [1:0] col,
                          input signed [7:0] gval);
        logic [31:0] wd;
        wd = {20'h0, gval, row, col};
        axi_write(8'h08, wd);
    endtask

    // ------------------------------------------------------------------
    // Send one voltage sample via ACT_DATA + CTRL
    // ------------------------------------------------------------------
    task automatic send_V(input signed [7:0] v, input logic last);
        axi_write(8'h0C, {24'h0, v});           // write ACT_DATA
        axi_write(8'h00, {30'h0, last, 1'b1});  // write CTRL: act_valid=1
    endtask

    // ------------------------------------------------------------------
    // Main test sequence
    // ------------------------------------------------------------------
    localparam signed [7:0] GON =  8'sd64;
    localparam signed [7:0] GOF = -8'sd64;

    logic [31:0] rd;
    logic signed [31:0] got [0:3];
    localparam signed [31:0] EXP0 = -32'sd256;
    localparam signed [31:0] EXP1 =  32'sd0;
    localparam signed [31:0] EXP2 = -32'sd128;
    localparam signed [31:0] EXP3 = -32'sd128;

    integer pass_cnt, fail_cnt;

    initial begin
        $dumpfile("cosim.vcd");
        $dumpvars(0, tb_top);

        // Reset
        rst_n = 1'b0;
        repeat(3) @(posedge clk);
        @(negedge clk); rst_n = 1'b1;

        // ---- Phase 1: load conductance matrix (host write transactions) ----
        // row0: [ +64, -64, +64, -64 ]
        load_G(2'd0, 2'd0, GON); load_G(2'd0, 2'd1, GOF);
        load_G(2'd0, 2'd2, GON); load_G(2'd0, 2'd3, GOF);
        // row1: [ +64, +64, -64, -64 ]
        load_G(2'd1, 2'd0, GON); load_G(2'd1, 2'd1, GON);
        load_G(2'd1, 2'd2, GOF); load_G(2'd1, 2'd3, GOF);
        // row2: [ -64, +64, +64, -64 ]
        load_G(2'd2, 2'd0, GOF); load_G(2'd2, 2'd1, GON);
        load_G(2'd2, 2'd2, GON); load_G(2'd2, 2'd3, GOF);
        // row3: [ -64, -64, -64, +64 ]
        load_G(2'd3, 2'd0, GOF); load_G(2'd3, 2'd1, GOF);
        load_G(2'd3, 2'd2, GOF); load_G(2'd3, 2'd3, GON);

        // ---- Phase 2: stream voltage inputs (compute activity) ----
        send_V(8'sd1, 1'b0);  // V[0]=1
        send_V(8'sd2, 1'b0);  // V[1]=2
        send_V(8'sd3, 1'b0);  // V[2]=3
        send_V(8'sd4, 1'b1);  // V[3]=4, last → triggers MVM completion

        // Wait for STATUS[done]=1
        rd = 32'h0;
        while (!rd[0]) axi_read(8'h04, rd);

        // ---- Phase 3: read column current results (host read transactions) ----
        axi_read(8'h10, rd); got[0] = $signed(rd);
        axi_read(8'h14, rd); got[1] = $signed(rd);
        axi_read(8'h18, rd); got[2] = $signed(rd);
        axi_read(8'h1C, rd); got[3] = $signed(rd);

        // ---- Verification ----
        $display("=== M3 co-simulation results (memristor crossbar MVM) ===");
        $display("Input V = [1, 2, 3, 4]");
        $display("%-8s  %-10s  %-10s  %-6s", "result", "got", "expected", "status");
        pass_cnt = 0; fail_cnt = 0;

        if (got[0] === EXP0) begin $display("I_col[0]  %10d  %10d  PASS", got[0], EXP0); pass_cnt++; end
        else                 begin $display("I_col[0]  %10d  %10d  FAIL", got[0], EXP0); fail_cnt++; end
        if (got[1] === EXP1) begin $display("I_col[1]  %10d  %10d  PASS", got[1], EXP1); pass_cnt++; end
        else                 begin $display("I_col[1]  %10d  %10d  FAIL", got[1], EXP1); fail_cnt++; end
        if (got[2] === EXP2) begin $display("I_col[2]  %10d  %10d  PASS", got[2], EXP2); pass_cnt++; end
        else                 begin $display("I_col[2]  %10d  %10d  FAIL", got[2], EXP2); fail_cnt++; end
        if (got[3] === EXP3) begin $display("I_col[3]  %10d  %10d  PASS", got[3], EXP3); pass_cnt++; end
        else                 begin $display("I_col[3]  %10d  %10d  FAIL", got[3], EXP3); fail_cnt++; end

        $display("--- %0d/4 checks passed ---", pass_cnt);
        if (fail_cnt == 0)
            $display("PASS");
        else
            $display("FAIL");

        $finish;
    end

endmodule
