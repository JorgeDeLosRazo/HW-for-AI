/*
 * tb_interface.sv
 * Testbench for interface.sv (AXI4-Lite slave wrapping compute_core).
 *
 * Tests:
 *   1. AXI4-Lite write transactions: load identity-matrix weights via WLOAD,
 *      write activations [1,2,3,4] via ACT_DATA + CTRL.
 *   2. AXI4-Lite read transactions: poll STATUS until done=1, then read
 *      RESULT0..RESULT3 and verify y=[1,2,3,4].
 *
 * Prints PASS or FAIL on stdout.
 */
`timescale 1ns/1ps

module tb_interface;

    // -------------------------------------------------------------------------
    // DUT signals
    // -------------------------------------------------------------------------
    logic        aclk, aresetn;

    logic        awvalid; logic        awready;
    logic [7:0]  awaddr;  logic [2:0]  awprot;

    logic        wvalid;  logic        wready;
    logic [31:0] wdata;   logic [3:0]  wstrb;

    logic        bvalid;  logic        bready;
    logic [1:0]  bresp;

    logic        arvalid; logic        arready;
    logic [7:0]  araddr;  logic [2:0]  arprot;

    logic        rvalid;  logic        rready;
    logic [31:0] rdata;   logic [1:0]  rresp;

    // -------------------------------------------------------------------------
    // DUT
    // -------------------------------------------------------------------------
    axi_interface dut (.*);

    // -------------------------------------------------------------------------
    // Clock: 10 ns period
    // -------------------------------------------------------------------------
    initial aclk = 1'b0;
    always #5 aclk = ~aclk;

    // -------------------------------------------------------------------------
    // AXI4-Lite helper tasks
    // -------------------------------------------------------------------------
    // Single write transaction.
    // Asserts awvalid+wvalid for exactly one clock cycle, then waits for bvalid.
    // Assumes the interface is idle (awready=1, wready=1) when called.
    task automatic axi_write(input [7:0] addr, input [31:0] data);
        @(posedge aclk); #1;
        awvalid = 1'b1; awaddr = addr; awprot = 3'b000;
        wvalid  = 1'b1; wdata  = data; wstrb  = 4'hF;
        @(posedge aclk); #1;   // AW+W handshake captured this edge; deassert
        awvalid = 1'b0;
        wvalid  = 1'b0;
        bready  = 1'b1;
        @(posedge aclk);
        while (!bvalid) @(posedge aclk);
        #1; bready = 1'b0;
    endtask

    // Single read transaction.
    // Asserts arvalid for one clock cycle, then waits for rvalid.
    task automatic axi_read(input [7:0] addr, output [31:0] out);
        @(posedge aclk); #1;
        arvalid = 1'b1; araddr = addr; arprot = 3'b000;
        @(posedge aclk); #1;   // AR handshake captured; deassert
        arvalid = 1'b0;
        rready  = 1'b1;
        @(posedge aclk);
        while (!rvalid) @(posedge aclk);
        #1;
        out    = rdata;
        rready = 1'b0;
    endtask

    // -------------------------------------------------------------------------
    // Stimulus
    // -------------------------------------------------------------------------
    integer errors;
    logic [31:0] rd_val;
    integer poll;

    // WLOAD field encoding: [11:4]=weight_data, [3:2]=row, [1:0]=col
    function automatic [31:0] wload_word(
        input signed [7:0] wt,
        input [1:0]  row,
        input [1:0]  col
    );
        wload_word = {20'h0, wt, row, col};
    endfunction

    initial begin
        errors  = 0;
        awvalid = 1'b0; wvalid  = 1'b0; bready  = 1'b0;
        arvalid = 1'b0; rready  = 1'b0;
        awaddr  = 8'h0; wdata   = 32'h0; wstrb   = 4'hF;
        araddr  = 8'h0; awprot  = 3'b0;  arprot  = 3'b0;
        aresetn = 1'b0;

        repeat (3) @(posedge aclk);
        #1; aresetn = 1'b1;
        repeat (2) @(posedge aclk);

        // ==================================================================
        // Load identity weight matrix via 16 WLOAD writes (addr 0x08)
        // ==================================================================
        axi_write(8'h08, wload_word( 8'sd1, 2'd0, 2'd0));
        axi_write(8'h08, wload_word( 8'sd0, 2'd0, 2'd1));
        axi_write(8'h08, wload_word( 8'sd0, 2'd0, 2'd2));
        axi_write(8'h08, wload_word( 8'sd0, 2'd0, 2'd3));
        axi_write(8'h08, wload_word( 8'sd0, 2'd1, 2'd0));
        axi_write(8'h08, wload_word( 8'sd1, 2'd1, 2'd1));
        axi_write(8'h08, wload_word( 8'sd0, 2'd1, 2'd2));
        axi_write(8'h08, wload_word( 8'sd0, 2'd1, 2'd3));
        axi_write(8'h08, wload_word( 8'sd0, 2'd2, 2'd0));
        axi_write(8'h08, wload_word( 8'sd0, 2'd2, 2'd1));
        axi_write(8'h08, wload_word( 8'sd1, 2'd2, 2'd2));
        axi_write(8'h08, wload_word( 8'sd0, 2'd2, 2'd3));
        axi_write(8'h08, wload_word( 8'sd0, 2'd3, 2'd0));
        axi_write(8'h08, wload_word( 8'sd0, 2'd3, 2'd1));
        axi_write(8'h08, wload_word( 8'sd0, 2'd3, 2'd2));
        axi_write(8'h08, wload_word( 8'sd1, 2'd3, 2'd3));

        // ==================================================================
        // Stream activations x=[1,2,3,4] via ACT_DATA (0x0C) + CTRL (0x00)
        //   CTRL[0]=act_valid, CTRL[1]=act_last
        // ==================================================================
        axi_write(8'h0C, 32'h01); axi_write(8'h00, 32'h1);  // x[0]=1, valid
        axi_write(8'h0C, 32'h02); axi_write(8'h00, 32'h1);  // x[1]=2, valid
        axi_write(8'h0C, 32'h03); axi_write(8'h00, 32'h1);  // x[2]=3, valid
        axi_write(8'h0C, 32'h04); axi_write(8'h00, 32'h3);  // x[3]=4, last

        // ==================================================================
        // Poll STATUS (0x04) until done=1 (max 50 cycles)
        // ==================================================================
        poll = 0;
        rd_val = 32'h0;
        while (rd_val[0] !== 1'b1 && poll < 50) begin
            axi_read(8'h04, rd_val);
            poll = poll + 1;
        end
        if (rd_val[0] !== 1'b1) begin
            $display("INTERFACE FAIL: STATUS never set done");
            errors = errors + 1;
        end

        // ==================================================================
        // Read RESULT0..3 and verify against identity-matrix reference
        // ==================================================================
        axi_read(8'h10, rd_val);
        if (rd_val !== 32'd1) begin
            $display("INTERFACE FAIL: RESULT0=%0d expected 1", rd_val);
            errors = errors + 1;
        end

        axi_read(8'h14, rd_val);
        if (rd_val !== 32'd2) begin
            $display("INTERFACE FAIL: RESULT1=%0d expected 2", rd_val);
            errors = errors + 1;
        end

        axi_read(8'h18, rd_val);
        if (rd_val !== 32'd3) begin
            $display("INTERFACE FAIL: RESULT2=%0d expected 3", rd_val);
            errors = errors + 1;
        end

        axi_read(8'h1C, rd_val);
        if (rd_val !== 32'd4) begin
            $display("INTERFACE FAIL: RESULT3=%0d expected 4", rd_val);
            errors = errors + 1;
        end

        // ==================================================================
        // Summary
        // ==================================================================
        repeat (2) @(posedge aclk);
        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL: %0d error(s)", errors);

        $finish;
    end

endmodule
