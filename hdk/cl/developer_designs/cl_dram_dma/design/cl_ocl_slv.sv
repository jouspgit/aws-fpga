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

module cl_ocl_slv (
   
   input clk,
   input sync_rst_n,

   input sh_cl_flr_assert_q,

   axi_bus_t.master sh_ocl_bus,
   axi_bus_t.slave axi_mstr_dma_cfg_bus,
   axi_bus_t.slave axi_mstr_jpeg_cfg_bus,

   cfg_bus_t.slave pcim_tst_cfg_bus,
   cfg_bus_t.slave ddra_tst_cfg_bus,
   cfg_bus_t.slave ddrb_tst_cfg_bus,
   cfg_bus_t.slave ddrc_tst_cfg_bus,
   cfg_bus_t.slave ddrd_tst_cfg_bus,
   cfg_bus_t.slave int_tst_cfg_bus,
   cfg_bus_t.slave axi_mstr_cfg_bus

);


axi_bus_t sh_ocl_bus_q();


//---------------------------------
// flop the input OCL bus
//---------------------------------
   axi_register_slice_light AXIL_OCL_REG_SLC (
    .aclk          (clk),
    .aresetn       (sync_rst_n),
    .s_axi_awaddr  (sh_ocl_bus.awaddr[31:0]),
    .s_axi_awvalid (sh_ocl_bus.awvalid),
    .s_axi_awready (sh_ocl_bus.awready),
    .s_axi_wdata   (sh_ocl_bus.wdata[31:0]),
    .s_axi_wstrb   (sh_ocl_bus.wstrb[3:0]),
    .s_axi_wvalid  (sh_ocl_bus.wvalid),
    .s_axi_wready  (sh_ocl_bus.wready),
    .s_axi_bresp   (sh_ocl_bus.bresp),
    .s_axi_bvalid  (sh_ocl_bus.bvalid),
    .s_axi_bready  (sh_ocl_bus.bready),
    .s_axi_araddr  (sh_ocl_bus.araddr[31:0]),
    .s_axi_arvalid (sh_ocl_bus.arvalid),
    .s_axi_arready (sh_ocl_bus.arready),
    .s_axi_rdata   (sh_ocl_bus.rdata[31:0]),
    .s_axi_rresp   (sh_ocl_bus.rresp),
    .s_axi_rvalid  (sh_ocl_bus.rvalid),
    .s_axi_rready  (sh_ocl_bus.rready),
 
    .m_axi_awaddr  (sh_ocl_bus_q.awaddr[31:0]), 
    .m_axi_awvalid (sh_ocl_bus_q.awvalid),
    .m_axi_awready (sh_ocl_bus_q.awready),
    .m_axi_wdata   (sh_ocl_bus_q.wdata[31:0]),  
    .m_axi_wstrb   (sh_ocl_bus_q.wstrb[3:0]),
    .m_axi_wvalid  (sh_ocl_bus_q.wvalid), 
    .m_axi_wready  (sh_ocl_bus_q.wready), 
    .m_axi_bresp   (sh_ocl_bus_q.bresp),  
    .m_axi_bvalid  (sh_ocl_bus_q.bvalid), 
    .m_axi_bready  (sh_ocl_bus_q.bready), 
    .m_axi_araddr  (sh_ocl_bus_q.araddr[31:0]), 
    .m_axi_arvalid (sh_ocl_bus_q.arvalid),
    .m_axi_arready (sh_ocl_bus_q.arready),
    .m_axi_rdata   (sh_ocl_bus_q.rdata[31:0]),  
    .m_axi_rresp   (sh_ocl_bus_q.rresp),  
    .m_axi_rvalid  (sh_ocl_bus_q.rvalid), 
    .m_axi_rready  (sh_ocl_bus_q.rready)
   );

// M00 = DMA, Base = 0x0
// M01 = JPEG, Base = 0x100000


