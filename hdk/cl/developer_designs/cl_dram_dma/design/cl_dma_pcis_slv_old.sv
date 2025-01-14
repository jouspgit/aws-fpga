// Amazon FPGA Hardware Development Kit
//
// Copyright 2016 Amazon.com, Inc. or its affiliates. All Rights Reserved.
//
// Licensed under the Amazon Software License (the "License"). You may not use
// this file except in compliance with the License. A copy of the License is
// located at
//
//    http://aws.amazon.com/asl/
//
// or in the "license" file accompanying this file. This file is distributed on
// an "AS IS" BASIS, WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, express or
// implied. See the License for the specific language governing permissions and
// limitations under the License.

module cl_dma_pcis_slv #(parameter SCRB_MAX_ADDR = 64'h3FFFFFFFF, parameter SCRB_BURST_LEN_MINUS1 = 15, parameter NO_SCRB_INST = 1)

(
    input aclk,
    input aresetn,

    cfg_bus_t.master ddra_tst_cfg_bus,
    cfg_bus_t.master ddrb_tst_cfg_bus,
    cfg_bus_t.master ddrc_tst_cfg_bus,
    cfg_bus_t.master ddrd_tst_cfg_bus,

    scrb_bus_t.master ddra_scrb_bus,
    scrb_bus_t.master ddrb_scrb_bus,
    scrb_bus_t.master ddrc_scrb_bus,
    scrb_bus_t.master ddrd_scrb_bus,

    axi_bus_t.master sh_cl_dma_pcis_bus,
    axi_bus_t.master cl_axi_mstr_bus,

    axi_bus_t.slave lcl_cl_sh_ddra,
    axi_bus_t.slave lcl_cl_sh_ddrb,
    axi_bus_t.slave lcl_cl_sh_ddrd,

    axi_bus_t sh_cl_dma_pcis_q,

    axi_bus_t.slave cl_sh_ddr_bus


);
localparam NUM_CFG_STGS_CL_DDR_ATG = 4;
localparam NUM_CFG_STGS_SH_DDR_ATG = 4;

//----------------------------
// Internal signals
//----------------------------
axi_bus_t lcl_cl_sh_ddra_q();
axi_bus_t lcl_cl_sh_ddrb_q();
axi_bus_t lcl_cl_sh_ddrd_q();
axi_bus_t lcl_cl_sh_ddra_q2();
axi_bus_t lcl_cl_sh_ddrb_q2();
axi_bus_t lcl_cl_sh_ddrd_q2();
axi_bus_t lcl_cl_sh_ddra_q3();
axi_bus_t lcl_cl_sh_ddrb_q3();
axi_bus_t lcl_cl_sh_ddrd_q3();
axi_bus_t cl_sh_ddr_q();
axi_bus_t cl_sh_ddr_q2();
axi_bus_t cl_sh_ddr_q3();
axi_bus_t sh_cl_pcis();

cfg_bus_t ddra_tst_cfg_bus_q();
cfg_bus_t ddrb_tst_cfg_bus_q();
cfg_bus_t ddrc_tst_cfg_bus_q();
cfg_bus_t ddrd_tst_cfg_bus_q();

scrb_bus_t ddra_scrb_bus_q();
scrb_bus_t ddrb_scrb_bus_q();
scrb_bus_t ddrc_scrb_bus_q();
scrb_bus_t ddrd_scrb_bus_q();

//----------------------------
// End Internal signals
//----------------------------


//reset synchronizers
(* dont_touch = "true" *) logic slr0_sync_aresetn;
(* dont_touch = "true" *) logic slr1_sync_aresetn;
(* dont_touch = "true" *) logic slr2_sync_aresetn;
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR0_PIPE_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(aresetn), .out_bus(slr0_sync_aresetn));
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR1_PIPE_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(aresetn), .out_bus(slr1_sync_aresetn));
lib_pipe #(.WIDTH(1), .STAGES(4)) SLR2_PIPE_RST_N (.clk(aclk), .rst_n(1'b1), .in_bus(aresetn), .out_bus(slr2_sync_aresetn));

//----------------------------
// flop the dma_pcis interface input of CL
//----------------------------

   // AXI4 Register Slice for dma_pcis interface
   axi_register_slice PCI_AXL_REG_SLC (
       .aclk          (aclk),
       .aresetn       (slr0_sync_aresetn),
       .s_axi_awid    (sh_cl_dma_pcis_bus.awid),
       .s_axi_awaddr  (sh_cl_dma_pcis_bus.awaddr),
       .s_axi_awlen   (sh_cl_dma_pcis_bus.awlen),
       .s_axi_awvalid (sh_cl_dma_pcis_bus.awvalid),
       .s_axi_awsize  (sh_cl_dma_pcis_bus.awsize),
       .s_axi_awready (sh_cl_dma_pcis_bus.awready),
       .s_axi_wdata   (sh_cl_dma_pcis_bus.wdata),
       .s_axi_wstrb   (sh_cl_dma_pcis_bus.wstrb),
       .s_axi_wlast   (sh_cl_dma_pcis_bus.wlast),
       .s_axi_wvalid  (sh_cl_dma_pcis_bus.wvalid),
       .s_axi_wready  (sh_cl_dma_pcis_bus.wready),
       .s_axi_bid     (sh_cl_dma_pcis_bus.bid),
       .s_axi_bresp   (sh_cl_dma_pcis_bus.bresp),
       .s_axi_bvalid  (sh_cl_dma_pcis_bus.bvalid),
       .s_axi_bready  (sh_cl_dma_pcis_bus.bready),
       .s_axi_arid    (sh_cl_dma_pcis_bus.arid),
       .s_axi_araddr  (sh_cl_dma_pcis_bus.araddr),
       .s_axi_arlen   (sh_cl_dma_pcis_bus.arlen),
       .s_axi_arvalid (sh_cl_dma_pcis_bus.arvalid),
       .s_axi_arsize  (sh_cl_dma_pcis_bus.arsize),
       .s_axi_arready (sh_cl_dma_pcis_bus.arready),
       .s_axi_rid     (sh_cl_dma_pcis_bus.rid),
       .s_axi_rdata   (sh_cl_dma_pcis_bus.rdata),
       .s_axi_rresp   (sh_cl_dma_pcis_bus.rresp),
       .s_axi_rlast   (sh_cl_dma_pcis_bus.rlast),
       .s_axi_rvalid  (sh_cl_dma_pcis_bus.rvalid),
       .s_axi_rready  (sh_cl_dma_pcis_bus.rready),

       .m_axi_awid    (sh_cl_dma_pcis_q.awid),
       .m_axi_awaddr  (sh_cl_dma_pcis_q.awaddr),
       .m_axi_awlen   (sh_cl_dma_pcis_q.awlen),
       .m_axi_awvalid (sh_cl_dma_pcis_q.awvalid),
       .m_axi_awsize  (sh_cl_dma_pcis_q.awsize),
       .m_axi_awready (sh_cl_dma_pcis_q.awready),
       .m_axi_wdata   (sh_cl_dma_pcis_q.wdata),
       .m_axi_wstrb   (sh_cl_dma_pcis_q.wstrb),
       .m_axi_wvalid  (sh_cl_dma_pcis_q.wvalid),
       .m_axi_wlast   (sh_cl_dma_pcis_q.wlast),
       .m_axi_wready  (sh_cl_dma_pcis_q.wready),
       .m_axi_bresp   (sh_cl_dma_pcis_q.bresp),
       .m_axi_bvalid  (sh_cl_dma_pcis_q.bvalid),
       .m_axi_bid     (sh_cl_dma_pcis_q.bid),
       .m_axi_bready  (sh_cl_dma_pcis_q.bready),
       .m_axi_arid    (sh_cl_dma_pcis_q.arid),
       .m_axi_araddr  (sh_cl_dma_pcis_q.araddr),
       .m_axi_arlen   (sh_cl_dma_pcis_q.arlen),
       .m_axi_arsize  (sh_cl_dma_pcis_q.arsize),
       .m_axi_arvalid (sh_cl_dma_pcis_q.arvalid),
       .m_axi_arready (sh_cl_dma_pcis_q.arready),
       .m_axi_rid     (sh_cl_dma_pcis_q.rid),
       .m_axi_rdata   (sh_cl_dma_pcis_q.rdata),
       .m_axi_rresp   (sh_cl_dma_pcis_q.rresp),
       .m_axi_rlast   (sh_cl_dma_pcis_q.rlast),
       .m_axi_rvalid  (sh_cl_dma_pcis_q.rvalid),
       .m_axi_rready  (sh_cl_dma_pcis_q.rready)
   );

//-----------------------------------------------------
//TIE-OFF unused signals to prevent critical warnings
//-----------------------------------------------------
/*
//-----------------------------------------------------
// AXI-4 FIFO
//-----------------------------------------------------
// This modules takes the output of the register slice.
// the flip flop might necessary.
axi_bus_t sh_cl_dma_pcis_fifo();

  fifo_generator_0 FIFO(
      .s_aclk           (aclk),
      .s_aresetn        (slr1_sync_aresetn),
      .s_axi_awid       (sh_cl_dma_pcis_q.awid),
      .s_axi_awaddr     (sh_cl_dma_pcis_q.awaddr),
      .s_axi_awlen      (sh_cl_dma_pcis_q.awlen),
      .s_axi_awsize     (sh_cl_dma_pcis_q.awsize),
      .s_axi_awburst    (2'b1), // from interconnect
      .s_axi_awlock     (1'b0), // from interconnect
      .s_axi_awcache    (4'b11), // from interconnect
      .s_axi_awprot     (3'b10), // from interconnect
      .s_axi_awqos      (4'b0), // from interconnect
      .s_axi_awregion   (4'b0),  // from interconnect
      .s_axi_awvalid    (sh_cl_dma_pcis_q.awvalid),
      .s_axi_awready    (sh_cl_dma_pcis_q.awready),
      .s_axi_wdata      (sh_cl_dma_pcis_q.wdata),
      .s_axi_wstrb      (sh_cl_dma_pcis_q.wstrb),
      .s_axi_wlast      (sh_cl_dma_pcis_q.wlast),
      .s_axi_wvalid     (sh_cl_dma_pcis_q.wvalid),
      .s_axi_wready     (sh_cl_dma_pcis_q.wready),
      .s_axi_bid        (sh_cl_dma_pcis_q.bid),
      .s_axi_bresp      (sh_cl_dma_pcis_q.bresp),
      .s_axi_bvalid     (sh_cl_dma_pcis_q.bvalid),
      .s_axi_bready     (sh_cl_dma_pcis_q.bready),

      .s_axi_arid       (sh_cl_dma_pcis_q.arid),
      .s_axi_araddr     (sh_cl_dma_pcis_q.araddr),
      .s_axi_arlen      (sh_cl_dma_pcis_q.arlen),
      .s_axi_arsize     (sh_cl_dma_pcis_q.arsize),
      .s_axi_arburst    (2'b1), // from interconnect
      .s_axi_arlock     (1'b0), // from interconnect
      .s_axi_arcache    (4'b11), // from interconnect
      .s_axi_arprot     (3'b10), // from interconnect
      .s_axi_arqos      (4'b0), // from interconnect
      .s_axi_arregion   (4'b0), // from interconnect
      .s_axi_arvalid    (sh_cl_dma_pcis_q.arvalid),
      .s_axi_arready    (sh_cl_dma_pcis_q.arready),
      .s_axi_rid        (sh_cl_dma_pcis_q.rid),
      .s_axi_rdata      (sh_cl_dma_pcis_q.rdata),
      .s_axi_rresp      (sh_cl_dma_pcis_q.rresp),
      .s_axi_rlast      (sh_cl_dma_pcis_q.rlast),
      .s_axi_rvalid     (sh_cl_dma_pcis_q.rvalid),
      .s_axi_rready     (sh_cl_dma_pcis_q.rready),

      .m_axi_wdata 		(sh_cl_dma_pcis_fifo.wdata)

);

*/

//-----------------------------------------------------
// AXI-Stream FIFO
//-----------------------------------------------------
wire mm2s_prmry_reset_out_n; // transmit to jpeg-xs
wire axi_str_txd_tvalid;
wire axi_str_txd_tready;
wire axi_str_txd_tlast;
wire [511:0] axi_str_txd_tdata;

wire up_s2mm_prmry_reset_out_n; // uplink from output of jpeg-xs
wire up_axi_str_rxd_tvalid;
wire up_axi_str_rxd_tready;
wire up_axi_str_rxd_tlast;
wire [511:0] up_axi_str_rxd_tdata;


