// wrapper for the pcie_axi_ram_top module

`resetall
`timescale 1ns / 1ps
`default_nettype none

module test_pcie_axi_ram;
    reg clk = 0;
    reg rst = 1;

    // PCIe TLP interface
    reg [255:0] rx_req_tlp_data;
    reg [31:0]  rx_req_tlp_strb;
    reg [127:0] rx_req_tlp_hdr;
    reg         rx_req_tlp_valid;
    reg         rx_req_tlp_sop;
    reg         rx_req_tlp_eop;
    wire        rx_req_tlp_ready;

    reg [255:0] tx_cpl_tlp_data;
    reg [31:0]  tx_cpl_tlp_strb;
    reg [127:0] tx_cpl_tlp_hdr;
    reg         tx_cpl_tlp_valid;
    reg         tx_cpl_tlp_sop;
    reg         tx_cpl_tlp_eop;
    wire        tx_cpl_tlp_ready;

    // Configuration
    wire [15:0]  completer_id;
    wire [2:0]   max_payload_size;

    // Status
    wire        status_error_cor;
    wire        status_error_uncor;

    // configuration signals (driven by testbench)
    reg [15:0]  completer_id;
    reg [2:0]   max_payload_size = 3'd5;  // 128 bytes

    // AXI signals (exposed for monitoring)
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
    wire [255:0] m_axi_wdata;
    wire [31:0]  m_axi_wstrb;
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
    wire [7:0]   m_axi_rid;
    wire [255:0] m_axi_rdata;
    wire [1:0]   m_axi_rresp;
    wire         m_axi_rlast;
    wire         m_axi_rvalid;
    wire         m_axi_rready;

    // DUT instantiation
    pcie_axi_ram_top #(
        .TLP_DATA_WIDTH(256),
        .TLP_STRB_WIDTH(8),
        .TLP_HDR_WIDTH(128),
        .TLP_SEG_COUNT(1),
        .AXI_DATA_WIDTH(256),
        .AXI_ADDR_WIDTH(16),
        .AXI_ID_WIDTH(8),
        .AXI_MAX_BURST_LEN(256)
    )
    dut (
        .clk(clk),
        .rst(rst),
        .rx_req_tlp_data    (rx_req_tlp_data),
        .rx_req_tlp_strb    (rx_req_tlp_strb),
        .rx_req_tlp_hdr     (rx_req_tlp_hdr),
        .rx_req_tlp_valid   (rx_req_tlp_valid),
        .rx_req_tlp_sop     (rx_req_tlp_sop),
        .rx_req_tlp_eop     (rx_req_tlp_eop),
        .rx_req_tlp_ready   (rx_req_tlp_ready),
        .tx_cpl_tlp_data    (tx_cpl_tlp_data),
        .tx_cpl_tlp_strb    (tx_cpl_tlp_strb),
        .tx_cpl_tlp_hdr     (tx_cpl_tlp_hdr),
        .tx_cpl_tlp_valid   (tx_cpl_tlp_valid),
        .tx_cpl_tlp_sop     (tx_cpl_tlp_sop),
        .tx_cpl_tlp_eop     (tx_cpl_tlp_eop),
        .tx_cpl_tlp_ready   (tx_cpl_tlp_ready),
        .completer_id       (completer_id),
        .max_payload_size   (max_payload_size),
        .status_error_cor   (status_error_cor),
        .status_error_uncor (status_error_uncor),
        // Expose AXI signals for testbench monitoring
        .m_axi_awid        (m_axi_awid),
        .m_axi_awaddr      (m_axi_awaddr),
        .m_axi_awlen       (m_axi_awlen),
        .m_axi_awsize      (m_axi_awsize),
        .m_axi_awburst     (m_axi_awburst),
        .m_axi_awlock      (m_axi_awlock),
        .m_axi_awcache     (m_axi_awcache),
        .m_axi_awprot      (m_axi_awprot),
        .m_axi_awvalid     (m_axi_awvalid),
        .m_axi_awready     (m_axi_awready),
        .m_axi_wdata       (m_axi_wdata),
        .m_axi_wstrb       (m_axi_wstrb),
        .m_axi_wlast       (m_axi_wlast),
        .m_axi_wvalid      (m_axi_wvalid),
        .m_axi_wready      (m_axi_wready),
        .m_axi_bid         (m_axi_bid),
        .m_axi_bresp       (m_axi_bresp),
        .m_axi_bvalid      (m_axi_bvalid),
        .m_axi_bready      (m_axi_bready),
        .m_axi_arid        (m_axi_arid),
        .m_axi_araddr      (m_axi_araddr),
        .m_axi_arlen       (m_axi_arlen),
        .m_axi_arsize      (m_axi_arsize),
        .m_axi_arburst     (m_axi_arburst),
        .m_axi_arlock      (m_axi_arlock),
        .m_axi_arcache     (m_axi_arcache),
        .m_axi_arprot      (m_axi_arprot),
        .m_axi_arvalid     (m_axi_arvalid),
        .m_axi_arready     (m_axi_arready),
        .m_axi_rid         (m_axi_rid),
        .m_axi_rdata       (m_axi_rdata),
        .m_axi_rresp       (m_axi_rresp),
        .m_axi_rlast       (m_axi_rlast),
        .m_axi_rvalid      (m_axi_rvalid),
        .m_axi_rready      (m_axi_rready),
    );
endmodule