wire [127 : 0] m_axi_crossbar_awaddr;
wire [5 : 0] m_axi_crossbar_awprot;
wire [1 : 0] m_axi_crossbar_awvalid;
wire [1 : 0] m_axi_crossbar_awready;
wire [63 : 0] m_axi_crossbar_wdata;
wire [7 : 0] m_axi_crossbar_wstrb;
wire [1 : 0] m_axi_crossbar_wvalid;
wire [1 : 0] m_axi_crossbar_wready;
wire [3 : 0] m_axi_crossbar_bresp;
wire [1 : 0] m_axi_crossbar_bvalid;
wire [1 : 0] m_axi_crossbar_bready;
wire [127 : 0] m_axi_crossbar_araddr;
wire [5 : 0] m_axi_crossbar_arprot;
wire [1 : 0] m_axi_crossbar_arvalid;
wire [1 : 0] m_axi_crossbar_arready;
wire [63 : 0] m_axi_crossbar_rdata;
wire [3 : 0] m_axi_crossbar_rresp;
wire [1 : 0] m_axi_crossbar_rvalid;
wire [1 : 0] m_axi_crossbar_rready;


axi_crossbar_0 DMA_JPEG_CROSSBAR (
  .aclk(clk),                    // input wire aclk
  .aresetn(sync_rst_n),              // input wire aresetn
  .s_axi_awaddr({32'b0,sh_ocl_bus_q.awaddr[31:0]}),    // input wire [63 : 0] s_axi_awaddr
  .s_axi_awprot(3'b10),                 // input wire [2 : 0] s_axi_awprot
  .s_axi_awvalid(sh_ocl_bus_q.awvalid),  // input wire [0 : 0] s_axi_awvalid
  .s_axi_awready(sh_ocl_bus_q.awready),  // output wire [0 : 0] s_axi_awready
  .s_axi_wdata(sh_ocl_bus_q.wdata[31:0]),      // input wire [31 : 0] s_axi_wdata
  .s_axi_wstrb(sh_ocl_bus_q.wstrb[3:0]),      // input wire [3 : 0] s_axi_wstrb
  .s_axi_wvalid(sh_ocl_bus_q.wvalid),    // input wire [0 : 0] s_axi_wvalid
  .s_axi_wready(sh_ocl_bus_q.wready),    // output wire [0 : 0] s_axi_wready
  .s_axi_bresp(sh_ocl_bus_q.bresp),      // output wire [1 : 0] s_axi_bresp
  .s_axi_bvalid(sh_ocl_bus_q.bvalid),    // output wire [0 : 0] s_axi_bvalid
  .s_axi_bready(sh_ocl_bus_q.bready),    // input wire [0 : 0] s_axi_bready
  .s_axi_araddr(sh_ocl_bus_q.araddr),    // input wire [63 : 0] s_axi_araddr
  .s_axi_arprot(3'b10),                   // input wire [2 : 0] s_axi_arprot
  .s_axi_arvalid(sh_ocl_bus_q.arvalid),  // input wire [0 : 0] s_axi_arvalid
  .s_axi_arready(sh_ocl_bus_q.arready),  // output wire [0 : 0] s_axi_arready
  .s_axi_rdata(sh_ocl_bus_q.rdata[31:0]),      // output wire [31 : 0] s_axi_rdata
  .s_axi_rresp(sh_ocl_bus_q.rresp),      // output wire [1 : 0] s_axi_rresp
  .s_axi_rvalid(sh_ocl_bus_q.rvalid),    // output wire [0 : 0] s_axi_rvalid
  .s_axi_rready(sh_ocl_bus_q.rready),    // input wire [0 : 0] s_axi_rready

  .m_axi_awaddr(m_axi_crossbar_awaddr),    // output wire [127 : 0] m_axi_awaddr
  .m_axi_awprot(),                        // output wire [5 : 0] m_axi_awprot, probably 6'b10010
  .m_axi_awvalid(m_axi_crossbar_awvalid),  // output wire [1 : 0] m_axi_awvalid
  .m_axi_awready(m_axi_crossbar_awready),  // input wire [1 : 0] m_axi_awready
  .m_axi_wdata(m_axi_crossbar_wdata),      // output wire [63 : 0] m_axi_wdata
  .m_axi_wstrb(m_axi_crossbar_wstrb),      // output wire [7 : 0] m_axi_wstrb
  .m_axi_wvalid(m_axi_crossbar_wvalid),    // output wire [1 : 0] m_axi_wvalid
  .m_axi_wready(m_axi_crossbar_wready),    // input wire [1 : 0] m_axi_wready
  .m_axi_bresp(m_axi_crossbar_bresp),      // input wire [3 : 0] m_axi_bresp
  .m_axi_bvalid(m_axi_crossbar_bvalid),    // input wire [1 : 0] m_axi_bvalid
  .m_axi_bready(m_axi_crossbar_bready),    // output wire [1 : 0] m_axi_bready
  .m_axi_araddr(m_axi_crossbar_araddr),    // output wire [127 : 0] m_axi_araddr
  .m_axi_arprot(),                          // output wire [5 : 0] m_axi_arprot, probably 6'b10010
  .m_axi_arvalid(m_axi_crossbar_arvalid),  // output wire [1 : 0] m_axi_arvalid
  .m_axi_arready(m_axi_crossbar_arready),  // input wire [1 : 0] m_axi_arready
  .m_axi_rdata(m_axi_crossbar_rdata),      // input wire [63 : 0] m_axi_rdata
  .m_axi_rresp(m_axi_crossbar_rresp),      // input wire [3 : 0] m_axi_rresp
  .m_axi_rvalid(m_axi_crossbar_rvalid),    // input wire [1 : 0] m_axi_rvalid
  .m_axi_rready(m_axi_crossbar_rready)    // output wire [1 : 0] m_axi_rready
);
// axi_mstr_dma_cfg_bus is LSB, axi_mstr_jpeg_cfg_bus is MSB

assign axi_mstr_dma_cfg_bus.awaddr = m_axi_crossbar_awaddr[63:0];
//assign axi_mstr_dma_cfg_bus.awprot = m_axi_crossbar_awprot[2:0]; // doesn't actually exist
assign axi_mstr_dma_cfg_bus.awvalid = m_axi_crossbar_awvalid[0];
assign m_axi_crossbar_awready[0] = axi_mstr_dma_cfg_bus.awready;
assign axi_mstr_dma_cfg_bus.wdata = m_axi_crossbar_wdata[31:0];
assign axi_mstr_dma_cfg_bus.wstrb = m_axi_crossbar_wstrb[3:0];
assign axi_mstr_dma_cfg_bus.wvalid = m_axi_crossbar_wvalid[0];
assign m_axi_crossbar_wready[0] = axi_mstr_dma_cfg_bus.wready;
assign m_axi_crossbar_bresp[1:0] = axi_mstr_dma_cfg_bus.bresp;
assign m_axi_crossbar_bvalid[0] = axi_mstr_dma_cfg_bus.bvalid;
assign axi_mstr_dma_cfg_bus.bready = m_axi_crossbar_bready[0];
assign axi_mstr_dma_cfg_bus.araddr = m_axi_crossbar_araddr[63:0];
//assign axi_mstr_dma_cfg_bus.arprot = m_axi_crossbar_arprot[2:0]; // doesn't actually exist
assign axi_mstr_dma_cfg_bus.arvalid = m_axi_crossbar_arvalid[0];
assign m_axi_crossbar_arready[0] = axi_mstr_dma_cfg_bus.arready;
assign m_axi_crossbar_rdata[31:0] = axi_mstr_dma_cfg_bus.rdata[31:0];
assign m_axi_crossbar_rresp[1:0] = axi_mstr_dma_cfg_bus.rresp;
assign m_axi_crossbar_rvalid[0] = axi_mstr_dma_cfg_bus.rvalid;
assign axi_mstr_dma_cfg_bus.rready = m_axi_crossbar_rready[0];

assign axi_mstr_jpeg_cfg_bus.awaddr = m_axi_crossbar_awaddr[127:64];
// assign axi_mstr_jpeg_cfg_bus.awprot = m_axi_crossbar_awprot[5:3]; // doesn't actually exist
assign axi_mstr_jpeg_cfg_bus.awvalid = m_axi_crossbar_awvalid[1];
assign m_axi_crossbar_awready[1] = axi_mstr_jpeg_cfg_bus.awready;
assign axi_mstr_jpeg_cfg_bus.wdata = m_axi_crossbar_wdata[63:32];
assign axi_mstr_jpeg_cfg_bus.wstrb = m_axi_crossbar_wstrb[7:4];
assign axi_mstr_jpeg_cfg_bus.wvalid = m_axi_crossbar_wvalid[1];
assign m_axi_crossbar_wready[1] = axi_mstr_jpeg_cfg_bus.wready;
assign m_axi_crossbar_bresp[3:2] = axi_mstr_jpeg_cfg_bus.bresp;
assign m_axi_crossbar_bvalid[1] = axi_mstr_jpeg_cfg_bus.bvalid;
assign axi_mstr_jpeg_cfg_bus.bready = m_axi_crossbar_bready[1];
assign axi_mstr_jpeg_cfg_bus.araddr = m_axi_crossbar_araddr[127:64];
//assign axi_mstr_jpeg_cfg_bus.arprot = m_axi_crossbar_arprot[5:3]; // doesn't actually exist
assign axi_mstr_jpeg_cfg_bus.arvalid = m_axi_crossbar_arvalid[1];
assign m_axi_crossbar_arready[1] = axi_mstr_jpeg_cfg_bus.arready;
assign m_axi_crossbar_rdata[63:32] = axi_mstr_jpeg_cfg_bus.rdata[31:0];
assign m_axi_crossbar_rresp[3:2] = axi_mstr_jpeg_cfg_bus.rresp;
assign m_axi_crossbar_rvalid[1] = axi_mstr_jpeg_cfg_bus.rvalid;
assign axi_mstr_jpeg_cfg_bus.rready = m_axi_crossbar_rready[1];


//-------------------------------------------------
// Slave state machine (accesses from PCIe on BAR0 for CL registers)
//-------------------------------------------------

parameter NUM_TST = (1 + 4 + 4 + 4 + 1 + 2);

typedef enum logic[2:0] {
   SLV_IDLE = 0,
   SLV_WR_ADDR = 1,
   SLV_CYC = 2,
   SLV_RESP = 3
   } slv_state_t;

slv_state_t slv_state, slv_state_nxt;

logic slv_arb_wr;                //Arbitration winner (write/read)
logic slv_cyc_wr;                //Cycle is write
logic[31:0] slv_mx_addr;         //Mux address
logic slv_mx_rsp_ready;          //Mux the response ready

logic slv_wr_req;                //Write request
logic slv_rd_req;                //Read request

logic slv_cyc_done;              //Cycle is done

logic[31:0] slv_rdata;           //Latch rdata

logic[17:0] slv_sel;              //Slave select

logic[31:0] slv_tst_addr[NUM_TST-1:0];
logic[31:0] slv_tst_wdata[NUM_TST-1:0];
logic[NUM_TST-1:0] slv_tst_wr;
logic[NUM_TST-1:0] slv_tst_rd;
logic slv_mx_req_valid;

logic[NUM_TST-1:0] tst_slv_ack;
logic[31:0] tst_slv_rdata [NUM_TST-1:0];

logic slv_did_req;            //Once cycle request, latch that did the request


//Write request valid when both address is valid
assign slv_wr_req = sh_ocl_bus_q.awvalid;
assign slv_rd_req = sh_ocl_bus_q.arvalid;
assign slv_mx_rsp_ready = (slv_cyc_wr)? sh_ocl_bus_q.bready: sh_ocl_bus_q.rready;
assign slv_mx_req_valid = (slv_cyc_wr)?   sh_ocl_bus_q.wvalid: 1'b1;

//Fixed write hi-pri
assign slv_arb_wr = slv_wr_req;

logic [63:0] slv_req_rd_addr;
logic [63:0] slv_req_wr_addr;
logic [5:0]  slv_req_rd_id;
logic [5:0]  slv_req_wr_id;


always_ff @(negedge sync_rst_n or posedge clk)
  if (!sync_rst_n)
  begin
    {slv_req_rd_addr, slv_req_wr_addr} <= 128'd0;
    {slv_req_rd_id, slv_req_wr_id} <= 0;
  end
  else if ((slv_state == SLV_IDLE) && sh_ocl_bus_q.awvalid)
  begin
    slv_req_wr_addr[31:0] <= sh_ocl_bus_q.awaddr[31:0];
    slv_req_wr_id <= 0;
  end
  else if ((slv_state == SLV_IDLE) && sh_ocl_bus_q.arvalid)
  begin
    slv_req_rd_addr[31:0] <= sh_ocl_bus_q.araddr[31:0];
    slv_req_rd_id <= 0;
  end

   
//Mux address
assign slv_mx_addr = (slv_cyc_wr)? slv_req_wr_addr : slv_req_rd_addr;
   
//Slave select (256B per slave)
assign slv_sel = slv_mx_addr[24:8];
   
//Latch the winner
always_ff @(negedge sync_rst_n or posedge clk)
   if (!sync_rst_n)
      slv_cyc_wr <= 0;
   else if (slv_state==SLV_IDLE)
      slv_cyc_wr <= slv_arb_wr;

//State machine
always_comb
begin
   slv_state_nxt = slv_state;
   if (sh_cl_flr_assert_q)
      slv_state_nxt = SLV_IDLE;
   else
   begin
   case (slv_state)

      SLV_IDLE:
      begin
         if (slv_wr_req)
            slv_state_nxt = SLV_WR_ADDR;
         else if (slv_rd_req)
            slv_state_nxt = SLV_CYC;
         else
            slv_state_nxt = SLV_IDLE;
      end

      SLV_WR_ADDR:
      begin
         slv_state_nxt = SLV_CYC;
      end

      SLV_CYC:
      begin
         if (slv_cyc_done)
            slv_state_nxt = SLV_RESP;
         else
            slv_state_nxt = SLV_CYC;
      end

      SLV_RESP:
      begin
         if (slv_mx_rsp_ready)
            slv_state_nxt = SLV_IDLE;
         else
            slv_state_nxt = SLV_RESP;
      end

   endcase
   end
end

//State machine flops
always_ff @(negedge sync_rst_n or posedge clk)
   if (!sync_rst_n)
      slv_state <= SLV_IDLE;
   else
      slv_state <= slv_state_nxt;


//Cycle to TST blocks -- Repliacte for timing

always_ff @(negedge sync_rst_n or posedge clk)
   if (!sync_rst_n)
   begin
      slv_tst_addr <= '{default:'0};
      slv_tst_wdata <= '{default:'0};
   end
   else
   begin
      for (int i=0; i<NUM_TST; i++)
      begin
         slv_tst_addr[i] <= slv_mx_addr;
         slv_tst_wdata[i] <= sh_ocl_bus_q.wdata;
      end
   end

//Test are 1 clock pulses (because want to support clock crossing)
always_ff @(negedge sync_rst_n or posedge clk)
   if (!sync_rst_n)
   begin
      slv_did_req <= 0;
   end
   else if (slv_state==SLV_IDLE)
   begin
      slv_did_req <= 0;
   end
   else if (|slv_tst_wr || |slv_tst_rd)
   begin
      slv_did_req <= 1;
   end

//Flop this for timing
always_ff @(negedge sync_rst_n or posedge clk)
   if (!sync_rst_n)
   begin
      slv_tst_wr <= 0;
      slv_tst_rd <= 0;
   end
   else
   begin
      slv_tst_wr <= (slv_sel<NUM_TST) ? ((slv_state==SLV_CYC) & slv_mx_req_valid & slv_cyc_wr & !slv_did_req) << slv_sel
                                      : 0;
      slv_tst_rd <= (slv_sel<NUM_TST) ? ((slv_state==SLV_CYC) & slv_mx_req_valid & !slv_cyc_wr & !slv_did_req) << slv_sel
                                      : 0;
   end

assign slv_cyc_done = (slv_sel<NUM_TST) ? tst_slv_ack[slv_sel] : 1'b1;

//Latch the return data
always_ff @(negedge sync_rst_n or posedge clk)
   if (!sync_rst_n)
      slv_rdata <= 0;
   else if (slv_cyc_done)
      slv_rdata <= (slv_sel<NUM_TST) ? tst_slv_rdata[slv_sel] : 32'hdead_beef;

//Ready back to AXI for request
always_ff @(negedge sync_rst_n or posedge clk)
   if (!sync_rst_n)
   begin
      sh_ocl_bus_q.awready <= 0;
      sh_ocl_bus_q.wready <= 0;
      sh_ocl_bus_q.arready <= 0;
   end
   else
   begin
      sh_ocl_bus_q.awready <= (slv_state_nxt==SLV_WR_ADDR);
      sh_ocl_bus_q.wready <= ((slv_state==SLV_CYC) && (slv_state_nxt!=SLV_CYC)) && slv_cyc_wr;
      sh_ocl_bus_q.arready <= ((slv_state==SLV_CYC) && (slv_state_nxt!=SLV_CYC)) && ~slv_cyc_wr;
   end
   
//Response back to AXI
assign sh_ocl_bus_q.bid = slv_req_wr_id;
assign sh_ocl_bus_q.bresp = 0;
assign sh_ocl_bus_q.bvalid = (slv_state==SLV_RESP) && slv_cyc_wr;
  
assign sh_ocl_bus_q.rid = slv_req_rd_id;
assign sh_ocl_bus_q.rdata = slv_rdata;
assign sh_ocl_bus_q.rresp = 2'b00;
assign sh_ocl_bus_q.rvalid = (slv_state==SLV_RESP) && !slv_cyc_wr;


//assign individual cfg bus
assign pcim_tst_cfg_bus.addr = slv_tst_addr[0];
assign pcim_tst_cfg_bus.wdata = slv_tst_wdata[0];
assign pcim_tst_cfg_bus.wr = slv_tst_wr[0];
assign pcim_tst_cfg_bus.rd = slv_tst_rd[0];

assign ddra_tst_cfg_bus.addr = slv_tst_addr[1];
assign ddra_tst_cfg_bus.wdata = slv_tst_wdata[1];
assign ddra_tst_cfg_bus.wr = slv_tst_wr[1];
assign ddra_tst_cfg_bus.rd = slv_tst_rd[1];

assign ddrb_tst_cfg_bus.addr = slv_tst_addr[2];
assign ddrb_tst_cfg_bus.wdata = slv_tst_wdata[2];
assign ddrb_tst_cfg_bus.wr = slv_tst_wr[2];
assign ddrb_tst_cfg_bus.rd = slv_tst_rd[2];

assign ddrc_tst_cfg_bus.addr = slv_tst_addr[3];
assign ddrc_tst_cfg_bus.wdata = slv_tst_wdata[3];
assign ddrc_tst_cfg_bus.wr = slv_tst_wr[3];
assign ddrc_tst_cfg_bus.rd = slv_tst_rd[3];

assign ddrd_tst_cfg_bus.addr = slv_tst_addr[4];
assign ddrd_tst_cfg_bus.wdata = slv_tst_wdata[4];
assign ddrd_tst_cfg_bus.wr = slv_tst_wr[4];
assign ddrd_tst_cfg_bus.rd = slv_tst_rd[4];

assign axi_mstr_cfg_bus.addr = slv_tst_addr[5];
assign axi_mstr_cfg_bus.wdata = slv_tst_wdata[5];
assign axi_mstr_cfg_bus.wr = slv_tst_wr[5];
assign axi_mstr_cfg_bus.rd = slv_tst_rd[5];

assign int_tst_cfg_bus.addr = slv_tst_addr[13];
assign int_tst_cfg_bus.wdata = slv_tst_wdata[13];
assign int_tst_cfg_bus.wr = slv_tst_wr[13];
assign int_tst_cfg_bus.rd = slv_tst_rd[13];


//respond back with deadbeef for addresses not implemented
always_comb begin
  //for pcim
  tst_slv_ack[0] = pcim_tst_cfg_bus.ack;
  tst_slv_rdata[0] = pcim_tst_cfg_bus.rdata;
  //for DDRA
  tst_slv_ack[1] = ddra_tst_cfg_bus.ack;
  tst_slv_rdata[1] = ddra_tst_cfg_bus.rdata; 
  //for DDRB
  tst_slv_ack[2] = ddrb_tst_cfg_bus.ack;
  tst_slv_rdata[2] = ddrb_tst_cfg_bus.rdata;
  //for DDRC
  tst_slv_ack[3] = ddrc_tst_cfg_bus.ack;
  tst_slv_rdata[3] = ddrc_tst_cfg_bus.rdata; 
  //for DDRD
  tst_slv_ack[4] = ddrd_tst_cfg_bus.ack;
  tst_slv_rdata[4] = ddrd_tst_cfg_bus.rdata;
  //for AXI Master
  tst_slv_ack[5] = axi_mstr_cfg_bus.ack;
  tst_slv_rdata[5] = axi_mstr_cfg_bus.rdata;
  //for int ATG
  tst_slv_ack[13] = int_tst_cfg_bus.ack;
  tst_slv_rdata[13] = int_tst_cfg_bus.rdata;
  for(int i=6; i<13; i++) begin
    tst_slv_ack[i] = 1'b1;
    tst_slv_rdata[i] = 32'hdead_beef;
  end
  for(int i=14; i<16; i++) begin
    tst_slv_ack[i] = 1'b1;
    tst_slv_rdata[i] = 32'hdead_beef;
  end
end


endmodule