axi_fifo_mm_s_0 FIFO_AXI4_TO_STREAM_AND_BACK (
  .interrupt(),                                     // output wire interrupt
  .s_axi_aclk(aclk),                                // input wire s_axi_aclk
  .s_axi_aresetn(slr1_sync_aresetn),                // input wire s_axi_aresetn

  .s_axi4_awid(16'b0),                        // input wire [15 : 0] s_axi4_awid
  .s_axi4_awaddr(sh_cl_dma_pcis_q.awaddr),                    // input wire [31 : 0] s_axi4_awaddr
  .s_axi4_awlen(sh_cl_dma_pcis_q.awlen),                      // input wire [7 : 0] s_axi4_awlen
  .s_axi4_awsize(sh_cl_dma_pcis_q.awsize),                    // input wire [2 : 0] s_axi4_awsize
  .s_axi4_awburst(2'b1),                                      // input wire [1 : 0] s_axi4_awburst
  .s_axi4_awlock(1'b0),                                       // input wire s_axi4_awlock
  .s_axi4_awcache(4'b11),                                     // input wire [3 : 0] s_axi4_awcache
  .s_axi4_awprot(3'b10),                                      // input wire [2 : 0] s_axi4_awprot
  .s_axi4_awvalid(sh_cl_dma_pcis_q.awvalid),                  // input wire s_axi4_awvalid
  .s_axi4_awready(sh_cl_dma_pcis_q.awready),                  // output wire s_axi4_awready
  .s_axi4_wdata(sh_cl_dma_pcis_q.wdata),                      // input wire [511 : 0] s_axi4_wdata
  .s_axi4_wstrb(sh_cl_dma_pcis_q.wstrb),                      // input wire [63 : 0] s_axi4_wstrb
  .s_axi4_wlast(sh_cl_dma_pcis_q.wlast),                      // input wire s_axi4_wlast
  .s_axi4_wvalid(sh_cl_dma_pcis_q.wvalid),                    // input wire s_axi4_wvalid
  .s_axi4_wready(sh_cl_dma_pcis_q.wready),                    // output wire s_axi4_wready
  .s_axi4_bid(sh_cl_dma_pcis_q.bid),                          // output wire [15 : 0] s_axi4_bid
  .s_axi4_bresp(sh_cl_dma_pcis_q.bresp),                      // output wire [1 : 0] s_axi4_bresp
  .s_axi4_bvalid(sh_cl_dma_pcis_q.bvalid),                    // output wire s_axi4_bvalid
  .s_axi4_bready(sh_cl_dma_pcis_q.bready),                    // input wire s_axi4_bready
  .s_axi4_arid(16'b0),                        // input wire [15 : 0] s_axi4_arid
  .s_axi4_araddr(sh_cl_dma_pcis_q.araddr),                    // input wire [31 : 0] s_axi4_araddr
  .s_axi4_arlen(sh_cl_dma_pcis_q.arlen),                      // input wire [7 : 0] s_axi4_arlen
  .s_axi4_arsize(sh_cl_dma_pcis_q.arsize),                    // input wire [2 : 0] s_axi4_arsize
  .s_axi4_arburst(2'b1),                                      // input wire [1 : 0] s_axi4_arburst
  .s_axi4_arlock(1'b0),                                       // input wire s_axi4_arlock
  .s_axi4_arcache(4'b11),                                     // input wire [3 : 0] s_axi4_arcache
  .s_axi4_arprot(3'b10),                                      // input wire [2 : 0] s_axi4_arprot
  .s_axi4_arvalid(sh_cl_dma_pcis_q.arvalid),                  // input wire s_axi4_arvalid
  .s_axi4_arready(sh_cl_dma_pcis_q.arready),                  // output wire s_axi4_arready
  .s_axi4_rid(sh_cl_dma_pcis_q.rid),                          // output wire [15 : 0] s_axi4_rid
  .s_axi4_rdata(sh_cl_dma_pcis_q.rdata),                      // output wire [511 : 0] s_axi4_rdata
  .s_axi4_rresp(sh_cl_dma_pcis_q.rresp),                      // output wire [1 : 0] s_axi4_rresp
  .s_axi4_rlast(sh_cl_dma_pcis_q.rlast),                      // output wire s_axi4_rlast
  .s_axi4_rvalid(sh_cl_dma_pcis_q.rvalid),                    // output wire s_axi4_rvalid
  .s_axi4_rready(sh_cl_dma_pcis_q.rready),                    // input wire s_axi4_rready

  // transmit data stream for jpeg-xs
  .mm2s_prmry_reset_out_n(mm2s_prmry_reset_out_n),  // output wire mm2s_prmry_reset_out_n
  .axi_str_txd_tvalid(axi_str_txd_tvalid),          // output wire axi_str_txd_tvalid
  .axi_str_txd_tready(axi_str_txd_tready),          // input wire axi_str_txd_tready
  .axi_str_txd_tlast(axi_str_txd_tlast),            // output wire axi_str_txd_tlast
  .axi_str_txd_tdata(axi_str_txd_tdata),            // output wire [511 : 0] axi_str_txd_tdata

  // receive stream for readback after jpeg-xs
  .s2mm_prmry_reset_out_n(up_s2mm_prmry_reset_out_n),  // output wire s2mm_prmry_reset_out_n
  .axi_str_rxd_tvalid(up_axi_str_rxd_tvalid),          // input wire axi_str_rxd_tvalid
  .axi_str_rxd_tready(up_axi_str_rxd_tready),          // output wire axi_str_rxd_tready
  .axi_str_rxd_tlast(up_axi_str_rxd_tlast),            // input wire axi_str_rxd_tlast
  .axi_str_rxd_tdata(up_axi_str_rxd_tdata)            // input wire [511 : 0] axi_str_rxd_tdata
);


//-----------------------------------------------------
// JPEG-XS Compression
//-----------------------------------------------------

// input : previous STREAM fifo axi_str_txd_*
/*
mm2s_prmry_reset_out_n;
axi_str_txd_tvalid;
axi_str_txd_tready;
axi_str_txd_tlast;
axi_str_txd_tdata;*/

//output : (for now, assigned back to FIFO as a loop) up_axi_str_rxd_*

assign up_axi_str_rxd_tvalid = axi_str_txd_tvalid;
assign axi_str_txd_tready= up_axi_str_rxd_tready;
assign up_axi_str_rxd_tlast = axi_str_txd_tlast;
assign up_axi_str_rxd_tdata = axi_str_txd_tdata;


//----------------------------
// axi interconnect for DDR address decodes
//----------------------------
(* dont_touch = "true" *) cl_axi_interconnect AXI_CROSSBAR
       (.ACLK(aclk),
        .ARESETN(slr1_sync_aresetn),
        /*
        .S00_AXI_araddr({sh_cl_dma_pcis_q.araddr[63:37], 1'b0, sh_cl_dma_pcis_q.araddr[35:0]}),
        .S00_AXI_arburst(2'b1),
        .S00_AXI_arcache(4'b11),
        .S00_AXI_arid(sh_cl_dma_pcis_q.arid[5:0]),
        .S00_AXI_arlen(sh_cl_dma_pcis_q.arlen),
        .S00_AXI_arlock(1'b0),
        .S00_AXI_arprot(3'b10),
        .S00_AXI_arqos(4'b0),
        .S00_AXI_arready(sh_cl_dma_pcis_q.arready),
        .S00_AXI_arregion(4'b0),
        .S00_AXI_arsize(sh_cl_dma_pcis_q.arsize),
        .S00_AXI_arvalid(sh_cl_dma_pcis_q.arvalid),
        .S00_AXI_rdata(sh_cl_dma_pcis_q.rdata),
        .S00_AXI_rid(sh_cl_dma_pcis_q.rid[5:0]),
        .S00_AXI_rlast(sh_cl_dma_pcis_q.rlast),
        .S00_AXI_rready(sh_cl_dma_pcis_q.rready),
        .S00_AXI_rresp(sh_cl_dma_pcis_q.rresp),
        .S00_AXI_rvalid(sh_cl_dma_pcis_q.rvalid),
        
        .S00_AXI_awaddr({sh_cl_dma_pcis_q.awaddr[63:37], 1'b0, sh_cl_dma_pcis_q.awaddr[35:0]}),
        .S00_AXI_awburst(2'b1),
        .S00_AXI_awcache(4'b11),
        .S00_AXI_awid(sh_cl_dma_pcis_q.awid[5:0]),
        .S00_AXI_awlen(sh_cl_dma_pcis_q.awlen),
        .S00_AXI_awlock(1'b0),
        .S00_AXI_awprot(3'b10),
        .S00_AXI_awqos(4'b0),
        .S00_AXI_awready(sh_cl_dma_pcis_q.awready),
        .S00_AXI_awregion(4'b0),
        .S00_AXI_awsize(sh_cl_dma_pcis_q.awsize),
        .S00_AXI_awvalid(sh_cl_dma_pcis_q.awvalid),
        .S00_AXI_bid(sh_cl_dma_pcis_q.bid[5:0]),
        .S00_AXI_bready(sh_cl_dma_pcis_q.bready),
        .S00_AXI_bresp(sh_cl_dma_pcis_q.bresp),
        .S00_AXI_bvalid(sh_cl_dma_pcis_q.bvalid),
        .S00_AXI_wdata(sh_cl_dma_pcis_q.wdata),
        .S00_AXI_wlast(sh_cl_dma_pcis_q.wlast),
        .S00_AXI_wready(sh_cl_dma_pcis_q.wready),
        .S00_AXI_wstrb(sh_cl_dma_pcis_q.wstrb),
        .S00_AXI_wvalid(sh_cl_dma_pcis_q.wvalid),
		    */

        .M00_AXI_araddr(lcl_cl_sh_ddra_q.araddr),
        .M00_AXI_arburst(),
        .M00_AXI_arcache(),
        .M00_AXI_arid(lcl_cl_sh_ddra_q.arid[6:0]),
        .M00_AXI_arlen(lcl_cl_sh_ddra_q.arlen),
        .M00_AXI_arlock(),
        .M00_AXI_arprot(),
        .M00_AXI_arqos(),
        .M00_AXI_arready(lcl_cl_sh_ddra_q.arready),
        .M00_AXI_arregion(),
        .M00_AXI_arsize(lcl_cl_sh_ddra_q.arsize),
        .M00_AXI_arvalid(lcl_cl_sh_ddra_q.arvalid),
        .M00_AXI_awaddr(lcl_cl_sh_ddra_q.awaddr),
        .M00_AXI_awburst(),
        .M00_AXI_awcache(),
        .M00_AXI_awid(lcl_cl_sh_ddra_q.awid[6:0]),
        .M00_AXI_awlen(lcl_cl_sh_ddra_q.awlen),
        .M00_AXI_awlock(),
        .M00_AXI_awprot(),
        .M00_AXI_awqos(),
        .M00_AXI_awready(lcl_cl_sh_ddra_q.awready),
        .M00_AXI_awregion(),
        .M00_AXI_awsize(lcl_cl_sh_ddra_q.awsize),
        .M00_AXI_awvalid(lcl_cl_sh_ddra_q.awvalid),
        .M00_AXI_bid(lcl_cl_sh_ddra_q.bid[6:0]),
        .M00_AXI_bready(lcl_cl_sh_ddra_q.bready),
        .M00_AXI_bresp(lcl_cl_sh_ddra_q.bresp),
        .M00_AXI_bvalid(lcl_cl_sh_ddra_q.bvalid),
        .M00_AXI_rdata(lcl_cl_sh_ddra_q.rdata),
        .M00_AXI_rid(lcl_cl_sh_ddra_q.rid[6:0]),
        .M00_AXI_rlast(lcl_cl_sh_ddra_q.rlast),
        .M00_AXI_rready(lcl_cl_sh_ddra_q.rready),
        .M00_AXI_rresp(lcl_cl_sh_ddra_q.rresp),
        .M00_AXI_rvalid(lcl_cl_sh_ddra_q.rvalid),
        .M00_AXI_wdata(lcl_cl_sh_ddra_q.wdata),
        .M00_AXI_wlast(lcl_cl_sh_ddra_q.wlast),
        .M00_AXI_wready(lcl_cl_sh_ddra_q.wready),
        .M00_AXI_wstrb(lcl_cl_sh_ddra_q.wstrb),
        .M00_AXI_wvalid(lcl_cl_sh_ddra_q.wvalid),

        .M01_AXI_araddr(lcl_cl_sh_ddrb_q.araddr),
        .M01_AXI_arburst(),
        .M01_AXI_arcache(),
        .M01_AXI_arid(lcl_cl_sh_ddrb_q.arid[6:0]),
        .M01_AXI_arlen(lcl_cl_sh_ddrb_q.arlen),
        .M01_AXI_arlock(),
        .M01_AXI_arprot(),
        .M01_AXI_arqos(),
        .M01_AXI_arready(lcl_cl_sh_ddrb_q.arready),
        .M01_AXI_arregion(),
        .M01_AXI_arsize(lcl_cl_sh_ddrb_q.arsize),
        .M01_AXI_arvalid(lcl_cl_sh_ddrb_q.arvalid),
        .M01_AXI_awaddr(lcl_cl_sh_ddrb_q.awaddr),
        .M01_AXI_awburst(),
        .M01_AXI_awcache(),
        .M01_AXI_awid(lcl_cl_sh_ddrb_q.awid[6:0]),
        .M01_AXI_awlen(lcl_cl_sh_ddrb_q.awlen),
        .M01_AXI_awlock(),
        .M01_AXI_awprot(),
        .M01_AXI_awqos(),
        .M01_AXI_awready(lcl_cl_sh_ddrb_q.awready),
        .M01_AXI_awregion(),
        .M01_AXI_awsize(lcl_cl_sh_ddrb_q.awsize),
        .M01_AXI_awvalid(lcl_cl_sh_ddrb_q.awvalid),
        .M01_AXI_bid(lcl_cl_sh_ddrb_q.bid[6:0]),
        .M01_AXI_bready(lcl_cl_sh_ddrb_q.bready),
        .M01_AXI_bresp(lcl_cl_sh_ddrb_q.bresp),
        .M01_AXI_bvalid(lcl_cl_sh_ddrb_q.bvalid),
        .M01_AXI_rdata(lcl_cl_sh_ddrb_q.rdata),
        .M01_AXI_rid(lcl_cl_sh_ddrb_q.rid[6:0]),
        .M01_AXI_rlast(lcl_cl_sh_ddrb_q.rlast),
        .M01_AXI_rready(lcl_cl_sh_ddrb_q.rready),
        .M01_AXI_rresp(lcl_cl_sh_ddrb_q.rresp),
        .M01_AXI_rvalid(lcl_cl_sh_ddrb_q.rvalid),
        .M01_AXI_wdata(lcl_cl_sh_ddrb_q.wdata),
        .M01_AXI_wlast(lcl_cl_sh_ddrb_q.wlast),
        .M01_AXI_wready(lcl_cl_sh_ddrb_q.wready),
        .M01_AXI_wstrb(lcl_cl_sh_ddrb_q.wstrb),
        .M01_AXI_wvalid(lcl_cl_sh_ddrb_q.wvalid),


        .M02_AXI_araddr(cl_sh_ddr_q.araddr),
        .M02_AXI_arburst(),
        .M02_AXI_arcache(),
        .M02_AXI_arid(cl_sh_ddr_q.arid[6:0]),
        .M02_AXI_arlen(cl_sh_ddr_q.arlen),
        .M02_AXI_arlock(),
        .M02_AXI_arprot(),
        .M02_AXI_arqos(),
        .M02_AXI_arready(cl_sh_ddr_q.arready),
        .M02_AXI_arregion(),
        .M02_AXI_arsize(cl_sh_ddr_q.arsize),
        .M02_AXI_arvalid(cl_sh_ddr_q.arvalid),
        .M02_AXI_awaddr(cl_sh_ddr_q.awaddr),
        .M02_AXI_awburst(),
        .M02_AXI_awcache(),
        .M02_AXI_awid(cl_sh_ddr_q.awid[6:0]),
        .M02_AXI_awlen(cl_sh_ddr_q.awlen),
        .M02_AXI_awlock(),
        .M02_AXI_awprot(),
        .M02_AXI_awqos(),
        .M02_AXI_awready(cl_sh_ddr_q.awready),
        .M02_AXI_awregion(),
        .M02_AXI_awsize(cl_sh_ddr_q.awsize),
        .M02_AXI_awvalid(cl_sh_ddr_q.awvalid),
        .M02_AXI_bid(cl_sh_ddr_q.bid[6:0]),
        .M02_AXI_bready(cl_sh_ddr_q.bready),
        .M02_AXI_bresp(cl_sh_ddr_q.bresp),
        .M02_AXI_bvalid(cl_sh_ddr_q.bvalid),
        .M02_AXI_rdata(cl_sh_ddr_q.rdata),
        .M02_AXI_rid(cl_sh_ddr_q.rid[6:0]),
        .M02_AXI_rlast(cl_sh_ddr_q.rlast),
        .M02_AXI_rready(cl_sh_ddr_q.rready),
        .M02_AXI_rresp(cl_sh_ddr_q.rresp),
        .M02_AXI_rvalid(cl_sh_ddr_q.rvalid),
        .M02_AXI_wdata(cl_sh_ddr_q.wdata),
        .M02_AXI_wlast(cl_sh_ddr_q.wlast),
        .M02_AXI_wready(cl_sh_ddr_q.wready),
        .M02_AXI_wstrb(cl_sh_ddr_q.wstrb),
        .M02_AXI_wvalid(cl_sh_ddr_q.wvalid),

        .M03_AXI_araddr(lcl_cl_sh_ddrd_q.araddr),
        .M03_AXI_arburst(),
        .M03_AXI_arcache(),
        .M03_AXI_arid(lcl_cl_sh_ddrd_q.arid[6:0]),
        .M03_AXI_arlen(lcl_cl_sh_ddrd_q.arlen),
        .M03_AXI_arlock(),
        .M03_AXI_arprot(),
        .M03_AXI_arqos(),
        .M03_AXI_arready(lcl_cl_sh_ddrd_q.arready),
        .M03_AXI_arregion(),
        .M03_AXI_arsize(lcl_cl_sh_ddrd_q.arsize),
        .M03_AXI_arvalid(lcl_cl_sh_ddrd_q.arvalid),
        .M03_AXI_awaddr(lcl_cl_sh_ddrd_q.awaddr),
        .M03_AXI_awburst(),
        .M03_AXI_awcache(),
        .M03_AXI_awid(lcl_cl_sh_ddrd_q.awid[6:0]),
        .M03_AXI_awlen(lcl_cl_sh_ddrd_q.awlen),
        .M03_AXI_awlock(),
        .M03_AXI_awprot(),
        .M03_AXI_awqos(),
        .M03_AXI_awready(lcl_cl_sh_ddrd_q.awready),
        .M03_AXI_awregion(),
        .M03_AXI_awsize(lcl_cl_sh_ddrd_q.awsize),
        .M03_AXI_awvalid(lcl_cl_sh_ddrd_q.awvalid),
        .M03_AXI_bid(lcl_cl_sh_ddrd_q.bid[6:0]),
        .M03_AXI_bready(lcl_cl_sh_ddrd_q.bready),
        .M03_AXI_bresp(lcl_cl_sh_ddrd_q.bresp),
        .M03_AXI_bvalid(lcl_cl_sh_ddrd_q.bvalid),
        .M03_AXI_rdata(lcl_cl_sh_ddrd_q.rdata),
        .M03_AXI_rid(lcl_cl_sh_ddrd_q.rid[6:0]),
        .M03_AXI_rlast(lcl_cl_sh_ddrd_q.rlast),
        .M03_AXI_rready(lcl_cl_sh_ddrd_q.rready),
        .M03_AXI_rresp(lcl_cl_sh_ddrd_q.rresp),
        .M03_AXI_rvalid(lcl_cl_sh_ddrd_q.rvalid),
        .M03_AXI_wdata(lcl_cl_sh_ddrd_q.wdata),
        .M03_AXI_wlast(lcl_cl_sh_ddrd_q.wlast),
        .M03_AXI_wready(lcl_cl_sh_ddrd_q.wready),
        .M03_AXI_wstrb(lcl_cl_sh_ddrd_q.wstrb),
        .M03_AXI_wvalid(lcl_cl_sh_ddrd_q.wvalid),


        

		
        .S01_AXI_araddr({cl_axi_mstr_bus.araddr[63:37], 1'b0, cl_axi_mstr_bus.araddr[35:0]}),
        .S01_AXI_arburst(2'b1),
        .S01_AXI_arcache(4'b11),
        .S01_AXI_arid(cl_axi_mstr_bus.arid[5:0]),
        .S01_AXI_arlen(cl_axi_mstr_bus.arlen),
        .S01_AXI_arlock(1'b0),
        .S01_AXI_arprot(3'b10),
        .S01_AXI_arqos(4'b0),
        .S01_AXI_arready(cl_axi_mstr_bus.arready),
        .S01_AXI_arregion(4'b0),
        .S01_AXI_arsize(cl_axi_mstr_bus.arsize),
        .S01_AXI_arvalid(cl_axi_mstr_bus.arvalid),
        .S01_AXI_awaddr({cl_axi_mstr_bus.awaddr[63:37], 1'b0, cl_axi_mstr_bus.awaddr[35:0]}),
        .S01_AXI_awburst(2'b1),
        .S01_AXI_awcache(4'b11),
        .S01_AXI_awid(cl_axi_mstr_bus.awid[5:0]),
        .S01_AXI_awlen(cl_axi_mstr_bus.awlen),
        .S01_AXI_awlock(1'b0),
        .S01_AXI_awprot(3'b10),
        .S01_AXI_awqos(4'b0),
        .S01_AXI_awready(cl_axi_mstr_bus.awready),
        .S01_AXI_awregion(4'b0),
        .S01_AXI_awsize(cl_axi_mstr_bus.awsize),
        .S01_AXI_awvalid(cl_axi_mstr_bus.awvalid),
        .S01_AXI_bid(cl_axi_mstr_bus.bid[5:0]),
        .S01_AXI_bready(cl_axi_mstr_bus.bready),
        .S01_AXI_bresp(cl_axi_mstr_bus.bresp),
        .S01_AXI_bvalid(cl_axi_mstr_bus.bvalid),
        .S01_AXI_rdata(cl_axi_mstr_bus.rdata),
        .S01_AXI_rid(cl_axi_mstr_bus.rid[5:0]),
        .S01_AXI_rlast(cl_axi_mstr_bus.rlast),
        .S01_AXI_rready(cl_axi_mstr_bus.rready),
        .S01_AXI_rresp(cl_axi_mstr_bus.rresp),
        .S01_AXI_rvalid(cl_axi_mstr_bus.rvalid),
        .S01_AXI_wdata(cl_axi_mstr_bus.wdata),
        .S01_AXI_wlast(cl_axi_mstr_bus.wlast),
        .S01_AXI_wready(cl_axi_mstr_bus.wready),
        .S01_AXI_wstrb(cl_axi_mstr_bus.wstrb),
        .S01_AXI_wvalid(cl_axi_mstr_bus.wvalid));

//----------------------------
// flop the output of interconnect for DDRC
//----------------------------
   axi_register_slice DDR_C_TST_AXI4_REG_SLC (
       .aclk           (aclk),
       .aresetn        (slr1_sync_aresetn),

       .s_axi_awid     (cl_sh_ddr_q.awid),
       .s_axi_awaddr   ({cl_sh_ddr_q.awaddr[63:36], 2'b0, cl_sh_ddr_q.awaddr[33:0]}),
       .s_axi_awlen    (cl_sh_ddr_q.awlen),
       .s_axi_awsize   (cl_sh_ddr_q.awsize),
       .s_axi_awvalid  (cl_sh_ddr_q.awvalid),
       .s_axi_awready  (cl_sh_ddr_q.awready),
       .s_axi_wdata    (cl_sh_ddr_q.wdata),
       .s_axi_wstrb    (cl_sh_ddr_q.wstrb),
       .s_axi_wlast    (cl_sh_ddr_q.wlast),
       .s_axi_wvalid   (cl_sh_ddr_q.wvalid),
       .s_axi_wready   (cl_sh_ddr_q.wready),
       .s_axi_bid      (cl_sh_ddr_q.bid),
       .s_axi_bresp    (cl_sh_ddr_q.bresp),
       .s_axi_bvalid   (cl_sh_ddr_q.bvalid),
       .s_axi_bready   (cl_sh_ddr_q.bready),
       .s_axi_arid     (cl_sh_ddr_q.arid),
       .s_axi_araddr   ({cl_sh_ddr_q.araddr[63:36], 2'b0, cl_sh_ddr_q.araddr[33:0]}),
       .s_axi_arlen    (cl_sh_ddr_q.arlen),
       .s_axi_arsize   (cl_sh_ddr_q.arsize),
       .s_axi_arvalid  (cl_sh_ddr_q.arvalid),
       .s_axi_arready  (cl_sh_ddr_q.arready),
       .s_axi_rid      (cl_sh_ddr_q.rid),
       .s_axi_rdata    (cl_sh_ddr_q.rdata),
       .s_axi_rresp    (cl_sh_ddr_q.rresp),
       .s_axi_rlast    (cl_sh_ddr_q.rlast),
       .s_axi_rvalid   (cl_sh_ddr_q.rvalid),
       .s_axi_rready   (cl_sh_ddr_q.rready),
       .m_axi_awid     (cl_sh_ddr_q2.awid),
       .m_axi_awaddr   (cl_sh_ddr_q2.awaddr),
       .m_axi_awlen    (cl_sh_ddr_q2.awlen),
       .m_axi_awsize   (cl_sh_ddr_q2.awsize),
       .m_axi_awvalid  (cl_sh_ddr_q2.awvalid),
       .m_axi_awready  (cl_sh_ddr_q2.awready),
       .m_axi_wdata    (cl_sh_ddr_q2.wdata),
       .m_axi_wstrb    (cl_sh_ddr_q2.wstrb),
       .m_axi_wlast    (cl_sh_ddr_q2.wlast),
       .m_axi_wvalid   (cl_sh_ddr_q2.wvalid),
       .m_axi_wready   (cl_sh_ddr_q2.wready),
       .m_axi_bid      (cl_sh_ddr_q2.bid),
       .m_axi_bresp    (cl_sh_ddr_q2.bresp),
       .m_axi_bvalid   (cl_sh_ddr_q2.bvalid),
       .m_axi_bready   (cl_sh_ddr_q2.bready),
       .m_axi_arid     (cl_sh_ddr_q2.arid),
       .m_axi_araddr   (cl_sh_ddr_q2.araddr),
       .m_axi_arlen    (cl_sh_ddr_q2.arlen),
       .m_axi_arsize   (cl_sh_ddr_q2.arsize),
       .m_axi_arvalid  (cl_sh_ddr_q2.arvalid),
       .m_axi_arready  (cl_sh_ddr_q2.arready),
       .m_axi_rid      (cl_sh_ddr_q2.rid),
       .m_axi_rdata    (cl_sh_ddr_q2.rdata),
       .m_axi_rresp    (cl_sh_ddr_q2.rresp),
       .m_axi_rlast    (cl_sh_ddr_q2.rlast),
       .m_axi_rvalid   (cl_sh_ddr_q2.rvalid),
       .m_axi_rready   (cl_sh_ddr_q2.rready)
   );


//----------------------------
// ATG/scrubber for DDRC
//----------------------------

   lib_pipe #(.WIDTH(32+32+1+1), .STAGES(NUM_CFG_STGS_SH_DDR_ATG)) PIPE_CFG_REQ_DDR_C (.clk (aclk),
                                                              .rst_n (aresetn),
                                                              .in_bus({ddrc_tst_cfg_bus.addr, ddrc_tst_cfg_bus.wdata, ddrc_tst_cfg_bus.wr, ddrc_tst_cfg_bus.rd}),
                                                              .out_bus({ddrc_tst_cfg_bus_q.addr, ddrc_tst_cfg_bus_q.wdata, ddrc_tst_cfg_bus_q.wr, ddrc_tst_cfg_bus_q.rd})
                                                              );

   lib_pipe #(.WIDTH(32+1), .STAGES(NUM_CFG_STGS_SH_DDR_ATG)) PIPE_CFG_ACK_DDR_C (.clk (aclk),
                                                              .rst_n (aresetn),
                                                              .in_bus({ddrc_tst_cfg_bus_q.ack, ddrc_tst_cfg_bus_q.rdata}),
                                                              .out_bus({ddrc_tst_cfg_bus.ack, ddrc_tst_cfg_bus.rdata})
                                                              );


   lib_pipe #(.WIDTH(2+3+64), .STAGES(NUM_CFG_STGS_SH_DDR_ATG)) PIPE_SCRB_DDR_C (.clk(aclk),
                                                              .rst_n(aresetn),
                                                              .in_bus({ddrc_scrb_bus.enable, ddrc_scrb_bus_q.done, ddrc_scrb_bus_q.state, ddrc_scrb_bus_q.addr}),
                                                              .out_bus({ddrc_scrb_bus_q.enable, ddrc_scrb_bus.done, ddrc_scrb_bus.state, ddrc_scrb_bus.addr})
                                                              );
   cl_tst_scrb #(.DATA_WIDTH(512),
                    .SCRB_BURST_LEN_MINUS1(SCRB_BURST_LEN_MINUS1),
                    .SCRB_MAX_ADDR(SCRB_MAX_ADDR),
                    .NO_SCRB_INST(NO_SCRB_INST)) CL_TST_DDR_C (

         .clk(aclk),
         .rst_n(slr1_sync_aresetn),

         .cfg_addr(ddrc_tst_cfg_bus_q.addr),
         .cfg_wdata(ddrc_tst_cfg_bus_q.wdata),
         .cfg_wr(ddrc_tst_cfg_bus_q.wr),
         .cfg_rd(ddrc_tst_cfg_bus_q.rd),
         .tst_cfg_ack(ddrc_tst_cfg_bus_q.ack),
         .tst_cfg_rdata(ddrc_tst_cfg_bus_q.rdata),

         .slv_awid(cl_sh_ddr_q2.awid[6:0]),
         .slv_awaddr(cl_sh_ddr_q2.awaddr),
         .slv_awlen(cl_sh_ddr_q2.awlen),
         .slv_awvalid(cl_sh_ddr_q2.awvalid),
         .slv_awsize(cl_sh_ddr_q2.awsize),
         .slv_awuser(11'b0),
         .slv_awready(cl_sh_ddr_q2.awready),

         .slv_wid(7'b0),
         .slv_wdata(cl_sh_ddr_q2.wdata),
         .slv_wstrb(cl_sh_ddr_q2.wstrb),
         .slv_wlast(cl_sh_ddr_q2.wlast),
         .slv_wvalid(cl_sh_ddr_q2.wvalid),
         .slv_wready(cl_sh_ddr_q2.wready),

         .slv_bid(cl_sh_ddr_q2.bid[6:0]),
         .slv_bresp(cl_sh_ddr_q2.bresp),
         .slv_buser(),
         .slv_bvalid(cl_sh_ddr_q2.bvalid),
         .slv_bready(cl_sh_ddr_q2.bready),

         .slv_arid(cl_sh_ddr_q2.arid[6:0]),
         .slv_araddr(cl_sh_ddr_q2.araddr),
         .slv_arlen(cl_sh_ddr_q2.arlen),
         .slv_arvalid(cl_sh_ddr_q2.arvalid),
         .slv_arsize(cl_sh_ddr_q2.arsize),
         .slv_aruser(11'b0),
         .slv_arready(cl_sh_ddr_q2.arready),

         .slv_rid(cl_sh_ddr_q2.rid[6:0]),
         .slv_rdata(cl_sh_ddr_q2.rdata),
         .slv_rresp(cl_sh_ddr_q2.rresp),
         .slv_rlast(cl_sh_ddr_q2.rlast),
         .slv_ruser(),
         .slv_rvalid(cl_sh_ddr_q2.rvalid),
         .slv_rready(cl_sh_ddr_q2.rready),


         .awid(cl_sh_ddr_q3.awid[8:0]),
         .awaddr(cl_sh_ddr_q3.awaddr),
         .awlen(cl_sh_ddr_q3.awlen),
         .awvalid(cl_sh_ddr_q3.awvalid),
         .awsize(cl_sh_ddr_q3.awsize),
         .awuser(),
         .awready(cl_sh_ddr_q3.awready),

         //.wid(cl_sh_ddr_q3.wid),
         .wid(),
         .wdata(cl_sh_ddr_q3.wdata),
         .wstrb(cl_sh_ddr_q3.wstrb),
         .wlast(cl_sh_ddr_q3.wlast),
         .wvalid(cl_sh_ddr_q3.wvalid),
         .wready(cl_sh_ddr_q3.wready),

         .bid(cl_sh_ddr_q3.bid[8:0]),
         .bresp(cl_sh_ddr_q3.bresp),
         .buser(18'h0),
         .bvalid(cl_sh_ddr_q3.bvalid),
         .bready(cl_sh_ddr_q3.bready),

         .arid(cl_sh_ddr_q3.arid[8:0]),
         .araddr(cl_sh_ddr_q3.araddr),
         .arlen(cl_sh_ddr_q3.arlen),
         .arvalid(cl_sh_ddr_q3.arvalid),
         .arsize(cl_sh_ddr_q3.arsize),
         .aruser(),
         .arready(cl_sh_ddr_q3.arready),

         .rid(cl_sh_ddr_q3.rid[8:0]),
         .rdata(cl_sh_ddr_q3.rdata),
         .rresp(cl_sh_ddr_q3.rresp),
         .rlast(cl_sh_ddr_q3.rlast),
         .ruser(18'h0),
         .rvalid(cl_sh_ddr_q3.rvalid),
         .rready(cl_sh_ddr_q3.rready),

         .scrb_enable(ddrc_scrb_bus_q.enable),
         .scrb_done  (ddrc_scrb_bus_q.done),

         .scrb_dbg_state(ddrc_scrb_bus_q.state),
         .scrb_dbg_addr (ddrc_scrb_bus_q.addr)
   );

//----------------------------
// flop the output of ATG/Scrubber for DDRC
//----------------------------

   axi_register_slice DDR_C_TST_AXI4_REG_SLC_1 (
     .aclk           (aclk),
     .aresetn        (slr1_sync_aresetn),

     .s_axi_awid     (cl_sh_ddr_q3.awid),
     .s_axi_awaddr   (cl_sh_ddr_q3.awaddr),
     .s_axi_awlen    (cl_sh_ddr_q3.awlen),
     .s_axi_awsize   (cl_sh_ddr_q3.awsize),
     .s_axi_awvalid  (cl_sh_ddr_q3.awvalid),
     .s_axi_awready  (cl_sh_ddr_q3.awready),
     .s_axi_wdata    (cl_sh_ddr_q3.wdata),
     .s_axi_wstrb    (cl_sh_ddr_q3.wstrb),
     .s_axi_wlast    (cl_sh_ddr_q3.wlast),
     .s_axi_wvalid   (cl_sh_ddr_q3.wvalid),
     .s_axi_wready   (cl_sh_ddr_q3.wready),
     .s_axi_bid      (cl_sh_ddr_q3.bid),
     .s_axi_bresp    (cl_sh_ddr_q3.bresp),
     .s_axi_bvalid   (cl_sh_ddr_q3.bvalid),
     .s_axi_bready   (cl_sh_ddr_q3.bready),
     .s_axi_arid     (cl_sh_ddr_q3.arid),
     .s_axi_araddr   (cl_sh_ddr_q3.araddr),
     .s_axi_arlen    (cl_sh_ddr_q3.arlen),
     .s_axi_arsize   (cl_sh_ddr_q3.arsize),
     .s_axi_arvalid  (cl_sh_ddr_q3.arvalid),
     .s_axi_arready  (cl_sh_ddr_q3.arready),
     .s_axi_rid      (cl_sh_ddr_q3.rid),
     .s_axi_rdata    (cl_sh_ddr_q3.rdata),
     .s_axi_rresp    (cl_sh_ddr_q3.rresp),
     .s_axi_rlast    (cl_sh_ddr_q3.rlast),
     .s_axi_rvalid   (cl_sh_ddr_q3.rvalid),
     .s_axi_rready   (cl_sh_ddr_q3.rready),

     .m_axi_awid     (cl_sh_ddr_bus.awid),
     .m_axi_awaddr   (cl_sh_ddr_bus.awaddr),
     .m_axi_awlen    (cl_sh_ddr_bus.awlen),
     .m_axi_awsize   (cl_sh_ddr_bus.awsize),
     .m_axi_awvalid  (cl_sh_ddr_bus.awvalid),
     .m_axi_awready  (cl_sh_ddr_bus.awready),
     .m_axi_wdata    (cl_sh_ddr_bus.wdata),
     .m_axi_wstrb    (cl_sh_ddr_bus.wstrb),
     .m_axi_wlast    (cl_sh_ddr_bus.wlast),
     .m_axi_wvalid   (cl_sh_ddr_bus.wvalid),
     .m_axi_wready   (cl_sh_ddr_bus.wready),
     .m_axi_bid      (cl_sh_ddr_bus.bid),
     .m_axi_bresp    (cl_sh_ddr_bus.bresp),
     .m_axi_bvalid   (cl_sh_ddr_bus.bvalid),
     .m_axi_bready   (cl_sh_ddr_bus.bready),
     .m_axi_arid     (cl_sh_ddr_bus.arid),
     .m_axi_araddr   (cl_sh_ddr_bus.araddr),
     .m_axi_arlen    (cl_sh_ddr_bus.arlen),
     .m_axi_arsize   (cl_sh_ddr_bus.arsize),
     .m_axi_arvalid  (cl_sh_ddr_bus.arvalid),
     .m_axi_arready  (cl_sh_ddr_bus.arready),
     .m_axi_rid      (cl_sh_ddr_bus.rid),
     .m_axi_rdata    (cl_sh_ddr_bus.rdata),
     .m_axi_rresp    (cl_sh_ddr_bus.rresp),
     .m_axi_rlast    (cl_sh_ddr_bus.rlast),
     .m_axi_rvalid   (cl_sh_ddr_bus.rvalid),
     .m_axi_rready   (cl_sh_ddr_bus.rready)
   );


//----------------------------
// flop the output of interconnect for DDRA
// back to back for SLR crossing
//----------------------------
   //back to back register slices for SLR crossing
   src_register_slice DDR_A_TST_AXI4_REG_SLC_1 (
       .aclk           (aclk),
       .aresetn        (slr1_sync_aresetn),
       .s_axi_awid     (lcl_cl_sh_ddra_q.awid),
       .s_axi_awaddr   ({lcl_cl_sh_ddra_q.awaddr[63:36], 2'b0, lcl_cl_sh_ddra_q.awaddr[33:0]}),
       .s_axi_awlen    (lcl_cl_sh_ddra_q.awlen),
       .s_axi_awsize   (lcl_cl_sh_ddra_q.awsize),
       .s_axi_awburst  (2'b1),
       .s_axi_awlock   (1'b0),
       .s_axi_awcache  (4'b11),
       .s_axi_awprot   (3'b10),
       .s_axi_awregion (4'b0),
       .s_axi_awqos    (4'b0),
       .s_axi_awvalid  (lcl_cl_sh_ddra_q.awvalid),
       .s_axi_awready  (lcl_cl_sh_ddra_q.awready),
       .s_axi_wdata    (lcl_cl_sh_ddra_q.wdata),
       .s_axi_wstrb    (lcl_cl_sh_ddra_q.wstrb),
       .s_axi_wlast    (lcl_cl_sh_ddra_q.wlast),
       .s_axi_wvalid   (lcl_cl_sh_ddra_q.wvalid),
       .s_axi_wready   (lcl_cl_sh_ddra_q.wready),
       .s_axi_bid      (lcl_cl_sh_ddra_q.bid),
       .s_axi_bresp    (lcl_cl_sh_ddra_q.bresp),
       .s_axi_bvalid   (lcl_cl_sh_ddra_q.bvalid),
       .s_axi_bready   (lcl_cl_sh_ddra_q.bready),
       .s_axi_arid     (lcl_cl_sh_ddra_q.arid),
       .s_axi_araddr   ({lcl_cl_sh_ddra_q.araddr[63:36], 2'b0, lcl_cl_sh_ddra_q.araddr[33:0]}),
       .s_axi_arlen    (lcl_cl_sh_ddra_q.arlen),
       .s_axi_arsize   (lcl_cl_sh_ddra_q.arsize),
       .s_axi_arburst  (2'b1),
       .s_axi_arlock   (1'b0),
       .s_axi_arcache  (4'b11),
       .s_axi_arprot   (3'b10),
       .s_axi_arregion (4'b0),
       .s_axi_arqos    (4'b0),
       .s_axi_arvalid  (lcl_cl_sh_ddra_q.arvalid),
       .s_axi_arready  (lcl_cl_sh_ddra_q.arready),
       .s_axi_rid      (lcl_cl_sh_ddra_q.rid),
       .s_axi_rdata    (lcl_cl_sh_ddra_q.rdata),
       .s_axi_rresp    (lcl_cl_sh_ddra_q.rresp),
       .s_axi_rlast    (lcl_cl_sh_ddra_q.rlast),
       .s_axi_rvalid   (lcl_cl_sh_ddra_q.rvalid),
       .s_axi_rready   (lcl_cl_sh_ddra_q.rready),
       .m_axi_awid     (lcl_cl_sh_ddra_q2.awid),
       .m_axi_awaddr   (lcl_cl_sh_ddra_q2.awaddr),
       .m_axi_awlen    (lcl_cl_sh_ddra_q2.awlen),
       .m_axi_awsize   (lcl_cl_sh_ddra_q2.awsize),
       .m_axi_awburst  (),
       .m_axi_awlock   (),
       .m_axi_awcache  (),
       .m_axi_awprot   (),
       .m_axi_awregion (),
       .m_axi_awqos    (),
       .m_axi_awvalid  (lcl_cl_sh_ddra_q2.awvalid),
       .m_axi_awready  (lcl_cl_sh_ddra_q2.awready),
       .m_axi_wdata    (lcl_cl_sh_ddra_q2.wdata),
       .m_axi_wstrb    (lcl_cl_sh_ddra_q2.wstrb),
       .m_axi_wlast    (lcl_cl_sh_ddra_q2.wlast),
       .m_axi_wvalid   (lcl_cl_sh_ddra_q2.wvalid),
       .m_axi_wready   (lcl_cl_sh_ddra_q2.wready),
       .m_axi_bid      (lcl_cl_sh_ddra_q2.bid),
       .m_axi_bresp    (lcl_cl_sh_ddra_q2.bresp),
       .m_axi_bvalid   (lcl_cl_sh_ddra_q2.bvalid),
       .m_axi_bready   (lcl_cl_sh_ddra_q2.bready),
       .m_axi_arid     (lcl_cl_sh_ddra_q2.arid),
       .m_axi_araddr   (lcl_cl_sh_ddra_q2.araddr),
       .m_axi_arlen    (lcl_cl_sh_ddra_q2.arlen),
       .m_axi_arsize   (lcl_cl_sh_ddra_q2.arsize),
       .m_axi_arburst  (),
       .m_axi_arlock   (),
       .m_axi_arcache  (),
       .m_axi_arprot   (),
       .m_axi_arregion (),
       .m_axi_arqos    (),
       .m_axi_arvalid  (lcl_cl_sh_ddra_q2.arvalid),
       .m_axi_arready  (lcl_cl_sh_ddra_q2.arready),
       .m_axi_rid      (lcl_cl_sh_ddra_q2.rid),
       .m_axi_rdata    (lcl_cl_sh_ddra_q2.rdata),
       .m_axi_rresp    (lcl_cl_sh_ddra_q2.rresp),
       .m_axi_rlast    (lcl_cl_sh_ddra_q2.rlast),
       .m_axi_rvalid   (lcl_cl_sh_ddra_q2.rvalid),
       .m_axi_rready   (lcl_cl_sh_ddra_q2.rready)
       );
   dest_register_slice DDR_A_TST_AXI4_REG_SLC_2 (
       .aclk           (aclk),
       .aresetn        (slr2_sync_aresetn),
       .s_axi_awid     (lcl_cl_sh_ddra_q2.awid),
       .s_axi_awaddr   (lcl_cl_sh_ddra_q2.awaddr),
       .s_axi_awlen    (lcl_cl_sh_ddra_q2.awlen),
       .s_axi_awsize   (lcl_cl_sh_ddra_q2.awsize),
       .s_axi_awburst  (2'b1),
       .s_axi_awlock   (1'b0),
       .s_axi_awcache  (4'b11),
       .s_axi_awprot   (3'b10),
       .s_axi_awregion (4'b0),
       .s_axi_awqos    (4'b0),
       .s_axi_awvalid  (lcl_cl_sh_ddra_q2.awvalid),
       .s_axi_awready  (lcl_cl_sh_ddra_q2.awready),
       .s_axi_wdata    (lcl_cl_sh_ddra_q2.wdata),
       .s_axi_wstrb    (lcl_cl_sh_ddra_q2.wstrb),
       .s_axi_wlast    (lcl_cl_sh_ddra_q2.wlast),
       .s_axi_wvalid   (lcl_cl_sh_ddra_q2.wvalid),
       .s_axi_wready   (lcl_cl_sh_ddra_q2.wready),
       .s_axi_bid      (lcl_cl_sh_ddra_q2.bid),
       .s_axi_bresp    (lcl_cl_sh_ddra_q2.bresp),
       .s_axi_bvalid   (lcl_cl_sh_ddra_q2.bvalid),
       .s_axi_bready   (lcl_cl_sh_ddra_q2.bready),
       .s_axi_arid     (lcl_cl_sh_ddra_q2.arid),
       .s_axi_araddr   (lcl_cl_sh_ddra_q2.araddr),
       .s_axi_arlen    (lcl_cl_sh_ddra_q2.arlen),
       .s_axi_arsize   (lcl_cl_sh_ddra_q2.arsize),
       .s_axi_arburst  (2'b1),
       .s_axi_arlock   (1'b0),
       .s_axi_arcache  (4'b11),
       .s_axi_arprot   (3'b10),
       .s_axi_arregion (4'b0),
       .s_axi_arqos    (4'b0),
       .s_axi_arvalid  (lcl_cl_sh_ddra_q2.arvalid),
       .s_axi_arready  (lcl_cl_sh_ddra_q2.arready),
       .s_axi_rid      (lcl_cl_sh_ddra_q2.rid),
       .s_axi_rdata    (lcl_cl_sh_ddra_q2.rdata),
       .s_axi_rresp    (lcl_cl_sh_ddra_q2.rresp),
       .s_axi_rlast    (lcl_cl_sh_ddra_q2.rlast),
       .s_axi_rvalid   (lcl_cl_sh_ddra_q2.rvalid),
       .s_axi_rready   (lcl_cl_sh_ddra_q2.rready),
       .m_axi_awid     (lcl_cl_sh_ddra_q3.awid),
       .m_axi_awaddr   (lcl_cl_sh_ddra_q3.awaddr),
       .m_axi_awlen    (lcl_cl_sh_ddra_q3.awlen),
       .m_axi_awsize   (lcl_cl_sh_ddra_q3.awsize),
       .m_axi_awburst  (),
       .m_axi_awlock   (),
       .m_axi_awcache  (),
       .m_axi_awprot   (),
       .m_axi_awregion (),
       .m_axi_awqos    (),
       .m_axi_awvalid  (lcl_cl_sh_ddra_q3.awvalid),
       .m_axi_awready  (lcl_cl_sh_ddra_q3.awready),
       .m_axi_wdata    (lcl_cl_sh_ddra_q3.wdata),
       .m_axi_wstrb    (lcl_cl_sh_ddra_q3.wstrb),
       .m_axi_wlast    (lcl_cl_sh_ddra_q3.wlast),
       .m_axi_wvalid   (lcl_cl_sh_ddra_q3.wvalid),
       .m_axi_wready   (lcl_cl_sh_ddra_q3.wready),
       .m_axi_bid      (lcl_cl_sh_ddra_q3.bid),
       .m_axi_bresp    (lcl_cl_sh_ddra_q3.bresp),
       .m_axi_bvalid   (lcl_cl_sh_ddra_q3.bvalid),
       .m_axi_bready   (lcl_cl_sh_ddra_q3.bready),
       .m_axi_arid     (lcl_cl_sh_ddra_q3.arid),
       .m_axi_araddr   (lcl_cl_sh_ddra_q3.araddr),
       .m_axi_arlen    (lcl_cl_sh_ddra_q3.arlen),
       .m_axi_arsize   (lcl_cl_sh_ddra_q3.arsize),
       .m_axi_arburst  (),
       .m_axi_arlock   (),
       .m_axi_arcache  (),
       .m_axi_arprot   (),
       .m_axi_arregion (),
       .m_axi_arqos    (),
       .m_axi_arvalid  (lcl_cl_sh_ddra_q3.arvalid),
       .m_axi_arready  (lcl_cl_sh_ddra_q3.arready),
       .m_axi_rid      (lcl_cl_sh_ddra_q3.rid),
       .m_axi_rdata    (lcl_cl_sh_ddra_q3.rdata),
       .m_axi_rresp    (lcl_cl_sh_ddra_q3.rresp),
       .m_axi_rlast    (lcl_cl_sh_ddra_q3.rlast),
       .m_axi_rvalid   (lcl_cl_sh_ddra_q3.rvalid),
       .m_axi_rready   (lcl_cl_sh_ddra_q3.rready)
       );

//----------------------------
// ATG/scrubber for DDRA
//----------------------------
   lib_pipe #(.WIDTH(32+32+1+1), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_CFG_REQ_DDR_A (.clk (aclk),
                                                              .rst_n (aresetn),
                                                              .in_bus({ddra_tst_cfg_bus.addr, ddra_tst_cfg_bus.wdata, ddra_tst_cfg_bus.wr, ddra_tst_cfg_bus.rd}),
                                                              .out_bus({ddra_tst_cfg_bus_q.addr, ddra_tst_cfg_bus_q.wdata, ddra_tst_cfg_bus_q.wr, ddra_tst_cfg_bus_q.rd})
                                                              );

   lib_pipe #(.WIDTH(32+1), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_CFG_ACK_DDR_A (.clk (aclk),
                                                              .rst_n (aresetn),
                                                              .in_bus({ddra_tst_cfg_bus_q.ack, ddra_tst_cfg_bus_q.rdata}),
                                                              .out_bus({ddra_tst_cfg_bus.ack, ddra_tst_cfg_bus.rdata})
                                                              );


   lib_pipe #(.WIDTH(2+3+64), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_SCRB_DDR_A (.clk(aclk),
                                                              .rst_n(aresetn),
                                                              .in_bus({ddra_scrb_bus.enable, ddra_scrb_bus_q.done, ddra_scrb_bus_q.state, ddra_scrb_bus_q.addr}),
                                                              .out_bus({ddra_scrb_bus_q.enable, ddra_scrb_bus.done, ddra_scrb_bus.state, ddra_scrb_bus.addr})
                                                              );

   cl_tst_scrb #(.DATA_WIDTH(512),
                    .SCRB_BURST_LEN_MINUS1(SCRB_BURST_LEN_MINUS1),
                    .SCRB_MAX_ADDR(SCRB_MAX_ADDR),
                    .NO_SCRB_INST(NO_SCRB_INST)) CL_TST_DDR_A (

         .clk(aclk),
         .rst_n(slr2_sync_aresetn),

         .cfg_addr(ddra_tst_cfg_bus_q.addr),
         .cfg_wdata(ddra_tst_cfg_bus_q.wdata),
         .cfg_wr(ddra_tst_cfg_bus_q.wr),
         .cfg_rd(ddra_tst_cfg_bus_q.rd),
         .tst_cfg_ack(ddra_tst_cfg_bus_q.ack),
         .tst_cfg_rdata(ddra_tst_cfg_bus_q.rdata),

         .slv_awid(lcl_cl_sh_ddra_q3.awid[6:0]),
         .slv_awaddr(lcl_cl_sh_ddra_q3.awaddr),
         .slv_awlen(lcl_cl_sh_ddra_q3.awlen),
         .slv_awsize(lcl_cl_sh_ddra_q3.awsize),
         .slv_awvalid(lcl_cl_sh_ddra_q3.awvalid),
         .slv_awuser(11'b0),
         .slv_awready(lcl_cl_sh_ddra_q3.awready),

         .slv_wid(7'b0),
         .slv_wdata(lcl_cl_sh_ddra_q3.wdata),
         .slv_wstrb(lcl_cl_sh_ddra_q3.wstrb),
         .slv_wlast(lcl_cl_sh_ddra_q3.wlast),
         .slv_wvalid(lcl_cl_sh_ddra_q3.wvalid),
         .slv_wready(lcl_cl_sh_ddra_q3.wready),

         .slv_bid(lcl_cl_sh_ddra_q3.bid[6:0]),
         .slv_bresp(lcl_cl_sh_ddra_q3.bresp),
         .slv_buser(),
         .slv_bvalid(lcl_cl_sh_ddra_q3.bvalid),
         .slv_bready(lcl_cl_sh_ddra_q3.bready),

         .slv_arid(lcl_cl_sh_ddra_q3.arid[6:0]),
         .slv_araddr(lcl_cl_sh_ddra_q3.araddr),
         .slv_arlen(lcl_cl_sh_ddra_q3.arlen),
         .slv_arsize(lcl_cl_sh_ddra_q3.arsize),
         .slv_arvalid(lcl_cl_sh_ddra_q3.arvalid),
         .slv_aruser(11'b0),
         .slv_arready(lcl_cl_sh_ddra_q3.arready),

         .slv_rid(lcl_cl_sh_ddra_q3.rid[6:0]),
         .slv_rdata(lcl_cl_sh_ddra_q3.rdata),
         .slv_rresp(lcl_cl_sh_ddra_q3.rresp),
         .slv_rlast(lcl_cl_sh_ddra_q3.rlast),
         .slv_ruser(),
         .slv_rvalid(lcl_cl_sh_ddra_q3.rvalid),
         .slv_rready(lcl_cl_sh_ddra_q3.rready),


         .awid(lcl_cl_sh_ddra.awid[8:0]),
         .awaddr(lcl_cl_sh_ddra.awaddr),
         .awlen(lcl_cl_sh_ddra.awlen),
         .awsize(lcl_cl_sh_ddra.awsize),
         .awvalid(lcl_cl_sh_ddra.awvalid),
         .awuser(),
         .awready(lcl_cl_sh_ddra.awready),

         .wid(lcl_cl_sh_ddra.wid[8:0]),
         .wdata(lcl_cl_sh_ddra.wdata),
         .wstrb(lcl_cl_sh_ddra.wstrb),
         .wlast(lcl_cl_sh_ddra.wlast),
         .wvalid(lcl_cl_sh_ddra.wvalid),
         .wready(lcl_cl_sh_ddra.wready),

         .bid(lcl_cl_sh_ddra.bid[8:0]),
         .bresp(lcl_cl_sh_ddra.bresp),
         .buser(18'h0),
         .bvalid(lcl_cl_sh_ddra.bvalid),
         .bready(lcl_cl_sh_ddra.bready),

         .arid(lcl_cl_sh_ddra.arid[8:0]),
         .araddr(lcl_cl_sh_ddra.araddr),
         .arlen(lcl_cl_sh_ddra.arlen),
         .arsize(lcl_cl_sh_ddra.arsize),
         .arvalid(lcl_cl_sh_ddra.arvalid),
         .aruser(),
         .arready(lcl_cl_sh_ddra.arready),

         .rid(lcl_cl_sh_ddra.rid[8:0]),
         .rdata(lcl_cl_sh_ddra.rdata),
         .rresp(lcl_cl_sh_ddra.rresp),
         .rlast(lcl_cl_sh_ddra.rlast),
         .ruser(18'h0),
         .rvalid(lcl_cl_sh_ddra.rvalid),
         .rready(lcl_cl_sh_ddra.rready),

         .scrb_enable(ddra_scrb_bus_q.enable),
         .scrb_done  (ddra_scrb_bus_q.done),

         .scrb_dbg_state(ddra_scrb_bus_q.state),
         .scrb_dbg_addr (ddra_scrb_bus_q.addr)
      );
      assign lcl_cl_sh_ddra.awid[15:9] = 7'b0;
      assign lcl_cl_sh_ddra.wid[15:9] = 7'b0;
      assign lcl_cl_sh_ddra.arid[15:9] = 7'b0;

//----------------------------
// flop the output of interconnect for DDRB
// back to back for SLR crossing
//----------------------------

  //back to back register slices for SLR crossing
   src_register_slice DDR_B_TST_AXI4_REG_SLC_1 (
       .aclk           (aclk),
       .aresetn        (slr1_sync_aresetn),
       .s_axi_awid     (lcl_cl_sh_ddrb_q.awid),
       .s_axi_awaddr   ({lcl_cl_sh_ddrb_q.awaddr[63:36], 2'b0, lcl_cl_sh_ddrb_q.awaddr[33:0]}),
       .s_axi_awlen    (lcl_cl_sh_ddrb_q.awlen),
       .s_axi_awsize   (lcl_cl_sh_ddrb_q.awsize),
       .s_axi_awburst  (2'b1),
       .s_axi_awlock   (1'b0),
       .s_axi_awcache  (4'b11),
       .s_axi_awprot   (3'b10),
       .s_axi_awregion (4'b0),
       .s_axi_awqos    (4'b0),
       .s_axi_awvalid  (lcl_cl_sh_ddrb_q.awvalid),
       .s_axi_awready  (lcl_cl_sh_ddrb_q.awready),
       .s_axi_wdata    (lcl_cl_sh_ddrb_q.wdata),
       .s_axi_wstrb    (lcl_cl_sh_ddrb_q.wstrb),
       .s_axi_wlast    (lcl_cl_sh_ddrb_q.wlast),
       .s_axi_wvalid   (lcl_cl_sh_ddrb_q.wvalid),
       .s_axi_wready   (lcl_cl_sh_ddrb_q.wready),
       .s_axi_bid      (lcl_cl_sh_ddrb_q.bid),
       .s_axi_bresp    (lcl_cl_sh_ddrb_q.bresp),
       .s_axi_bvalid   (lcl_cl_sh_ddrb_q.bvalid),
       .s_axi_bready   (lcl_cl_sh_ddrb_q.bready),
       .s_axi_arid     (lcl_cl_sh_ddrb_q.arid),
       .s_axi_araddr   ({lcl_cl_sh_ddrb_q.araddr[63:36], 2'b0, lcl_cl_sh_ddrb_q.araddr[33:0]}),
       .s_axi_arlen    (lcl_cl_sh_ddrb_q.arlen),
       .s_axi_arsize   (lcl_cl_sh_ddrb_q.arsize),
       .s_axi_arburst  (2'b1),
       .s_axi_arlock   (1'b0),
       .s_axi_arcache  (4'b11),
       .s_axi_arprot   (3'b10),
       .s_axi_arregion (4'b0),
       .s_axi_arqos    (4'b0),
       .s_axi_arvalid  (lcl_cl_sh_ddrb_q.arvalid),
       .s_axi_arready  (lcl_cl_sh_ddrb_q.arready),
       .s_axi_rid      (lcl_cl_sh_ddrb_q.rid),
       .s_axi_rdata    (lcl_cl_sh_ddrb_q.rdata),
       .s_axi_rresp    (lcl_cl_sh_ddrb_q.rresp),
       .s_axi_rlast    (lcl_cl_sh_ddrb_q.rlast),
       .s_axi_rvalid   (lcl_cl_sh_ddrb_q.rvalid),
       .s_axi_rready   (lcl_cl_sh_ddrb_q.rready),
       .m_axi_awid     (lcl_cl_sh_ddrb_q2.awid),
       .m_axi_awaddr   (lcl_cl_sh_ddrb_q2.awaddr),
       .m_axi_awlen    (lcl_cl_sh_ddrb_q2.awlen),
       .m_axi_awsize   (lcl_cl_sh_ddrb_q2.awsize),
       .m_axi_awburst  (),
       .m_axi_awlock   (),
       .m_axi_awcache  (),
       .m_axi_awprot   (),
       .m_axi_awregion (),
       .m_axi_awqos    (),
       .m_axi_awvalid  (lcl_cl_sh_ddrb_q2.awvalid),
       .m_axi_awready  (lcl_cl_sh_ddrb_q2.awready),
       .m_axi_wdata    (lcl_cl_sh_ddrb_q2.wdata),
       .m_axi_wstrb    (lcl_cl_sh_ddrb_q2.wstrb),
       .m_axi_wlast    (lcl_cl_sh_ddrb_q2.wlast),
       .m_axi_wvalid   (lcl_cl_sh_ddrb_q2.wvalid),
       .m_axi_wready   (lcl_cl_sh_ddrb_q2.wready),
       .m_axi_bid      (lcl_cl_sh_ddrb_q2.bid),
       .m_axi_bresp    (lcl_cl_sh_ddrb_q2.bresp),
       .m_axi_bvalid   (lcl_cl_sh_ddrb_q2.bvalid),
       .m_axi_bready   (lcl_cl_sh_ddrb_q2.bready),
       .m_axi_arid     (lcl_cl_sh_ddrb_q2.arid),
       .m_axi_araddr   (lcl_cl_sh_ddrb_q2.araddr),
       .m_axi_arlen    (lcl_cl_sh_ddrb_q2.arlen),
       .m_axi_arsize   (lcl_cl_sh_ddrb_q2.arsize),
       .m_axi_arburst  (),
       .m_axi_arlock   (),
       .m_axi_arcache  (),
       .m_axi_arprot   (),
       .m_axi_arregion (),
       .m_axi_arqos    (),
       .m_axi_arvalid  (lcl_cl_sh_ddrb_q2.arvalid),
       .m_axi_arready  (lcl_cl_sh_ddrb_q2.arready),
       .m_axi_rid      (lcl_cl_sh_ddrb_q2.rid),
       .m_axi_rdata    (lcl_cl_sh_ddrb_q2.rdata),
       .m_axi_rresp    (lcl_cl_sh_ddrb_q2.rresp),
       .m_axi_rlast    (lcl_cl_sh_ddrb_q2.rlast),
       .m_axi_rvalid   (lcl_cl_sh_ddrb_q2.rvalid),
       .m_axi_rready   (lcl_cl_sh_ddrb_q2.rready)
       );
   dest_register_slice DDR_B_TST_AXI4_REG_SLC_2 (
       .aclk           (aclk),
       .aresetn        (slr1_sync_aresetn),
       .s_axi_awid     (lcl_cl_sh_ddrb_q2.awid),
       .s_axi_awaddr   (lcl_cl_sh_ddrb_q2.awaddr),
       .s_axi_awlen    (lcl_cl_sh_ddrb_q2.awlen),
       .s_axi_awsize   (lcl_cl_sh_ddrb_q2.awsize),
       .s_axi_awburst  (2'b1),
       .s_axi_awlock   (1'b0),
       .s_axi_awcache  (4'b11),
       .s_axi_awprot   (3'b10),
       .s_axi_awregion (4'b0),
       .s_axi_awqos    (4'b0),
       .s_axi_awvalid  (lcl_cl_sh_ddrb_q2.awvalid),
       .s_axi_awready  (lcl_cl_sh_ddrb_q2.awready),
       .s_axi_wdata    (lcl_cl_sh_ddrb_q2.wdata),
       .s_axi_wstrb    (lcl_cl_sh_ddrb_q2.wstrb),
       .s_axi_wlast    (lcl_cl_sh_ddrb_q2.wlast),
       .s_axi_wvalid   (lcl_cl_sh_ddrb_q2.wvalid),
       .s_axi_wready   (lcl_cl_sh_ddrb_q2.wready),
       .s_axi_bid      (lcl_cl_sh_ddrb_q2.bid),
       .s_axi_bresp    (lcl_cl_sh_ddrb_q2.bresp),
       .s_axi_bvalid   (lcl_cl_sh_ddrb_q2.bvalid),
       .s_axi_bready   (lcl_cl_sh_ddrb_q2.bready),
       .s_axi_arid     (lcl_cl_sh_ddrb_q2.arid),
       .s_axi_araddr   (lcl_cl_sh_ddrb_q2.araddr),
       .s_axi_arlen    (lcl_cl_sh_ddrb_q2.arlen),
       .s_axi_arsize   (lcl_cl_sh_ddrb_q2.arsize),
       .s_axi_arburst  (2'b1),
       .s_axi_arlock   (1'b0),
       .s_axi_arcache  (4'b11),
       .s_axi_arprot   (3'b10),
       .s_axi_arregion (4'b0),
       .s_axi_arqos    (4'b0),
       .s_axi_arvalid  (lcl_cl_sh_ddrb_q2.arvalid),
       .s_axi_arready  (lcl_cl_sh_ddrb_q2.arready),
       .s_axi_rid      (lcl_cl_sh_ddrb_q2.rid),
       .s_axi_rdata    (lcl_cl_sh_ddrb_q2.rdata),
       .s_axi_rresp    (lcl_cl_sh_ddrb_q2.rresp),
       .s_axi_rlast    (lcl_cl_sh_ddrb_q2.rlast),
       .s_axi_rvalid   (lcl_cl_sh_ddrb_q2.rvalid),
       .s_axi_rready   (lcl_cl_sh_ddrb_q2.rready),
       .m_axi_awid     (lcl_cl_sh_ddrb_q3.awid),
       .m_axi_awaddr   (lcl_cl_sh_ddrb_q3.awaddr),
       .m_axi_awlen    (lcl_cl_sh_ddrb_q3.awlen),
       .m_axi_awsize   (lcl_cl_sh_ddrb_q3.awsize),
       .m_axi_awburst  (),
       .m_axi_awlock   (),
       .m_axi_awcache  (),
       .m_axi_awprot   (),
       .m_axi_awregion (),
       .m_axi_awqos    (),
       .m_axi_awvalid  (lcl_cl_sh_ddrb_q3.awvalid),
       .m_axi_awready  (lcl_cl_sh_ddrb_q3.awready),
       .m_axi_wdata    (lcl_cl_sh_ddrb_q3.wdata),
       .m_axi_wstrb    (lcl_cl_sh_ddrb_q3.wstrb),
       .m_axi_wlast    (lcl_cl_sh_ddrb_q3.wlast),
       .m_axi_wvalid   (lcl_cl_sh_ddrb_q3.wvalid),
       .m_axi_wready   (lcl_cl_sh_ddrb_q3.wready),
       .m_axi_bid      (lcl_cl_sh_ddrb_q3.bid),
       .m_axi_bresp    (lcl_cl_sh_ddrb_q3.bresp),
       .m_axi_bvalid   (lcl_cl_sh_ddrb_q3.bvalid),
       .m_axi_bready   (lcl_cl_sh_ddrb_q3.bready),
       .m_axi_arid     (lcl_cl_sh_ddrb_q3.arid),
       .m_axi_araddr   (lcl_cl_sh_ddrb_q3.araddr),
       .m_axi_arlen    (lcl_cl_sh_ddrb_q3.arlen),
       .m_axi_arsize   (lcl_cl_sh_ddrb_q3.arsize),
       .m_axi_arburst  (),
       .m_axi_arlock   (),
       .m_axi_arcache  (),
       .m_axi_arprot   (),
       .m_axi_arregion (),
       .m_axi_arqos    (),
       .m_axi_arvalid  (lcl_cl_sh_ddrb_q3.arvalid),
       .m_axi_arready  (lcl_cl_sh_ddrb_q3.arready),
       .m_axi_rid      (lcl_cl_sh_ddrb_q3.rid),
       .m_axi_rdata    (lcl_cl_sh_ddrb_q3.rdata),
       .m_axi_rresp    (lcl_cl_sh_ddrb_q3.rresp),
       .m_axi_rlast    (lcl_cl_sh_ddrb_q3.rlast),
       .m_axi_rvalid   (lcl_cl_sh_ddrb_q3.rvalid),
       .m_axi_rready   (lcl_cl_sh_ddrb_q3.rready)
       );

//----------------------------
// ATG/scrubber for DDRB
//----------------------------
   lib_pipe #(.WIDTH(32+32+1+1), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_CFG_REQ_DDR_B (.clk (aclk),
                                                              .rst_n (aresetn),
                                                              .in_bus({ddrb_tst_cfg_bus.addr, ddrb_tst_cfg_bus.wdata, ddrb_tst_cfg_bus.wr, ddrb_tst_cfg_bus.rd}),
                                                              .out_bus({ddrb_tst_cfg_bus_q.addr, ddrb_tst_cfg_bus_q.wdata, ddrb_tst_cfg_bus_q.wr, ddrb_tst_cfg_bus_q.rd})
                                                              );

   lib_pipe #(.WIDTH(32+1), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_CFG_ACK_DDR_B (.clk (aclk),
                                                              .rst_n (aresetn),
                                                              .in_bus({ddrb_tst_cfg_bus_q.ack, ddrb_tst_cfg_bus_q.rdata}),
                                                              .out_bus({ddrb_tst_cfg_bus.ack, ddrb_tst_cfg_bus.rdata})
                                                              );


   lib_pipe #(.WIDTH(2+3+64), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_SCRB_DDR_B (.clk(aclk),
                                                              .rst_n(aresetn),
                                                              .in_bus({ddrb_scrb_bus.enable, ddrb_scrb_bus_q.done, ddrb_scrb_bus_q.state, ddrb_scrb_bus_q.addr}),
                                                              .out_bus({ddrb_scrb_bus_q.enable, ddrb_scrb_bus.done, ddrb_scrb_bus.state, ddrb_scrb_bus.addr})
                                                              );

   cl_tst_scrb #(.DATA_WIDTH(512),
                    .SCRB_BURST_LEN_MINUS1(SCRB_BURST_LEN_MINUS1),
                    .SCRB_MAX_ADDR(SCRB_MAX_ADDR),
                    .NO_SCRB_INST(NO_SCRB_INST)) CL_TST_DDR_B (

         .clk(aclk),
         .rst_n(slr1_sync_aresetn),

         .cfg_addr(ddrb_tst_cfg_bus_q.addr),
         .cfg_wdata(ddrb_tst_cfg_bus_q.wdata),
         .cfg_wr(ddrb_tst_cfg_bus_q.wr),
         .cfg_rd(ddrb_tst_cfg_bus_q.rd),
         .tst_cfg_ack(ddrb_tst_cfg_bus_q.ack),
         .tst_cfg_rdata(ddrb_tst_cfg_bus_q.rdata),

         .slv_awid(lcl_cl_sh_ddrb_q3.awid[6:0]),
         .slv_awaddr(lcl_cl_sh_ddrb_q3.awaddr),
         .slv_awlen(lcl_cl_sh_ddrb_q3.awlen),
         .slv_awsize(lcl_cl_sh_ddrb_q3.awsize),
         .slv_awvalid(lcl_cl_sh_ddrb_q3.awvalid),
         .slv_awuser(11'b0),
         .slv_awready(lcl_cl_sh_ddrb_q3.awready),

         .slv_wid(7'b0),
         .slv_wdata(lcl_cl_sh_ddrb_q3.wdata),
         .slv_wstrb(lcl_cl_sh_ddrb_q3.wstrb),
         .slv_wlast(lcl_cl_sh_ddrb_q3.wlast),
         .slv_wvalid(lcl_cl_sh_ddrb_q3.wvalid),
         .slv_wready(lcl_cl_sh_ddrb_q3.wready),

         .slv_bid(lcl_cl_sh_ddrb_q3.bid[6:0]),
         .slv_bresp(lcl_cl_sh_ddrb_q3.bresp),
         .slv_buser(),
         .slv_bvalid(lcl_cl_sh_ddrb_q3.bvalid),
         .slv_bready(lcl_cl_sh_ddrb_q3.bready),

         .slv_arid(lcl_cl_sh_ddrb_q3.arid[6:0]),
         .slv_araddr(lcl_cl_sh_ddrb_q3.araddr),
         .slv_arlen(lcl_cl_sh_ddrb_q3.arlen),
         .slv_arsize(lcl_cl_sh_ddrb_q3.arsize),
         .slv_arvalid(lcl_cl_sh_ddrb_q3.arvalid),
         .slv_aruser(11'b0),
         .slv_arready(lcl_cl_sh_ddrb_q3.arready),

         .slv_rid(lcl_cl_sh_ddrb_q3.rid[6:0]),
         .slv_rdata(lcl_cl_sh_ddrb_q3.rdata),
         .slv_rresp(lcl_cl_sh_ddrb_q3.rresp),
         .slv_rlast(lcl_cl_sh_ddrb_q3.rlast),
         .slv_ruser(),
         .slv_rvalid(lcl_cl_sh_ddrb_q3.rvalid),
         .slv_rready(lcl_cl_sh_ddrb_q3.rready),


         .awid(lcl_cl_sh_ddrb.awid[8:0]),
         .awaddr(lcl_cl_sh_ddrb.awaddr),
         .awlen(lcl_cl_sh_ddrb.awlen),
         .awsize(lcl_cl_sh_ddrb.awsize),
         .awvalid(lcl_cl_sh_ddrb.awvalid),
         .awuser(),
         .awready(lcl_cl_sh_ddrb.awready),

         .wid(lcl_cl_sh_ddrb.wid[8:0]),
         .wdata(lcl_cl_sh_ddrb.wdata),
         .wstrb(lcl_cl_sh_ddrb.wstrb),
         .wlast(lcl_cl_sh_ddrb.wlast),
         .wvalid(lcl_cl_sh_ddrb.wvalid),
         .wready(lcl_cl_sh_ddrb.wready),

         .bid(lcl_cl_sh_ddrb.bid[8:0]),
         .bresp(lcl_cl_sh_ddrb.bresp),
         .buser(18'h0),
         .bvalid(lcl_cl_sh_ddrb.bvalid),
         .bready(lcl_cl_sh_ddrb.bready),

         .arid(lcl_cl_sh_ddrb.arid[8:0]),
         .araddr(lcl_cl_sh_ddrb.araddr),
         .arlen(lcl_cl_sh_ddrb.arlen),
         .arsize(lcl_cl_sh_ddrb.arsize),
         .arvalid(lcl_cl_sh_ddrb.arvalid),
         .aruser(),
         .arready(lcl_cl_sh_ddrb.arready),

         .rid(lcl_cl_sh_ddrb.rid[8:0]),
         .rdata(lcl_cl_sh_ddrb.rdata),
         .rresp(lcl_cl_sh_ddrb.rresp),
         .rlast(lcl_cl_sh_ddrb.rlast),
         .ruser(18'h0),
         .rvalid(lcl_cl_sh_ddrb.rvalid),
         .rready(lcl_cl_sh_ddrb.rready),

         .scrb_enable(ddrb_scrb_bus_q.enable),
         .scrb_done  (ddrb_scrb_bus_q.done),

         .scrb_dbg_state(ddrb_scrb_bus_q.state),
         .scrb_dbg_addr (ddrb_scrb_bus_q.addr)
      );
      assign lcl_cl_sh_ddrb.awid[15:9] = 7'b0;
      assign lcl_cl_sh_ddrb.wid[15:9] = 7'b0;
      assign lcl_cl_sh_ddrb.arid[15:9] = 7'b0;


//----------------------------
// flop the output of interconnect for DDRD
// back to back for SLR crossing
//----------------------------

  //back to back register slices for SLR crossing
   src_register_slice DDR_D_TST_AXI4_REG_SLC_1 (
       .aclk           (aclk),
       .aresetn        (slr1_sync_aresetn),
       .s_axi_awid     (lcl_cl_sh_ddrd_q.awid),
       .s_axi_awaddr   ({lcl_cl_sh_ddrd_q.awaddr[63:36], 2'b0, lcl_cl_sh_ddrd_q.awaddr[33:0]}),
       .s_axi_awlen    (lcl_cl_sh_ddrd_q.awlen),
       .s_axi_awsize   (lcl_cl_sh_ddrd_q.awsize),
       .s_axi_awburst  (2'b1),
       .s_axi_awlock   (1'b0),
       .s_axi_awcache  (4'b11),
       .s_axi_awprot   (3'b10),
       .s_axi_awregion (4'b0),
       .s_axi_awqos    (4'b0),
       .s_axi_awvalid  (lcl_cl_sh_ddrd_q.awvalid),
       .s_axi_awready  (lcl_cl_sh_ddrd_q.awready),
       .s_axi_wdata    (lcl_cl_sh_ddrd_q.wdata),
       .s_axi_wstrb    (lcl_cl_sh_ddrd_q.wstrb),
       .s_axi_wlast    (lcl_cl_sh_ddrd_q.wlast),
       .s_axi_wvalid   (lcl_cl_sh_ddrd_q.wvalid),
       .s_axi_wready   (lcl_cl_sh_ddrd_q.wready),
       .s_axi_bid      (lcl_cl_sh_ddrd_q.bid),
       .s_axi_bresp    (lcl_cl_sh_ddrd_q.bresp),
       .s_axi_bvalid   (lcl_cl_sh_ddrd_q.bvalid),
       .s_axi_bready   (lcl_cl_sh_ddrd_q.bready),
       .s_axi_arid     (lcl_cl_sh_ddrd_q.arid),
       .s_axi_araddr   ({lcl_cl_sh_ddrd_q.araddr[63:36], 2'b0, lcl_cl_sh_ddrd_q.araddr[33:0]}),
       .s_axi_arlen    (lcl_cl_sh_ddrd_q.arlen),
       .s_axi_arsize   (lcl_cl_sh_ddrd_q.arsize),
       .s_axi_arburst  (2'b1),
       .s_axi_arlock   (1'b0),
       .s_axi_arcache  (4'b11),
       .s_axi_arprot   (3'b10),
       .s_axi_arregion (4'b0),
       .s_axi_arqos    (4'b0),
       .s_axi_arvalid  (lcl_cl_sh_ddrd_q.arvalid),
       .s_axi_arready  (lcl_cl_sh_ddrd_q.arready),
       .s_axi_rid      (lcl_cl_sh_ddrd_q.rid),
       .s_axi_rdata    (lcl_cl_sh_ddrd_q.rdata),
       .s_axi_rresp    (lcl_cl_sh_ddrd_q.rresp),
       .s_axi_rlast    (lcl_cl_sh_ddrd_q.rlast),
       .s_axi_rvalid   (lcl_cl_sh_ddrd_q.rvalid),
       .s_axi_rready   (lcl_cl_sh_ddrd_q.rready),
       .m_axi_awid     (lcl_cl_sh_ddrd_q2.awid),
       .m_axi_awaddr   (lcl_cl_sh_ddrd_q2.awaddr),
       .m_axi_awlen    (lcl_cl_sh_ddrd_q2.awlen),
       .m_axi_awsize   (lcl_cl_sh_ddrd_q2.awsize),
       .m_axi_awburst  (),
       .m_axi_awlock   (),
       .m_axi_awcache  (),
       .m_axi_awprot   (),
       .m_axi_awregion (),
       .m_axi_awqos    (),
       .m_axi_awvalid  (lcl_cl_sh_ddrd_q2.awvalid),
       .m_axi_awready  (lcl_cl_sh_ddrd_q2.awready),
       .m_axi_wdata    (lcl_cl_sh_ddrd_q2.wdata),
       .m_axi_wstrb    (lcl_cl_sh_ddrd_q2.wstrb),
       .m_axi_wlast    (lcl_cl_sh_ddrd_q2.wlast),
       .m_axi_wvalid   (lcl_cl_sh_ddrd_q2.wvalid),
       .m_axi_wready   (lcl_cl_sh_ddrd_q2.wready),
       .m_axi_bid      (lcl_cl_sh_ddrd_q2.bid),
       .m_axi_bresp    (lcl_cl_sh_ddrd_q2.bresp),
       .m_axi_bvalid   (lcl_cl_sh_ddrd_q2.bvalid),
       .m_axi_bready   (lcl_cl_sh_ddrd_q2.bready),
       .m_axi_arid     (lcl_cl_sh_ddrd_q2.arid),
       .m_axi_araddr   (lcl_cl_sh_ddrd_q2.araddr),
       .m_axi_arlen    (lcl_cl_sh_ddrd_q2.arlen),
       .m_axi_arsize   (lcl_cl_sh_ddrd_q2.arsize),
       .m_axi_arburst  (),
       .m_axi_arlock   (),
       .m_axi_arcache  (),
       .m_axi_arprot   (),
       .m_axi_arregion (),
       .m_axi_arqos    (),
       .m_axi_arvalid  (lcl_cl_sh_ddrd_q2.arvalid),
       .m_axi_arready  (lcl_cl_sh_ddrd_q2.arready),
       .m_axi_rid      (lcl_cl_sh_ddrd_q2.rid),
       .m_axi_rdata    (lcl_cl_sh_ddrd_q2.rdata),
       .m_axi_rresp    (lcl_cl_sh_ddrd_q2.rresp),
       .m_axi_rlast    (lcl_cl_sh_ddrd_q2.rlast),
       .m_axi_rvalid   (lcl_cl_sh_ddrd_q2.rvalid),
       .m_axi_rready   (lcl_cl_sh_ddrd_q2.rready)
       );
   dest_register_slice DDR_D_TST_AXI4_REG_SLC_2 (
       .aclk           (aclk),
       .aresetn        (slr0_sync_aresetn),
       .s_axi_awid     (lcl_cl_sh_ddrd_q2.awid),
       .s_axi_awaddr   (lcl_cl_sh_ddrd_q2.awaddr),
       .s_axi_awlen    (lcl_cl_sh_ddrd_q2.awlen),
       .s_axi_awsize   (lcl_cl_sh_ddrd_q2.awsize),
       .s_axi_awburst  (2'b1),
       .s_axi_awlock   (1'b0),
       .s_axi_awcache  (4'b11),
       .s_axi_awprot   (3'b10),
       .s_axi_awregion (4'b0),
       .s_axi_awqos    (4'b0),
       .s_axi_awvalid  (lcl_cl_sh_ddrd_q2.awvalid),
       .s_axi_awready  (lcl_cl_sh_ddrd_q2.awready),
       .s_axi_wdata    (lcl_cl_sh_ddrd_q2.wdata),
       .s_axi_wstrb    (lcl_cl_sh_ddrd_q2.wstrb),
       .s_axi_wlast    (lcl_cl_sh_ddrd_q2.wlast),
       .s_axi_wvalid   (lcl_cl_sh_ddrd_q2.wvalid),
       .s_axi_wready   (lcl_cl_sh_ddrd_q2.wready),
       .s_axi_bid      (lcl_cl_sh_ddrd_q2.bid),
       .s_axi_bresp    (lcl_cl_sh_ddrd_q2.bresp),
       .s_axi_bvalid   (lcl_cl_sh_ddrd_q2.bvalid),
       .s_axi_bready   (lcl_cl_sh_ddrd_q2.bready),
       .s_axi_arid     (lcl_cl_sh_ddrd_q2.arid),
       .s_axi_araddr   (lcl_cl_sh_ddrd_q2.araddr),
       .s_axi_arlen    (lcl_cl_sh_ddrd_q2.arlen),
       .s_axi_arsize   (lcl_cl_sh_ddrd_q2.arsize),
       .s_axi_arburst  (2'b1),
       .s_axi_arlock   (1'b0),
       .s_axi_arcache  (4'b11),
       .s_axi_arprot   (3'b10),
       .s_axi_arregion (4'b0),
       .s_axi_arqos    (4'b0),
       .s_axi_arvalid  (lcl_cl_sh_ddrd_q2.arvalid),
       .s_axi_arready  (lcl_cl_sh_ddrd_q2.arready),
       .s_axi_rid      (lcl_cl_sh_ddrd_q2.rid),
       .s_axi_rdata    (lcl_cl_sh_ddrd_q2.rdata),
       .s_axi_rresp    (lcl_cl_sh_ddrd_q2.rresp),
       .s_axi_rlast    (lcl_cl_sh_ddrd_q2.rlast),
       .s_axi_rvalid   (lcl_cl_sh_ddrd_q2.rvalid),
       .s_axi_rready   (lcl_cl_sh_ddrd_q2.rready),
       .m_axi_awid     (lcl_cl_sh_ddrd_q3.awid),
       .m_axi_awaddr   (lcl_cl_sh_ddrd_q3.awaddr),
       .m_axi_awlen    (lcl_cl_sh_ddrd_q3.awlen),
       .m_axi_awsize   (lcl_cl_sh_ddrd_q3.awsize),
       .m_axi_awburst  (),
       .m_axi_awlock   (),
       .m_axi_awcache  (),
       .m_axi_awprot   (),
       .m_axi_awregion (),
       .m_axi_awqos    (),
       .m_axi_awvalid  (lcl_cl_sh_ddrd_q3.awvalid),
       .m_axi_awready  (lcl_cl_sh_ddrd_q3.awready),
       .m_axi_wdata    (lcl_cl_sh_ddrd_q3.wdata),
       .m_axi_wstrb    (lcl_cl_sh_ddrd_q3.wstrb),
       .m_axi_wlast    (lcl_cl_sh_ddrd_q3.wlast),
       .m_axi_wvalid   (lcl_cl_sh_ddrd_q3.wvalid),
       .m_axi_wready   (lcl_cl_sh_ddrd_q3.wready),
       .m_axi_bid      (lcl_cl_sh_ddrd_q3.bid),
       .m_axi_bresp    (lcl_cl_sh_ddrd_q3.bresp),
       .m_axi_bvalid   (lcl_cl_sh_ddrd_q3.bvalid),
       .m_axi_bready   (lcl_cl_sh_ddrd_q3.bready),
       .m_axi_arid     (lcl_cl_sh_ddrd_q3.arid),
       .m_axi_araddr   (lcl_cl_sh_ddrd_q3.araddr),
       .m_axi_arlen    (lcl_cl_sh_ddrd_q3.arlen),
       .m_axi_arsize   (lcl_cl_sh_ddrd_q3.arsize),
       .m_axi_arburst  (),
       .m_axi_arlock   (),
       .m_axi_arcache  (),
       .m_axi_arprot   (),
       .m_axi_arregion (),
       .m_axi_arqos    (),
       .m_axi_arvalid  (lcl_cl_sh_ddrd_q3.arvalid),
       .m_axi_arready  (lcl_cl_sh_ddrd_q3.arready),
       .m_axi_rid      (lcl_cl_sh_ddrd_q3.rid),
       .m_axi_rdata    (lcl_cl_sh_ddrd_q3.rdata),
       .m_axi_rresp    (lcl_cl_sh_ddrd_q3.rresp),
       .m_axi_rlast    (lcl_cl_sh_ddrd_q3.rlast),
       .m_axi_rvalid   (lcl_cl_sh_ddrd_q3.rvalid),
       .m_axi_rready   (lcl_cl_sh_ddrd_q3.rready)
       );

//----------------------------
// ATG/scrubber for DDRD
//----------------------------
   lib_pipe #(.WIDTH(32+32+1+1), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_CFG_REQ_DDR_D (.clk (aclk),
                                                              .rst_n (aresetn),
                                                              .in_bus({ddrd_tst_cfg_bus.addr, ddrd_tst_cfg_bus.wdata, ddrd_tst_cfg_bus.wr, ddrd_tst_cfg_bus.rd}),
                                                              .out_bus({ddrd_tst_cfg_bus_q.addr, ddrd_tst_cfg_bus_q.wdata, ddrd_tst_cfg_bus_q.wr, ddrd_tst_cfg_bus_q.rd})
                                                              );

   lib_pipe #(.WIDTH(32+1), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_CFG_ACK_DDR_D (.clk (aclk),
                                                              .rst_n (aresetn),
                                                              .in_bus({ddrd_tst_cfg_bus_q.ack, ddrd_tst_cfg_bus_q.rdata}),
                                                              .out_bus({ddrd_tst_cfg_bus.ack, ddrd_tst_cfg_bus.rdata})
                                                              );


   lib_pipe #(.WIDTH(2+3+64), .STAGES(NUM_CFG_STGS_CL_DDR_ATG)) PIPE_SCRB_DDR_D (.clk(aclk),
                                                              .rst_n(aresetn),
                                                              .in_bus({ddrd_scrb_bus.enable, ddrd_scrb_bus_q.done, ddrd_scrb_bus_q.state, ddrd_scrb_bus_q.addr}),
                                                              .out_bus({ddrd_scrb_bus_q.enable, ddrd_scrb_bus.done, ddrd_scrb_bus.state, ddrd_scrb_bus.addr})
                                                              );

   cl_tst_scrb #(.DATA_WIDTH(512),
                    .SCRB_BURST_LEN_MINUS1(SCRB_BURST_LEN_MINUS1),
                    .SCRB_MAX_ADDR(SCRB_MAX_ADDR),
                    .NO_SCRB_INST(NO_SCRB_INST)) CL_TST_DDR_D (

         .clk(aclk),
         .rst_n(slr0_sync_aresetn),

         .cfg_addr(ddrd_tst_cfg_bus_q.addr),
         .cfg_wdata(ddrd_tst_cfg_bus_q.wdata),
         .cfg_wr(ddrd_tst_cfg_bus_q.wr),
         .cfg_rd(ddrd_tst_cfg_bus_q.rd),
         .tst_cfg_ack(ddrd_tst_cfg_bus_q.ack),
         .tst_cfg_rdata(ddrd_tst_cfg_bus_q.rdata),

         .slv_awid(lcl_cl_sh_ddrd_q3.awid[6:0]),
         .slv_awaddr(lcl_cl_sh_ddrd_q3.awaddr),
         .slv_awlen(lcl_cl_sh_ddrd_q3.awlen),
         .slv_awsize(lcl_cl_sh_ddrd_q3.awsize),
         .slv_awvalid(lcl_cl_sh_ddrd_q3.awvalid),
         .slv_awuser(11'b0),
         .slv_awready(lcl_cl_sh_ddrd_q3.awready),

         .slv_wid(7'b0),
         .slv_wdata(lcl_cl_sh_ddrd_q3.wdata),
         .slv_wstrb(lcl_cl_sh_ddrd_q3.wstrb),
         .slv_wlast(lcl_cl_sh_ddrd_q3.wlast),
         .slv_wvalid(lcl_cl_sh_ddrd_q3.wvalid),
         .slv_wready(lcl_cl_sh_ddrd_q3.wready),

         .slv_bid(lcl_cl_sh_ddrd_q3.bid[6:0]),
         .slv_bresp(lcl_cl_sh_ddrd_q3.bresp),
         .slv_buser(),
         .slv_bvalid(lcl_cl_sh_ddrd_q3.bvalid),
         .slv_bready(lcl_cl_sh_ddrd_q3.bready),

         .slv_arid(lcl_cl_sh_ddrd_q3.arid[6:0]),
         .slv_araddr(lcl_cl_sh_ddrd_q3.araddr),
         .slv_arlen(lcl_cl_sh_ddrd_q3.arlen),
         .slv_arsize(lcl_cl_sh_ddrd_q3.arsize),
         .slv_arvalid(lcl_cl_sh_ddrd_q3.arvalid),
         .slv_aruser(11'b0),
         .slv_arready(lcl_cl_sh_ddrd_q3.arready),

         .slv_rid(lcl_cl_sh_ddrd_q3.rid[6:0]),
         .slv_rdata(lcl_cl_sh_ddrd_q3.rdata),
         .slv_rresp(lcl_cl_sh_ddrd_q3.rresp),
         .slv_rlast(lcl_cl_sh_ddrd_q3.rlast),
         .slv_ruser(),
         .slv_rvalid(lcl_cl_sh_ddrd_q3.rvalid),
         .slv_rready(lcl_cl_sh_ddrd_q3.rready),


         .awid(lcl_cl_sh_ddrd.awid[8:0]),
         .awaddr(lcl_cl_sh_ddrd.awaddr),
         .awlen(lcl_cl_sh_ddrd.awlen),
         .awvalid(lcl_cl_sh_ddrd.awvalid),
         .awsize(lcl_cl_sh_ddrd.awsize),
         .awuser(),
         .awready(lcl_cl_sh_ddrd.awready),

         .wid(lcl_cl_sh_ddrd.wid[8:0]),
         .wdata(lcl_cl_sh_ddrd.wdata),
         .wstrb(lcl_cl_sh_ddrd.wstrb),
         .wlast(lcl_cl_sh_ddrd.wlast),
         .wvalid(lcl_cl_sh_ddrd.wvalid),
         .wready(lcl_cl_sh_ddrd.wready),

         .bid(lcl_cl_sh_ddrd.bid[8:0]),
         .bresp(lcl_cl_sh_ddrd.bresp),
         .buser(18'h0),
         .bvalid(lcl_cl_sh_ddrd.bvalid),
         .bready(lcl_cl_sh_ddrd.bready),

         .arid(lcl_cl_sh_ddrd.arid[8:0]),
         .araddr(lcl_cl_sh_ddrd.araddr),
         .arlen(lcl_cl_sh_ddrd.arlen),
         .arsize(lcl_cl_sh_ddrd.arsize),
         .arvalid(lcl_cl_sh_ddrd.arvalid),
         .aruser(),
         .arready(lcl_cl_sh_ddrd.arready),

         .rid(lcl_cl_sh_ddrd.rid[8:0]),
         .rdata(lcl_cl_sh_ddrd.rdata),
         .rresp(lcl_cl_sh_ddrd.rresp),
         .rlast(lcl_cl_sh_ddrd.rlast),
         .ruser(18'h0),
         .rvalid(lcl_cl_sh_ddrd.rvalid),
         .rready(lcl_cl_sh_ddrd.rready),

         .scrb_enable(ddrd_scrb_bus_q.enable),
         .scrb_done  (ddrd_scrb_bus_q.done),

         .scrb_dbg_state(ddrd_scrb_bus_q.state),
         .scrb_dbg_addr (ddrd_scrb_bus_q.addr)
      );
      assign lcl_cl_sh_ddrd.awid[15:9] = 7'b0;
      assign lcl_cl_sh_ddrd.wid[15:9] = 7'b0;
      assign lcl_cl_sh_ddrd.arid[15:9] = 7'b0;


endmodule

