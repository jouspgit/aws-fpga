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

// -----------------------------------------------------------------------------
// This module is an example of how to master transactions on a master port
// of the PCIS AXI Interconnect. The module issues a write command (Write
// Address, Write Data, and Write Response) followed by a read command (Read
// Address, and Read Data) to the same address.
// -----------------------------------------------------------------------------

module cl_dram_dma_axi_mstr (

    input            aclk,
    input            aresetn,
    axi_bus_t.slave  cl_axi_mstr_bus,  // AXI Master Bus towards interconnect

    axi_bus_t.master axi_mstr_dma_cfg_bus,
    axi_bus_t.master axi_mstr_jpeg_cfg_bus,

    cfg_bus_t.master axi_mstr_cfg_bus  // Config Bus for Register Access
);

 `include "cl_dram_dma_defines.vh"

/* START OF PREVIOUS CODE

// -----------------------------------------------------------------------------
// Parameters
// -----------------------------------------------------------------------------

   // State Machine States
   typedef enum logic [2:0] {
      AXI_MSTR_SM_IDLE     = 3'd0,
      AXI_MSTR_SM_WR       = 3'd1,
      AXI_MSTR_SM_WR_DATA  = 3'd2,
      AXI_MSTR_SM_WR_RESP  = 3'd3,
      AXI_MSTR_SM_RD       = 3'd4,
      AXI_MSTR_SM_RD_DATA  = 3'd5
                             } axi_mstr_sm_states;

// -----------------------------------------------------------------------------
// Internal signals
// -----------------------------------------------------------------------------

   // Command Registers
   logic        cmd_done_ns;
   logic [31:0] cmd_rd_data_ns;

   logic        cmd_go_q;
   logic        cmd_done_q;
   logic        cmd_rd_wrb_q;
   logic [31:0] cmd_addr_hi_q;
   logic [31:0] cmd_addr_lo_q;
   logic [31:0] cmd_rd_data_q;
   logic [31:0] cmd_wr_data_q;

   // AXI Master State Machine
   axi_mstr_sm_states axi_mstr_sm_ns;
   axi_mstr_sm_states axi_mstr_sm_q;

   logic axi_mstr_sm_idle;
   logic axi_mstr_sm_wr;
   logic axi_mstr_sm_wr_data;
   logic axi_mstr_sm_wr_resp;
   logic axi_mstr_sm_rd;
   logic axi_mstr_sm_rd_data;

   logic cfg_wr_stretch;
   logic cfg_rd_stretch;

   logic [ 7:0] cfg_addr_q  = 0; // Only care about lower 8-bits of address. Upper bits are decoded somewhere else.
   logic [31:0] cfg_wdata_q = 0;

// -----------------------------------------------------------------------------
// Register Access
// -----------------------------------------------------------------------------

   always @(posedge aclk)
      if (!aresetn)
      begin
         cfg_wr_stretch <= 0;
         cfg_rd_stretch <= 0;
      end
      else
      begin
         cfg_wr_stretch <= axi_mstr_cfg_bus.wr || (cfg_wr_stretch && !axi_mstr_cfg_bus.ack);
         cfg_rd_stretch <= axi_mstr_cfg_bus.rd || (cfg_rd_stretch && !axi_mstr_cfg_bus.ack);
         if (axi_mstr_cfg_bus.wr||axi_mstr_cfg_bus.rd)
         begin
            cfg_addr_q  <= axi_mstr_cfg_bus.addr[7:0];
            cfg_wdata_q <= axi_mstr_cfg_bus.wdata[31:0];
         end
      end

   //Readback mux
   always @(posedge aclk)
   begin
         case (cfg_addr_q)
            8'h00:      axi_mstr_cfg_bus.rdata[31:0] <= {29'b0, cmd_rd_wrb_q, cmd_done_q, cmd_go_q};
            8'h04:      axi_mstr_cfg_bus.rdata[31:0] <= cmd_addr_hi_q[31:0];
            8'h08:      axi_mstr_cfg_bus.rdata[31:0] <= cmd_addr_lo_q[31:0];
            8'h0C:      axi_mstr_cfg_bus.rdata[31:0] <= cmd_wr_data_q[31:0];
            8'h10:      axi_mstr_cfg_bus.rdata[31:0] <= cmd_rd_data_q[31:0];
            default:    axi_mstr_cfg_bus.rdata[31:0] <= 32'hffffffff;
         endcase
   end

   //Ack for cycle
   always_ff @(posedge aclk)
      if (!aresetn)
         axi_mstr_cfg_bus.ack <= 0;
      else
         axi_mstr_cfg_bus.ack <= ((cfg_wr_stretch||cfg_rd_stretch) && !axi_mstr_cfg_bus.ack);

// -----------------------------------------------------------------------------
// AXI Master Command Registers
// -----------------------------------------------------------------------------
// Offset     Register
// -------    --------------------
// 0x00       Command Control Register (CCR)
//             31:3 - Reserved
//                2 - Read/Write_B
//                1 - Done
//                0 - Go
// 0x04       Command Address High Register (CAHR)
//             31:0 - Address
// 0x08       Command Address Low Register (CALR)
//             31:0 - Address
// 0x0C       Command Write Data Register (CWDR)
//             31:0 - Write Data
// 0x10       Command Read Data Register (CRDR)
//             31:3 - Read Data

   // ----------------------
   // Command Go
   // ----------------------

   always_ff @(posedge aclk)
      if (!aresetn) begin
         cmd_go_q <= 1'b0;
      end
      else if (cfg_wr_stretch & ~axi_mstr_cfg_bus.ack & (cfg_addr_q == `CL_DRAM_DMA_AXI_MSTR_CCR_ADDR)) begin
         cmd_go_q <= cfg_wdata_q[0];
      end
      else begin
         cmd_go_q <= cmd_go_q & ~axi_mstr_sm_idle;
      end


   // ----------------------
   // Command Done
   // ----------------------

   assign cmd_done_ns = cmd_done_q | (axi_mstr_sm_rd_data & cl_axi_mstr_bus.rvalid) |
                                     (axi_mstr_sm_wr_resp & cl_axi_mstr_bus.bvalid) ;

   always_ff @(posedge aclk)
      if (!aresetn) begin
         cmd_done_q <= 1'b0;
      end
      else if (cfg_wr_stretch & ~axi_mstr_cfg_bus.ack & (cfg_addr_q == `CL_DRAM_DMA_AXI_MSTR_CCR_ADDR)) begin
         cmd_done_q <= cfg_wdata_q[1];
      end
      else begin
         cmd_done_q <= cmd_done_ns;
      end


   // ----------------------
   // Command Rd/Wr_B
   // ----------------------

   always_ff @(posedge aclk)
      if (!aresetn) begin
         cmd_rd_wrb_q <= 1'b0;
      end
      else if (cfg_wr_stretch & ~axi_mstr_cfg_bus.ack & (cfg_addr_q == `CL_DRAM_DMA_AXI_MSTR_CCR_ADDR)) begin
         cmd_rd_wrb_q <= cfg_wdata_q[2];
      end
      else begin
         cmd_rd_wrb_q <= cmd_rd_wrb_q;
      end


   // ----------------------
   // Command Address - High
   // ----------------------

   always_ff @(posedge aclk)
      if (!aresetn) begin
         cmd_addr_hi_q[31:0] <= 32'h0000_0000;
      end
      else if (cfg_wr_stretch & ~axi_mstr_cfg_bus.ack & (cfg_addr_q == `CL_DRAM_DMA_AXI_MSTR_CAHR_ADDR)) begin
         cmd_addr_hi_q[31:0] <= cfg_wdata_q[31:0];
      end
      else begin
         cmd_addr_hi_q[31:0] <= cmd_addr_hi_q[31:0];
      end

   // ----------------------
   // Command Address - Low
   // ----------------------

   always_ff @(posedge aclk)
      if (!aresetn) begin
         cmd_addr_lo_q[31:0] <= 32'h0000_0000;
      end
      else if (cfg_wr_stretch & ~axi_mstr_cfg_bus.ack & (cfg_addr_q == `CL_DRAM_DMA_AXI_MSTR_CALR_ADDR)) begin
         cmd_addr_lo_q[31:0] <= cfg_wdata_q[31:0];
      end
      else begin
         cmd_addr_lo_q[31:0] <= cmd_addr_lo_q[31:0];
      end

   // ----------------------
   // Command Write Data
   // ----------------------

   always_ff @(posedge aclk)
      if (!aresetn) begin
         cmd_wr_data_q[31:0] <= 32'h0000_0000;
      end
      else if (cfg_wr_stretch & ~axi_mstr_cfg_bus.ack & (cfg_addr_q == `CL_DRAM_DMA_AXI_MSTR_CWDR_ADDR)) begin
         cmd_wr_data_q <= cfg_wdata_q[31:0];
      end
      else begin
         cmd_wr_data_q[31:0] <= cmd_wr_data_q[31:0];
      end

   // ----------------------
   // Command Read Data
   // ----------------------

   assign cmd_rd_data_ns[31:0] =
         (axi_mstr_sm_rd_data & cl_axi_mstr_bus.rvalid) ? (cl_axi_mstr_bus.rdata[511:0] >> (8 * cmd_addr_lo_q[5:0])) :
                                                          cmd_rd_data_q[31:0]         ;

   always_ff @(posedge aclk)
      if (!aresetn) begin
         cmd_rd_data_q[31:0] <= 32'h0000_0000;
      end
      else if (cfg_wr_stretch & ~axi_mstr_cfg_bus.ack & (cfg_addr_q == `CL_DRAM_DMA_AXI_MSTR_CRDR_ADDR)) begin
         cmd_rd_data_q <= cfg_wdata_q[31:0];
      end
      else begin
         cmd_rd_data_q[31:0] <= cmd_rd_data_ns[31:0];
      end

