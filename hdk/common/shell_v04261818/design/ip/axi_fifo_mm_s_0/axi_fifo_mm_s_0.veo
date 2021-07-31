// (c) Copyright 1995-2021 Xilinx, Inc. All rights reserved.
// 
// This file contains confidential and proprietary information
// of Xilinx, Inc. and is protected under U.S. and
// international copyright and other intellectual property
// laws.
// 
// DISCLAIMER
// This disclaimer is not a license and does not grant any
// rights to the materials distributed herewith. Except as
// otherwise provided in a valid license issued to you by
// Xilinx, and to the maximum extent permitted by applicable
// law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
// WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
// AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
// BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
// INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
// (2) Xilinx shall not be liable (whether in contract or tort,
// including negligence, or under any other theory of
// liability) for any loss or damage of any kind or nature
// related to, arising under or in connection with these
// materials, including for any direct, or any indirect,
// special, incidental, or consequential loss or damage
// (including loss of data, profits, goodwill, or any type of
// loss or damage suffered as a result of any action brought
// by a third party) even if such damage or loss was
// reasonably foreseeable or Xilinx had been advised of the
// possibility of the same.
// 
// CRITICAL APPLICATIONS
// Xilinx products are not designed or intended to be fail-
// safe, or for use in any application requiring fail-safe
// performance, such as life-support or safety devices or
// systems, Class III medical devices, nuclear facilities,
// applications related to the deployment of airbags, or any
// other applications that could lead to death, personal
// injury, or severe property or environmental damage
// (individually and collectively, "Critical
// Applications"). Customer assumes the sole risk and
// liability of any use of Xilinx products in Critical
// Applications, subject only to applicable laws and
// regulations governing limitations on product liability.
// 
// THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
// PART OF THIS FILE AT ALL TIMES.
// 
// DO NOT MODIFY THIS FILE.

// IP VLNV: xilinx.com:ip:axi_fifo_mm_s:4.2
// IP Revision: 3

// The following must be inserted into your Verilog file for this
// core to be instantiated. Change the instance name and port connections
// (in parentheses) to your own signal names.

