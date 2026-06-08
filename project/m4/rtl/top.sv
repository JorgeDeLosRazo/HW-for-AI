/*
 * top.sv  —  M4 integrated top module
 * Memristor Crossbar Analog AI Accelerator
 *
 * Instantiates axi_interface and compute_core and connects them.
 * No glue logic required: the interface exposes compute_core control ports
 * directly; signals wire point-to-point with no clock crossings, FIFOs,
 * or width converters.
 *
 * External port list:
 *   clk      in   1    100 MHz rising-edge system clock
 *   rst_n    in   1    synchronous active-low reset
 *   -- AXI4-Lite slave (ARM IHI0022E, 32-bit data, 8-bit address) --
 *   awvalid  in   1    write address valid
 *   awready  out  1    write address ready
 *   awaddr   in   8    write byte address
 *   awprot   in   3    write protection (ignored)
 *   wvalid   in   1    write data valid
 *   wready   out  1    write data ready
 *   wdata    in   32   write data
 *   wstrb    in   4    write strobes
 *   bvalid   out  1    write response valid
 *   bready   in   1    write response ready
 *   bresp    out  2    write response (OKAY)
 *   arvalid  in   1    read address valid
 *   arready  out  1    read address ready
 *   araddr   in   8    read byte address
 *   arprot   in   3    read protection (ignored)
 *   rvalid   out  1    read data valid
 *   rready   in   1    read data ready
 *   rdata    out  32   read data
 *   rresp    out  2    read response (OKAY)
 */

module crossbar_top (
    input  logic        clk,
    input  logic        rst_n,

    input  logic        awvalid,
    output logic        awready,
    input  logic [7:0]  awaddr,
    input  logic [2:0]  awprot,

    input  logic        wvalid,
    output logic        wready,
    input  logic [31:0] wdata,
    input  logic [3:0]  wstrb,

    output logic        bvalid,
    input  logic        bready,
    output logic [1:0]  bresp,

    input  logic        arvalid,
    output logic        arready,
    input  logic [7:0]  araddr,
    input  logic [2:0]  arprot,

    output logic        rvalid,
    input  logic        rready,
    output logic [31:0] rdata,
    output logic [1:0]  rresp
);

    // Inter-module signals (interface → compute_core)
    logic        cc_wload_en;
    logic [1:0]  cc_wload_row, cc_wload_col;
    logic signed [7:0]  cc_wload_data;
    logic        cc_act_valid, cc_act_last;
    logic signed [7:0]  cc_act_data;
    logic        cc_result_valid;
    logic signed [31:0] cc_result_0, cc_result_1, cc_result_2, cc_result_3;

    // AXI4-Lite interface (M4: exposes compute_core ports externally)
    axi_interface u_iface (
        .clk            (clk),
        .rst_n          (rst_n),
        .awvalid        (awvalid),
        .awready        (awready),
        .awaddr         (awaddr),
        .awprot         (awprot),
        .wvalid         (wvalid),
        .wready         (wready),
        .wdata          (wdata),
        .wstrb          (wstrb),
        .bvalid         (bvalid),
        .bready         (bready),
        .bresp          (bresp),
        .arvalid        (arvalid),
        .arready        (arready),
        .araddr         (araddr),
        .arprot         (arprot),
        .rvalid         (rvalid),
        .rready         (rready),
        .rdata          (rdata),
        .rresp          (rresp),
        .cc_wload_en    (cc_wload_en),
        .cc_wload_row   (cc_wload_row),
        .cc_wload_col   (cc_wload_col),
        .cc_wload_data  (cc_wload_data),
        .cc_act_valid   (cc_act_valid),
        .cc_act_last    (cc_act_last),
        .cc_act_data    (cc_act_data),
        .cc_result_valid(cc_result_valid),
        .cc_result_0    (cc_result_0),
        .cc_result_1    (cc_result_1),
        .cc_result_2    (cc_result_2),
        .cc_result_3    (cc_result_3)
    );

    // Memristor crossbar compute core
    compute_core u_core (
        .clk          (clk),
        .rst_n        (rst_n),
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

endmodule