// -----------------------------------------------------------------------------
// AXI Master State Machine
// -----------------------------------------------------------------------------

   // States
   // ----------------------------
   // 0. Idle           - Waiting for command
   // 1. Write          - Sending write address request (awvalid)
   // 2. Write Data     - Sending write data (wvalid)
   // 3. Write Response - Waiting for write response (bvalid)
   // 4. Read           - Sending read address request (arvalid)
   // 5. Read Data      - Waiting for read data (rvalid)

   always_comb begin
     // Default
     axi_mstr_sm_ns[2:0]  = AXI_MSTR_SM_IDLE;

     case (axi_mstr_sm_q[2:0])

       AXI_MSTR_SM_IDLE: begin
         if (cmd_go_q & ~cmd_done_q)
           if (cmd_rd_wrb_q) axi_mstr_sm_ns[2:0] = AXI_MSTR_SM_RD;
           else              axi_mstr_sm_ns[2:0] = AXI_MSTR_SM_WR;
         else                axi_mstr_sm_ns[2:0] = AXI_MSTR_SM_IDLE;
       end

       AXI_MSTR_SM_WR: begin
         if (cl_axi_mstr_bus.awready) axi_mstr_sm_ns[2:0] = AXI_MSTR_SM_WR_DATA;
         else                         axi_mstr_sm_ns[2:0] = AXI_MSTR_SM_WR;
       end

       AXI_MSTR_SM_WR_DATA: begin
         if (cl_axi_mstr_bus.wready) axi_mstr_sm_ns[2:0]  = AXI_MSTR_SM_WR_RESP;
         else                        axi_mstr_sm_ns[2:0]  = AXI_MSTR_SM_WR_DATA;
       end

       AXI_MSTR_SM_WR_RESP: begin
         if (cl_axi_mstr_bus.bvalid)  axi_mstr_sm_ns[2:0] = AXI_MSTR_SM_IDLE;
         else                         axi_mstr_sm_ns[2:0] = AXI_MSTR_SM_WR_RESP;
       end

       AXI_MSTR_SM_RD: begin
         if (cl_axi_mstr_bus.arready) axi_mstr_sm_ns[2:0] = AXI_MSTR_SM_RD_DATA;
         else                         axi_mstr_sm_ns[2:0] = AXI_MSTR_SM_RD;
       end

       AXI_MSTR_SM_RD_DATA: begin
         if (cl_axi_mstr_bus.rvalid)  axi_mstr_sm_ns[2:0] = AXI_MSTR_SM_IDLE;
         else                         axi_mstr_sm_ns[2:0] = AXI_MSTR_SM_RD_DATA;
       end

       default: axi_mstr_sm_ns[2:0]  = AXI_MSTR_SM_IDLE;

     endcase
   end

   // AXI Master SM Flop
   always_ff @(posedge aclk)
      if (!aresetn) begin
         axi_mstr_sm_q[2:0] <= 3'h0;
      end
      else begin
         axi_mstr_sm_q[2:0] <= axi_mstr_sm_ns[2:0];
      end

   // State nets
   assign axi_mstr_sm_idle     = (axi_mstr_sm_q[2:0] == AXI_MSTR_SM_IDLE);
   assign axi_mstr_sm_wr       = (axi_mstr_sm_q[2:0] == AXI_MSTR_SM_WR);
   assign axi_mstr_sm_wr_data  = (axi_mstr_sm_q[2:0] == AXI_MSTR_SM_WR_DATA);
   assign axi_mstr_sm_wr_resp  = (axi_mstr_sm_q[2:0] == AXI_MSTR_SM_WR_RESP);
   assign axi_mstr_sm_rd       = (axi_mstr_sm_q[2:0] == AXI_MSTR_SM_RD);
   assign axi_mstr_sm_rd_data  = (axi_mstr_sm_q[2:0] == AXI_MSTR_SM_RD_DATA);

