// wrapper for the pcie_axi_master and axi_ram modules
// this module is based on Alex Forencich's pcie_axi_master and axi_ram modules
// 
// portfolio of: Tyler Boardman
// date: 2026-01-01
// github: https://github.com/tylerboardman/cocotb-pcie



`resetall
`timescale 1ns / 1ps
`default_nettype none




module pcie_axi_ram_top
#(
    parameter TLP_DATA_WIDTH = 256,
    parameter TLP_STRB_WIDTH = TLP_DATA_WIDTH/32,
    parameter TLP_HDR_WIDTH = 128,
    parameter TLP_SEG_COUNT = 1,
    parameter AXI_DATA_WIDTH = 256,
    parameter AXI_ADDR_WIDTH = 16,
    parameter AXI_ID_WIDTH = 8,
    parameter AXI_MAX_BURST_LEN = 256
)
 (
    input  wire        clk,
    input  wire        rst,

    /*
     * PCIe TLP Interface (Incoming from cocotb/Testbench)
     */

    /*
     * TLP input (request)
     */
    input  wire [TLP_DATA_WIDTH-1:0]               rx_req_tlp_data,
    input  wire [TLP_STRB_WIDTH-1:0]               rx_req_tlp_strb,
    input  wire [TLP_SEG_COUNT*TLP_HDR_WIDTH-1:0]  rx_req_tlp_hdr,
    input  wire [TLP_SEG_COUNT-1:0]                rx_req_tlp_valid,
    input  wire [TLP_SEG_COUNT-1:0]                rx_req_tlp_sop,
    input  wire [TLP_SEG_COUNT-1:0]                rx_req_tlp_eop,
    output wire                                    rx_req_tlp_ready,

    /*
     * TLP output (completion)
     */
    output wire [TLP_DATA_WIDTH-1:0]               tx_cpl_tlp_data,
    output wire [TLP_STRB_WIDTH-1:0]               tx_cpl_tlp_strb,
    output wire [TLP_SEG_COUNT*TLP_HDR_WIDTH-1:0]  tx_cpl_tlp_hdr,
    output wire [TLP_SEG_COUNT-1:0]                tx_cpl_tlp_valid,
    output wire [TLP_SEG_COUNT-1:0]                tx_cpl_tlp_sop,
    output wire [TLP_SEG_COUNT-1:0]                tx_cpl_tlp_eop,
    input  wire                                    tx_cpl_tlp_ready,

    /*
     * Configuration
     */
    input  wire [15:0]                             completer_id,
    input  wire [2:0]                              max_payload_size,

    /*
     * Status
     */
    output wire                                    status_error_cor,
    output wire                                    status_error_uncor

);

    // Internal AXI Signals
    // These connect the Bridge (Master) to the RAM (Slave)

    wire [7:0]   m_axi_awid;
    wire [15:0]  m_axi_awaddr;
    wire [7:0]   m_axi_awlen;
    wire [2:0]   m_axi_awsize;
    wire [1:0]   m_axi_awburst;
    wire         m_axi_awlock;
    wire [3:0]   m_axi_awcache;
    wire [2:0]   m_axi_awprot;
    wire         m_axi_awvalid;
    wire         m_axi_awready;
    wire [31:0]  m_axi_wdata;
    wire [3:0]   m_axi_wstrb;
    wire         m_axi_wlast;
    wire         m_axi_wvalid;
    wire         m_axi_wready;
    wire [7:0]   m_axi_bid;
    wire [1:0]   m_axi_bresp;
    wire         m_axi_bvalid;
    wire         m_axi_bready;
    wire [7:0]   m_axi_arid;
    wire [15:0]  m_axi_araddr;
    wire [7:0]   m_axi_arlen;
    wire [2:0]   m_axi_arsize;
    wire [1:0]   m_axi_arburst;
    wire         m_axi_arlock;
    wire [3:0]   m_axi_arcache;
    wire [2:0]   m_axi_arprot;
    wire         m_axi_arvalid;
    wire         m_axi_arready;
    wire [8:0]   m_axi_rid;
    wire [32:0]  m_axi_rdata;
    wire [1:0]   m_axi_rresp;
    wire         m_axi_rlast;
    wire         m_axi_rvalid;
    wire         m_axi_rready;


    /*
     * 1. PCIe to AXI Bridge (Master)
     * Translates incoming PCIe TLPs to AXI transactions.
     */


    pcie_axi_master #(
        // TLP data width
        .TLP_DATA_WIDTH(TLP_DATA_WIDTH),
        // TLP strobe width
        .TLP_STRB_WIDTH(TLP_STRB_WIDTH),
        // TLP header width
        .TLP_HDR_WIDTH(TLP_HDR_WIDTH),
        // TLP segment count
        .TLP_SEG_COUNT(TLP_SEG_COUNT),
        // Width of AXI data bus in bits
        .AXI_DATA_WIDTH(AXI_DATA_WIDTH),
        // Width of AXI address bus in bits
        .AXI_ADDR_WIDTH(AXI_ADDR_WIDTH),
        // Width of AXI wstrb (width of data bus in words)
        .AXI_STRB_WIDTH((AXI_DATA_WIDTH/8)),
        // Width of AXI ID signal
        .AXI_ID_WIDTH(AXI_ID_WIDTH),
        // Maximum AXI burst length to generate
        .AXI_MAX_BURST_LEN(AXI_MAX_BURST_LEN),
        // Force 64 bit address
        .TLP_FORCE_64_BIT_ADDR(0)
    ) pcie_bridge_inst (
        .clk(clk),
        .rst(rst),

        /*
         * TLP input (request)
         */
        .rx_req_tlp_data(rx_req_tlp_data),
        .rx_req_tlp_hdr(rx_req_tlp_hdr),
        .rx_req_tlp_valid(rx_req_tlp_valid),
        .rx_req_tlp_sop(rx_req_tlp_sop),
        .rx_req_tlp_eop(rx_req_tlp_eop),
        .rx_req_tlp_ready(rx_req_tlp_ready),

        /*
         * TLP output (completion)
         */
        .tx_cpl_tlp_data(tx_cpl_tlp_data),
        .tx_cpl_tlp_strb(tx_cpl_tlp_strb),
        .tx_cpl_tlp_hdr(tx_cpl_tlp_hdr),
        .tx_cpl_tlp_valid(tx_cpl_tlp_valid),
        .tx_cpl_tlp_sop(tx_cpl_tlp_sop),
        .tx_cpl_tlp_eop(tx_cpl_tlp_eop),
        .tx_cpl_tlp_ready(tx_cpl_tlp_ready),

        /*
         * AXI Master output
         */
        .m_axi_awid(m_axi_awid),
        .m_axi_awaddr(m_axi_awaddr),
        .m_axi_awlen(m_axi_awlen),
        .m_axi_awsize(m_axi_awsize),
        .m_axi_awburst(m_axi_awburst),
        .m_axi_awlock(m_axi_awlock),
        .m_axi_awcache(m_axi_awcache),
        .m_axi_awprot(m_axi_awprot),
        .m_axi_awvalid(m_axi_awvalid),
        .m_axi_awready(m_axi_awready),
        .m_axi_wdata(m_axi_wdata),
        .m_axi_wstrb(m_axi_wstrb),
        .m_axi_wlast(m_axi_wlast),
        .m_axi_wvalid(m_axi_wvalid),
        .m_axi_wready(m_axi_wready),
        .m_axi_bid(m_axi_bid),
        .m_axi_bresp(m_axi_bresp),
        .m_axi_bvalid(m_axi_bvalid),
        .m_axi_bready(m_axi_bready),
        .m_axi_arid(m_axi_arid),
        .m_axi_araddr(m_axi_araddr),
        .m_axi_arlen(m_axi_arlen),
        .m_axi_arsize(m_axi_arsize),
        .m_axi_arburst(m_axi_arburst),
        .m_axi_arlock(m_axi_arlock),
        .m_axi_arcache(m_axi_arcache),
        .m_axi_arprot(m_axi_arprot),
        .m_axi_arvalid(m_axi_arvalid),
        .m_axi_arready(m_axi_arready),
        .m_axi_rid(m_axi_rid),
        .m_axi_rdata(m_axi_rdata),
        .m_axi_rresp(m_axi_rresp),
        .m_axi_rlast(m_axi_rlast),
        .m_axi_rvalid(m_axi_rvalid),
        .m_axi_rready(m_axi_rready),

        /*
         * Configuration
         */
        .completer_id(completer_id),
        .max_payload_size(max_payload_size),

        /*
         * Status
         */
        .status_error_cor(status_error_cor),
        .status_error_uncor(status_error_uncor)
    );



    axi_ram #(
        // Width of data bus in bits
        .DATA_WIDTH(AXI_DATA_WIDTH),
        // Width of address bus in bits
        .ADDR_WIDTH(AXI_ADDR_WIDTH),
        // Width of wstrb (width of data bus in words)
        .STRB_WIDTH((AXI_DATA_WIDTH/8)),
        // Width of ID signal
        .ID_WIDTH(AXI_ID_WIDTH),
        // Extra pipeline register on output
        .PIPELINE_OUTPUT(1)
    ) ram_inst (
        .clk(clk),
        .rst(rst),

        .s_axi_awid(m_axi_awid),
        .s_axi_awaddr(m_axi_awaddr),
        .s_axi_awlen(m_axi_awlen),
        .s_axi_awsize(m_axi_awsize),
        .s_axi_awburst(m_axi_awburst),
        .s_axi_awlock(m_axi_awlock),
        .s_axi_awcache(m_axi_awcache),
        .s_axi_awprot(m_axi_awprot),
        .s_axi_awvalid(m_axi_awvalid),
        .s_axi_awready(m_axi_awready),
        .s_axi_wdata(m_axi_wdata),
        .s_axi_wstrb(m_axi_wstrb),
        .s_axi_wlast(m_axi_wlast),
        .s_axi_wvalid(m_axi_wvalid),
        .s_axi_wready(m_axi_wready),
        .s_axi_bid(m_axi_bid),
        .s_axi_bresp(m_axi_bresp),
        .s_axi_bvalid(m_axi_bvalid),
        .s_axi_bready(m_axi_bready),
        .s_axi_arid(m_axi_arid),
        .s_axi_araddr(m_axi_araddr),
        .s_axi_arlen(m_axi_arlen),
        .s_axi_arsize(m_axi_arsize),
        .s_axi_arburst(m_axi_arburst),
        .s_axi_arlock(m_axi_arlock),
        .s_axi_arcache(m_axi_arcache),
        .s_axi_arprot(m_axi_arprot),
        .s_axi_arvalid(m_axi_arvalid),
        .s_axi_arready(m_axi_arready),
        .s_axi_rid(m_axi_rid),
        .s_axi_rdata(m_axi_rdata),
        .s_axi_rresp(m_axi_rresp),
        .s_axi_rlast(m_axi_rlast),
        .s_axi_rvalid(m_axi_rvalid),
        .s_axi_rready(m_axi_rready)

    );


endmodule