//----------- Begin Cut here for INSTANTIATION Template ---// INST_TAG
axi_fifo_mm_s_0 your_instance_name (
  .interrupt(interrupt),                            // output wire interrupt
  .s_axi_aclk(s_axi_aclk),                          // input wire s_axi_aclk
  .s_axi_aresetn(s_axi_aresetn),                    // input wire s_axi_aresetn
  .s_axi_awaddr(s_axi_awaddr),                      // input wire [31 : 0] s_axi_awaddr
  .s_axi_awvalid(s_axi_awvalid),                    // input wire s_axi_awvalid
  .s_axi_awready(s_axi_awready),                    // output wire s_axi_awready
  .s_axi_wdata(s_axi_wdata),                        // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(s_axi_wstrb),                        // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(s_axi_wvalid),                      // input wire s_axi_wvalid
  .s_axi_wready(s_axi_wready),                      // output wire s_axi_wready
  .s_axi_bresp(s_axi_bresp),                        // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(s_axi_bvalid),                      // output wire s_axi_bvalid
  .s_axi_bready(s_axi_bready),                      // input wire s_axi_bready
  .s_axi_araddr(s_axi_araddr),                      // input wire [31 : 0] s_axi_araddr
  .s_axi_arvalid(s_axi_arvalid),                    // input wire s_axi_arvalid
  .s_axi_arready(s_axi_arready),                    // output wire s_axi_arready
  .s_axi_rdata(s_axi_rdata),                        // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(s_axi_rresp),                        // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(s_axi_rvalid),                      // output wire s_axi_rvalid
  .s_axi_rready(s_axi_rready),                      // input wire s_axi_rready
  .s_axi4_awid(s_axi4_awid),                        // input wire [15 : 0] s_axi4_awid
  .s_axi4_awaddr(s_axi4_awaddr),                    // input wire [31 : 0] s_axi4_awaddr
  .s_axi4_awlen(s_axi4_awlen),                      // input wire [7 : 0] s_axi4_awlen
  .s_axi4_awsize(s_axi4_awsize),                    // input wire [2 : 0] s_axi4_awsize
  .s_axi4_awburst(s_axi4_awburst),                  // input wire [1 : 0] s_axi4_awburst
  .s_axi4_awlock(s_axi4_awlock),                    // input wire s_axi4_awlock
  .s_axi4_awcache(s_axi4_awcache),                  // input wire [3 : 0] s_axi4_awcache
  .s_axi4_awprot(s_axi4_awprot),                    // input wire [2 : 0] s_axi4_awprot
  .s_axi4_awvalid(s_axi4_awvalid),                  // input wire s_axi4_awvalid
  .s_axi4_awready(s_axi4_awready),                  // output wire s_axi4_awready
  .s_axi4_wdata(s_axi4_wdata),                      // input wire [511 : 0] s_axi4_wdata
  .s_axi4_wstrb(s_axi4_wstrb),                      // input wire [63 : 0] s_axi4_wstrb
  .s_axi4_wlast(s_axi4_wlast),                      // input wire s_axi4_wlast
  .s_axi4_wvalid(s_axi4_wvalid),                    // input wire s_axi4_wvalid
  .s_axi4_wready(s_axi4_wready),                    // output wire s_axi4_wready
  .s_axi4_bid(s_axi4_bid),                          // output wire [15 : 0] s_axi4_bid
  .s_axi4_bresp(s_axi4_bresp),                      // output wire [1 : 0] s_axi4_bresp
  .s_axi4_bvalid(s_axi4_bvalid),                    // output wire s_axi4_bvalid
  .s_axi4_bready(s_axi4_bready),                    // input wire s_axi4_bready
  .s_axi4_arid(s_axi4_arid),                        // input wire [15 : 0] s_axi4_arid
  .s_axi4_araddr(s_axi4_araddr),                    // input wire [31 : 0] s_axi4_araddr
  .s_axi4_arlen(s_axi4_arlen),                      // input wire [7 : 0] s_axi4_arlen
  .s_axi4_arsize(s_axi4_arsize),                    // input wire [2 : 0] s_axi4_arsize
  .s_axi4_arburst(s_axi4_arburst),                  // input wire [1 : 0] s_axi4_arburst
  .s_axi4_arlock(s_axi4_arlock),                    // input wire s_axi4_arlock
  .s_axi4_arcache(s_axi4_arcache),                  // input wire [3 : 0] s_axi4_arcache
  .s_axi4_arprot(s_axi4_arprot),                    // input wire [2 : 0] s_axi4_arprot
  .s_axi4_arvalid(s_axi4_arvalid),                  // input wire s_axi4_arvalid
  .s_axi4_arready(s_axi4_arready),                  // output wire s_axi4_arready
  .s_axi4_rid(s_axi4_rid),                          // output wire [15 : 0] s_axi4_rid
  .s_axi4_rdata(s_axi4_rdata),                      // output wire [511 : 0] s_axi4_rdata
  .s_axi4_rresp(s_axi4_rresp),                      // output wire [1 : 0] s_axi4_rresp
  .s_axi4_rlast(s_axi4_rlast),                      // output wire s_axi4_rlast
  .s_axi4_rvalid(s_axi4_rvalid),                    // output wire s_axi4_rvalid
  .s_axi4_rready(s_axi4_rready),                    // input wire s_axi4_rready
  .mm2s_prmry_reset_out_n(mm2s_prmry_reset_out_n),  // output wire mm2s_prmry_reset_out_n
  .axi_str_txd_tvalid(axi_str_txd_tvalid),          // output wire axi_str_txd_tvalid
  .axi_str_txd_tready(axi_str_txd_tready),          // input wire axi_str_txd_tready
  .axi_str_txd_tlast(axi_str_txd_tlast),            // output wire axi_str_txd_tlast
  .axi_str_txd_tdata(axi_str_txd_tdata),            // output wire [511 : 0] axi_str_txd_tdata
  .s2mm_prmry_reset_out_n(s2mm_prmry_reset_out_n),  // output wire s2mm_prmry_reset_out_n
  .axi_str_rxd_tvalid(axi_str_rxd_tvalid),          // input wire axi_str_rxd_tvalid
  .axi_str_rxd_tready(axi_str_rxd_tready),          // output wire axi_str_rxd_tready
  .axi_str_rxd_tlast(axi_str_rxd_tlast),            // input wire axi_str_rxd_tlast
  .axi_str_rxd_tdata(axi_str_rxd_tdata)            // input wire [511 : 0] axi_str_rxd_tdata
);
// INST_TAG_END ------ End INSTANTIATION Template ---------

// You must compile the wrapper file axi_fifo_mm_s_0.v when simulating
// the core, axi_fifo_mm_s_0. When compiling the wrapper file, be sure to
// reference the Verilog simulation library.