// -----------------------------------------------------------------------------
// AXI Bus Connections
// -----------------------------------------------------------------------------

   // Write Address
   assign cl_axi_mstr_bus.awid[15:0]   = 16'b0;                     // Only 1 outstanding command
   assign cl_axi_mstr_bus.awaddr[63:0] = {cmd_addr_hi_q[31:0], cmd_addr_lo_q[31:0]};
   assign cl_axi_mstr_bus.awlen[7:0]   = 8'h00;                     // Always 1 burst
   assign cl_axi_mstr_bus.awsize[2:0]  = 3'b010;                    // Always 4 bytes
   assign cl_axi_mstr_bus.awvalid      = axi_mstr_sm_wr;

   // Write Data
   assign cl_axi_mstr_bus.wid[15:0]    = 16'b0;                        // Only 1 outstanding command
   assign cl_axi_mstr_bus.wdata[511:0] = {480'b0, cmd_wr_data_q[31:0]} << (8 * cmd_addr_lo_q[5:0]);
   assign cl_axi_mstr_bus.wstrb[63:0]  = 64'h0000_0000_0000_000F << cmd_addr_lo_q[5:0];      // Always 4 bytes

   assign cl_axi_mstr_bus.wlast        = 1'b1;                         // Always 1 burst
   assign cl_axi_mstr_bus.wvalid       = axi_mstr_sm_wr_data;

   // Write Response
   assign cl_axi_mstr_bus.bready       = axi_mstr_sm_wr_resp;

   // Read Address
   assign cl_axi_mstr_bus.arid[15:0]   = 16'b0;                     // Only 1 outstanding command
   assign cl_axi_mstr_bus.araddr[63:0] = {cmd_addr_hi_q[31:0], cmd_addr_lo_q[31:0]};
   assign cl_axi_mstr_bus.arlen[7:0]   = 8'h00;                     // Always 1 burst
   assign cl_axi_mstr_bus.arsize[2:0]  = 3'b010;                    // Always 4 bytes
   assign cl_axi_mstr_bus.arvalid      = axi_mstr_sm_rd;

   // Read Data
   assign cl_axi_mstr_bus.rready       = axi_mstr_sm_rd_data;


   END OF PREVIOUS CODE */ 

   // wires for the dma. at some point we will replace them by axi_bus_t ports surely
  

   // kept for now
  wire [1 : 0] m_axi_mm2s_arburst;
  wire [2 : 0] m_axi_mm2s_arprot;
  wire [3 : 0] m_axi_mm2s_arcache;

   //kept for now
  wire [1 : 0] m_axi_s2mm_awburst;
  wire [2 : 0] m_axi_s2mm_awprot;
  wire [3 : 0] m_axi_s2mm_awcache;



  wire mm2s_prmry_reset_out_n;
  wire [31 : 0] m_axis_mm2s_tdata;
  wire [3 : 0] m_axis_mm2s_tkeep;
  wire m_axis_mm2s_tvalid;
  wire m_axis_mm2s_tready;
  wire m_axis_mm2s_tlast;

  wire s2mm_prmry_reset_out_n;
  wire [31 : 0] s_axis_s2mm_tdata;
  wire [3 : 0] s_axis_s2mm_tkeep;
  wire s_axis_s2mm_tvalid;
  wire s_axis_s2mm_tready;
  wire s_axis_s2mm_tlast;

 
  

  wire mm2s_introut;
  wire s2mm_introut;
  wire [31 : 0] axi_dma_tstvec;

  // temporary, to replace with actual jpeg-xs module.
  assign axi_mstr_jpeg_cfg_bus.awready = 1'b0;
  assign axi_mstr_jpeg_cfg_bus.wready  = 1'b0;
  assign axi_mstr_jpeg_cfg_bus.bresp   = 2'b0;
  assign axi_mstr_jpeg_cfg_bus.bvalid  = 1'b0; 
  assign axi_mstr_jpeg_cfg_bus.arready = 1'b0; 
  assign axi_mstr_jpeg_cfg_bus.rvalid  = 1'b0;
  assign axi_mstr_jpeg_cfg_bus.rresp   = 2'b0;
  assign axi_mstr_jpeg_cfg_bus.rdata   = 0;
 
 // temporary loopback connection with byteswap

  assign s_axis_s2mm_tdata  =	{<<byte{m_axis_mm2s_tdata}};  // << for swap, >> for nothing
  assign s_axis_s2mm_tkeep  =	m_axis_mm2s_tkeep;       
  assign s_axis_s2mm_tvalid =	m_axis_mm2s_tvalid;      
  assign m_axis_mm2s_tready =	s_axis_s2mm_tready;    
  assign s_axis_s2mm_tlast  =	m_axis_mm2s_tlast;


  axi_dma_0 JPEG_DMA (
  .s_axi_lite_aclk(aclk),                // input wire s_axi_lite_aclk
  .m_axi_mm2s_aclk(aclk),                // input wire m_axi_mm2s_aclk
  .m_axi_s2mm_aclk(aclk),                // input wire m_axi_s2mm_aclk
  .axi_resetn(aresetn),                          // input wire axi_resetn

  // AXI-L Register access
  .s_axi_lite_awvalid(axi_mstr_dma_cfg_bus.awvalid),          // input wire s_axi_lite_awvalid
  .s_axi_lite_awready(axi_mstr_dma_cfg_bus.awready),          // output wire s_axi_lite_awready
  .s_axi_lite_awaddr(axi_mstr_dma_cfg_bus.awaddr[9:0]),            // input wire [9 : 0] s_axi_lite_awaddr
  .s_axi_lite_wvalid(axi_mstr_dma_cfg_bus.wvalid),            // input wire s_axi_lite_wvalid
  .s_axi_lite_wready(axi_mstr_dma_cfg_bus.wready),            // output wire s_axi_lite_wready
  .s_axi_lite_wdata(axi_mstr_dma_cfg_bus.wdata[31:0]),              // input wire [31 : 0] s_axi_lite_wdata
  .s_axi_lite_bresp(axi_mstr_dma_cfg_bus.bresp),              // output wire [1 : 0] s_axi_lite_bresp
  .s_axi_lite_bvalid(axi_mstr_dma_cfg_bus.bvalid),            // output wire s_axi_lite_bvalid
  .s_axi_lite_bready(axi_mstr_dma_cfg_bus.bready),            // input wire s_axi_lite_bready
  .s_axi_lite_arvalid(axi_mstr_dma_cfg_bus.arvalid),          // input wire s_axi_lite_arvalid
  .s_axi_lite_arready(axi_mstr_dma_cfg_bus.arready),          // output wire s_axi_lite_arready
  .s_axi_lite_araddr(axi_mstr_dma_cfg_bus.araddr[9:0]),            // input wire [9 : 0] s_axi_lite_araddr
  .s_axi_lite_rvalid(axi_mstr_dma_cfg_bus.rvalid),            // output wire s_axi_lite_rvalid
  .s_axi_lite_rready(axi_mstr_dma_cfg_bus.rready),            // input wire s_axi_lite_rready
  .s_axi_lite_rdata(axi_mstr_dma_cfg_bus.rdata[31:0]),              // output wire [31 : 0] s_axi_lite_rdata
  .s_axi_lite_rresp(axi_mstr_dma_cfg_bus.rresp),              // output wire [1 : 0] s_axi_lite_rresp

  // AXI4 Read, makes ar output requests to DDR and receives read data
  .m_axi_mm2s_araddr(cl_axi_mstr_bus.araddr),            // output wire [63 : 0] m_axi_mm2s_araddr
  .m_axi_mm2s_arlen(cl_axi_mstr_bus.arlen),              // output wire [7 : 0] m_axi_mm2s_arlen
  .m_axi_mm2s_arsize(cl_axi_mstr_bus.arsize),            // output wire [2 : 0] m_axi_mm2s_arsize
  .m_axi_mm2s_arburst(m_axi_mm2s_arburst),          // output wire [1 : 0] m_axi_mm2s_arburst
  .m_axi_mm2s_arprot(m_axi_mm2s_arprot),            // output wire [2 : 0] m_axi_mm2s_arprot
  .m_axi_mm2s_arcache(m_axi_mm2s_arcache),          // output wire [3 : 0] m_axi_mm2s_arcache
  .m_axi_mm2s_arvalid(cl_axi_mstr_bus.arvalid),          // output wire m_axi_mm2s_arvalid
  .m_axi_mm2s_arready(cl_axi_mstr_bus.arready),          // input wire m_axi_mm2s_arready
  .m_axi_mm2s_rdata(cl_axi_mstr_bus.rdata),              // input wire [511 : 0] m_axi_mm2s_rdata
  .m_axi_mm2s_rresp(cl_axi_mstr_bus.rresp),              // input wire [1 : 0] m_axi_mm2s_rresp
  .m_axi_mm2s_rlast(cl_axi_mstr_bus.rlast),              // input wire m_axi_mm2s_rlast
  .m_axi_mm2s_rvalid(cl_axi_mstr_bus.rvalid),            // input wire m_axi_mm2s_rvalid
  .m_axi_mm2s_rready(cl_axi_mstr_bus.rready),            // output wire m_axi_mm2s_rready

  // Master Stream interface from read data, towards data modif module
  .mm2s_prmry_reset_out_n(mm2s_prmry_reset_out_n),  // output wire mm2s_prmry_reset_out_n
  .m_axis_mm2s_tdata(m_axis_mm2s_tdata),            // output wire [31 : 0] m_axis_mm2s_tdata
  .m_axis_mm2s_tkeep(m_axis_mm2s_tkeep),            // output wire [3 : 0] m_axis_mm2s_tkeep
  .m_axis_mm2s_tvalid(m_axis_mm2s_tvalid),          // output wire m_axis_mm2s_tvalid
  .m_axis_mm2s_tready(m_axis_mm2s_tready),          // input wire m_axis_mm2s_tready
  .m_axis_mm2s_tlast(m_axis_mm2s_tlast),            // output wire m_axis_mm2s_tlast


  // Slave Stream interface from data modif module, turned into write to DDR. 
  .s2mm_prmry_reset_out_n(s2mm_prmry_reset_out_n),  // output wire s2mm_prmry_reset_out_n
  .s_axis_s2mm_tdata(s_axis_s2mm_tdata),            // input wire [31 : 0] s_axis_s2mm_tdata
  .s_axis_s2mm_tkeep(s_axis_s2mm_tkeep),            // input wire [3 : 0] s_axis_s2mm_tkeep
  .s_axis_s2mm_tvalid(s_axis_s2mm_tvalid),          // input wire s_axis_s2mm_tvalid
  .s_axis_s2mm_tready(s_axis_s2mm_tready),          // output wire s_axis_s2mm_tready
  .s_axis_s2mm_tlast(s_axis_s2mm_tlast),            // input wire s_axis_s2mm_tlast

  //AXI4 Write, makes writes to DDR from slave stream
  .m_axi_s2mm_awaddr(cl_axi_mstr_bus.awaddr),            // output wire [63 : 0] m_axi_s2mm_awaddr
  .m_axi_s2mm_awlen(cl_axi_mstr_bus.awlen),              // output wire [7 : 0] m_axi_s2mm_awlen
  .m_axi_s2mm_awsize(cl_axi_mstr_bus.awsize),            // output wire [2 : 0] m_axi_s2mm_awsize
  .m_axi_s2mm_awburst(m_axi_s2mm_awburst),          // output wire [1 : 0] m_axi_s2mm_awburst
  .m_axi_s2mm_awprot(m_axi_s2mm_awprot),            // output wire [2 : 0] m_axi_s2mm_awprot
  .m_axi_s2mm_awcache(m_axi_s2mm_awcache),          // output wire [3 : 0] m_axi_s2mm_awcache
  .m_axi_s2mm_awvalid(cl_axi_mstr_bus.awvalid),          // output wire m_axi_s2mm_awvalid
  .m_axi_s2mm_awready(cl_axi_mstr_bus.awready),          // input wire m_axi_s2mm_awready
  .m_axi_s2mm_wdata(cl_axi_mstr_bus.wdata),              // output wire [511 : 0] m_axi_s2mm_wdata
  .m_axi_s2mm_wstrb(cl_axi_mstr_bus.wstrb),              // output wire [63 : 0] m_axi_s2mm_wstrb
  .m_axi_s2mm_wlast(cl_axi_mstr_bus.wlast),              // output wire m_axi_s2mm_wlast
  .m_axi_s2mm_wvalid(cl_axi_mstr_bus.wvalid),            // output wire m_axi_s2mm_wvalid
  .m_axi_s2mm_wready(cl_axi_mstr_bus.wready),            // input wire m_axi_s2mm_wready
  .m_axi_s2mm_bresp(cl_axi_mstr_bus.bresp),              // input wire [1 : 0] m_axi_s2mm_bresp
  .m_axi_s2mm_bvalid(cl_axi_mstr_bus.bvalid),            // input wire m_axi_s2mm_bvalid
  .m_axi_s2mm_bready(cl_axi_mstr_bus.bready),            // output wire m_axi_s2mm_bready


  // Interrupt AXI4 to Stream
  .mm2s_introut(mm2s_introut),                      // output wire mm2s_introut

  // Interrput Stream to AXI4
  .s2mm_introut(s2mm_introut),                      // output wire s2mm_introut

  // Debug signals
  .axi_dma_tstvec(axi_dma_tstvec)                  // output wire [31 : 0] axi_dma_tstvec
  );

endmodule
