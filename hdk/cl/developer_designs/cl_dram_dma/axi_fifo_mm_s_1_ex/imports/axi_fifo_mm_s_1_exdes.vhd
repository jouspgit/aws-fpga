--------------------------------------------------------------------------------
--
-- axi_fifo_mm_s  Core - Example design
--
--------------------------------------------------------------------------------
--
-- (c) Copyright 2009 - 2013 Xilinx, Inc. All rights reserved.
-- 
-- This file contains confidential and proprietary information
-- of Xilinx, Inc. and is protected under U.S. and
-- international copyright and other intellectual property
-- laws.
-- 
-- DISCLAIMER
-- This disclaimer is not a license and does not grant any
-- rights to the materials distributed herewith. Except as
-- otherwise provided in a valid license issued to you by
-- Xilinx, and to the maximum extent permitted by applicable
-- law: (1) THESE MATERIALS ARE MADE AVAILABLE "AS IS" AND
-- WITH ALL FAULTS, AND XILINX HEREBY DISCLAIMS ALL WARRANTIES
-- AND CONDITIONS, EXPRESS, IMPLIED, OR STATUTORY, INCLUDING
-- BUT NOT LIMITED TO WARRANTIES OF MERCHANTABILITY, NON-
-- INFRINGEMENT, OR FITNESS FOR ANY PARTICULAR PURPOSE; and
-- (2) Xilinx shall not be liable (whether in contract or tort,
-- including negligence, or under any other theory of
-- liability) for any loss or damage of any kind or nature
-- related to, arising under or in connection with these
-- materials, including for any direct, or any indirect,
-- special, incidental, or consequential loss or damage
-- (including loss of data, profits, goodwill, or any type of
-- loss or damage suffered as a result of any action brought
-- by a third party) even if such damage or loss was
-- reasonably foreseeable or Xilinx had been advised of the
-- possibility of the same.
-- 
-- CRITICAL APPLICATIONS
-- Xilinx products are not designed or intended to be fail-
-- safe, or for use in any application requiring fail-safe
-- performance, such as life-support or safety devices or
-- systems, Class III medical devices, nuclear facilities,
-- applications related to the deployment of airbags, or any
-- other applications that could lead to death, personal
-- injury, or severe property or environmental damage
-- (individually and collectively, "Critical
-- Applications"). Customer assumes the sole risk and
-- liability of any use of Xilinx products in Critical
-- Applications, subject only to applicable laws and
-- regulations governing limitations on product liability.
-- 
-- THIS COPYRIGHT NOTICE AND DISCLAIMER MUST BE RETAINED AS
-- PART OF THIS FILE AT ALL TIMES.
--------------------------------------------------------------------------------
--
-- Filename: axi_fifo_mm_s_1_exdes.vhd
--
-- Description:
--   This is axi_fifo_mm_s core example design using axi traffic generator core.
--
--------------------------------------------------------------------------------
-- Library Declarations
--------------------------------------------------------------------------------

LIBRARY ieee;
USE ieee.std_logic_1164.all;
USE ieee.numeric_std.all;
USE ieee.std_logic_misc.all;
USE ieee.std_logic_arith.all;
USE ieee.std_logic_unsigned.all;

LIBRARY unisim;
USE unisim.vcomponents.all;

ENTITY axi_fifo_mm_s_1_exdes IS
  PORT(
    SIGNAL  aclk   	 : IN STD_LOGIC;
    SIGNAL  aresetn 	 : IN STD_LOGIC;
    SIGNAL  done         : OUT STD_LOGIC;
    SIGNAL  test_status  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)
  );
END ENTITY;

ARCHITECTURE arch_axi_fifo_mm_s_1_exdes of axi_fifo_mm_s_1_exdes IS

 SIGNAL m_axi_awid                          : STD_LOGIC_VECTOR(1 - 1 DOWNTO 0);
 SIGNAL m_axi_awaddr                        : STD_LOGIC_VECTOR(32 - 1 DOWNTO 0);
 SIGNAL m_axi_awlen                         : STD_LOGIC_VECTOR(8 - 1 DOWNTO 0);
 SIGNAL m_axi_awsize                        : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0);
 SIGNAL m_axi_awburst                       : STD_LOGIC_VECTOR(2 - 1 DOWNTO 0);
 SIGNAL m_axi_awlock                        : STD_LOGIC_VECTOR(1 - 1 DOWNTO 0);
 SIGNAL m_axi_awcache                       : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
 SIGNAL m_axi_awprot                        : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0);
 SIGNAL m_axi_awqos                         : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
 SIGNAL m_axi_awvalid                       : STD_LOGIC;
 SIGNAL m_axi_awready                       : STD_LOGIC;

 SIGNAL m_axi_wdata                         : STD_LOGIC_VECTOR(512 - 1 DOWNTO 0);
 SIGNAL m_axi_wstrb                         : STD_LOGIC_VECTOR(512 / 8 - 1 DOWNTO 0);
 SIGNAL m_axi_wlast                         : STD_LOGIC;
 SIGNAL m_axi_wvalid                        : STD_LOGIC;
 SIGNAL m_axi_wready                        : STD_LOGIC;
 
 SIGNAL m_axi_bid                           : STD_LOGIC_VECTOR(1 - 1 DOWNTO 0);
 SIGNAL m_axi_bresp                         : STD_LOGIC_VECTOR(2 - 1 DOWNTO 0);
 SIGNAL m_axi_bvalid                        : STD_LOGIC;
 SIGNAL m_axi_bready                        : STD_LOGIC;
 
 SIGNAL m_axi_arid                          : STD_LOGIC_VECTOR(1 - 1 DOWNTO 0);
 SIGNAL m_axi_araddr                        : STD_LOGIC_VECTOR(32 - 1 DOWNTO 0);
 SIGNAL m_axi_arlen                         : STD_LOGIC_VECTOR(8 - 1 DOWNTO 0);
 SIGNAL m_axi_arsize                        : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0);
 SIGNAL m_axi_arburst                       : STD_LOGIC_VECTOR(2 - 1 DOWNTO 0);
 SIGNAL m_axi_arlock                        : STD_LOGIC_VECTOR(1 - 1 DOWNTO 0);
 SIGNAL m_axi_arcache                       : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
 SIGNAL m_axi_arprot                        : STD_LOGIC_VECTOR(3 - 1 DOWNTO 0);
 SIGNAL m_axi_arqos                         : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
 SIGNAL m_axi_arvalid                       : STD_LOGIC;
 SIGNAL m_axi_arready                       : STD_LOGIC;
 
 SIGNAL m_axi_rid                           : STD_LOGIC_VECTOR(1 - 1 DOWNTO 0);
 SIGNAL m_axi_rdata                         : STD_LOGIC_VECTOR(512 - 1 DOWNTO 0);
 SIGNAL m_axi_rresp                         : STD_LOGIC_VECTOR(2 - 1 DOWNTO 0);
 SIGNAL m_axi_rlast                         : STD_LOGIC;
 SIGNAL m_axi_rvalid                        : STD_LOGIC;
 SIGNAL m_axi_rready                        : STD_LOGIC;

 SIGNAL m_axis_tready                       : STD_LOGIC;
 SIGNAL m_axis_tvalid                       : STD_LOGIC;
 SIGNAL m_axis_tlast                        : STD_LOGIC;
 SIGNAL m_axis_tdata                        : STD_LOGIC_VECTOR(512 - 1 DOWNTO 0);
 SIGNAL m_axis_tstrb                        : STD_LOGIC_VECTOR(512/8 - 1 DOWNTO 0);
 SIGNAL m_axis_tkeep                        : STD_LOGIC_VECTOR(512/8 - 1 DOWNTO 0);
 SIGNAL m_axis_tuser                        : STD_LOGIC_VECTOR(64 - 1 DOWNTO 0);
 SIGNAL m_axis_tid                          : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
 SIGNAL m_axis_tdest                        : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
 SIGNAL s_axis_tready                       : STD_LOGIC;
 SIGNAL s_axis_tvalid                       : STD_LOGIC;
 SIGNAL s_axis_tlast                        : STD_LOGIC;
 SIGNAL s_axis_tdata                        : STD_LOGIC_VECTOR(512-1 DOWNTO 0);
 SIGNAL s_axis_tstrb                        : STD_LOGIC_VECTOR(512/8 - 1 DOWNTO 0);
 SIGNAL s_axis_tkeep                        : STD_LOGIC_VECTOR(512/8 - 1 DOWNTO 0);
 SIGNAL s_axis_tuser                        : STD_LOGIC_VECTOR(64 - 1 DOWNTO 0);
 SIGNAL s_axis_tid                          : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
 SIGNAL s_axis_tdest                        : STD_LOGIC_VECTOR(4 - 1 DOWNTO 0);
 
 SIGNAL m_axi_lite_ch1_awaddr               : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch1_awprot               : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch1_awvalid              : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch1_awready              : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch1_wdata                : STD_LOGIC_VECTOR(32-1 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch1_wstrb                : STD_LOGIC_VECTOR(32/8-1 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch1_wvalid               : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch1_wready               : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch1_bresp                : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch1_bvalid               : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch1_bready               : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch1_araddr               : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch1_arvalid              : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch1_arready              : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch1_rdata                : STD_LOGIC_VECTOR(32-1 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch1_rvalid               : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch1_rresp                : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch1_rready               : STD_LOGIC := '0';

 SIGNAL m_axi_lite_ch2_awaddr               : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch2_awprot               : STD_LOGIC_VECTOR(2 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch2_awvalid              : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch2_awready              : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch2_wdata                : STD_LOGIC_VECTOR(32-1 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch2_wstrb                : STD_LOGIC_VECTOR(32/8-1 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch2_wvalid               : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch2_wready               : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch2_bresp                : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch2_bvalid               : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch2_bready               : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch2_araddr               : STD_LOGIC_VECTOR(31 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch2_arvalid              : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch2_arready              : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch2_rdata                : STD_LOGIC_VECTOR(32-1 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch2_rvalid               : STD_LOGIC := '0';
 SIGNAL m_axi_lite_ch2_rresp                : STD_LOGIC_VECTOR(1 DOWNTO 0) := (OTHERS => '0');
 SIGNAL m_axi_lite_ch2_rready               : STD_LOGIC := '0';
 SIGNAL lite_gen_status                     : STD_LOGIC_VECTOR(31 DOWNTO 0);
 SIGNAL stim_status                         : STD_LOGIC_VECTOR(5 DOWNTO 0);
 SIGNAL data_gen                            : STD_LOGIC_VECTOR(7 DOWNTO 0);
 SIGNAL last_counter                        : STD_LOGIC_VECTOR(3 DOWNTO 0);
 SIGNAL next_data                           : STD_LOGIC := '0';
 SIGNAL data_status                         : STD_LOGIC := '0';
 SIGNAL wdata_512                           : STD_LOGIC_VECTOR(512-1 DOWNTO 0) := (OTHERS => '0');
 SIGNAL rdata_512                           : STD_LOGIC_VECTOR(512-1 DOWNTO 0) := (OTHERS => '0');

 SIGNAL aclk_i 			            : STD_LOGIC;
-----------------------------------------------------------------------------

  COMPONENT axi_fifo_mm_s_1 IS
  PORT ( 
  s_axi_aclk                  : IN STD_LOGIC;
  s_axi_aresetn               : IN STD_LOGIC;
  
  --Lite interface
  ----AW
  s_axi_awaddr                : IN STD_LOGIC_VECTOR(32-1 DOWNTO 0);
  s_axi_awvalid               : IN STD_LOGIC;
  s_axi_awready               : OUT STD_LOGIC;
  ----W
  s_axi_wdata                 : IN STD_LOGIC_VECTOR(32-1 DOWNTO 0);
  s_axi_wstrb                 : IN STD_LOGIC_VECTOR(32/8-1 DOWNTO 0);
  s_axi_wvalid                : IN STD_LOGIC;
  s_axi_wready                : OUT STD_LOGIC;
  ----B
  s_axi_bresp                 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
  s_axi_bvalid                : OUT STD_LOGIC;
  s_axi_bready                : IN STD_LOGIC;
  ----AR
  s_axi_araddr                : IN STD_LOGIC_VECTOR(32-1 DOWNTO 0);
  s_axi_arvalid               : IN STD_LOGIC;
  s_axi_arready               : OUT STD_LOGIC;
  ---R
  s_axi_rdata                 : OUT STD_LOGIC_VECTOR(32-1 DOWNTO 0);
  s_axi_rvalid                : OUT STD_LOGIC;
  s_axi_rready                : IN STD_LOGIC;
  s_axi_rresp                 : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
  
  --Full interface
  ----AW
  s_axi4_awaddr               : IN STD_LOGIC_VECTOR(32-1 DOWNTO 0);
  s_axi4_awvalid              : IN STD_LOGIC;
  s_axi4_awready              : OUT STD_LOGIC;
  s_axi4_awid                 : IN STD_LOGIC_VECTOR(4-1 DOWNTO 0);
  s_axi4_awlen                : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
  s_axi4_awsize               : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
  s_axi4_awburst              : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
  s_axi4_awlock               : IN STD_LOGIC;
  s_axi4_awcache              : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
  s_axi4_awprot               : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
  --  s_axi4_awqos            : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
  --  s_axi4_awregion         : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
  ----W
  s_axi4_wdata                : IN STD_LOGIC_VECTOR(512-1 DOWNTO 0);
  s_axi4_wstrb                : IN STD_LOGIC_VECTOR(512/8-1 DOWNTO 0);
  s_axi4_wvalid               : IN STD_LOGIC;
  s_axi4_wready               : OUT STD_LOGIC;
  s_axi4_wlast                : IN STD_LOGIC;
  ----B
  s_axi4_bresp                : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
  s_axi4_bvalid               : OUT STD_LOGIC;
  s_axi4_bready               : IN STD_LOGIC;
  s_axi4_bid                  : OUT STD_LOGIC_VECTOR(4-1 DOWNTO 0);
  ----AR
  s_axi4_araddr               : IN STD_LOGIC_VECTOR(32-1 DOWNTO 0);
  s_axi4_arvalid              : IN STD_LOGIC;
  s_axi4_arready              : OUT STD_LOGIC;
  s_axi4_arid                 : IN STD_LOGIC_VECTOR(4-1 DOWNTO 0);
  s_axi4_arlen                : IN STD_LOGIC_VECTOR(7 DOWNTO 0);
  s_axi4_arsize               : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
  s_axi4_arburst              : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
  s_axi4_arlock               : IN STD_LOGIC;
  s_axi4_arcache              : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
  s_axi4_arprot               : IN STD_LOGIC_VECTOR(2 DOWNTO 0);
  --  s_axi4_arqos            : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
  --  s_axi4_arregion         : IN STD_LOGIC_VECTOR(3 DOWNTO 0);
  
  ---R
  s_axi4_rdata                : OUT STD_LOGIC_VECTOR(512-1 DOWNTO 0);
  s_axi4_rresp                : OUT STD_LOGIC_VECTOR(1 DOWNTO 0);
  s_axi4_rvalid               : OUT STD_LOGIC;
  s_axi4_rready               : IN STD_LOGIC;
  s_axi4_rlast                : OUT STD_LOGIC;
  s_axi4_rid                  : OUT STD_LOGIC_VECTOR(4-1 DOWNTO 0);
  -- TX AXI Streaming
  mm2s_prmry_reset_out_n      : OUT STD_LOGIC;
  axi_str_txd_tvalid          : OUT STD_LOGIC;
  axi_str_txd_tready          : IN STD_LOGIC;
  axi_str_txd_tlast           : OUT STD_LOGIC;
  axi_str_txd_tdata           : OUT STD_LOGIC_VECTOR(512-1 DOWNTO 0);
  
  -- TX AXI Control Streaming
  mm2s_cntrl_reset_out_n      : OUT STD_LOGIC;
  axi_str_txc_tvalid          : OUT STD_LOGIC;
  axi_str_txc_tready          : IN STD_LOGIC;
  axi_str_txc_tlast           : OUT STD_LOGIC;
  axi_str_txc_tdata           : OUT STD_LOGIC_VECTOR(512-1 DOWNTO 0);
  
  -- RX AXI Streaming
  s2mm_prmry_reset_out_n      : OUT STD_LOGIC;
  axi_str_rxd_tvalid          : IN STD_LOGIC;
  axi_str_rxd_tready          : OUT STD_LOGIC;
  axi_str_rxd_tlast           : IN STD_LOGIC;
  axi_str_rxd_tdata           : IN STD_LOGIC_VECTOR(512-1 DOWNTO 0);
  interrupt                   : OUT STD_LOGIC
);
END COMPONENT;


COMPONENT atg_lite_agent
  PORT (
    s_axi_aclk             : IN STD_LOGIC;
    s_axi_aresetn          : IN STD_LOGIC;
    m_axi_lite_ch1_awaddr  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_lite_ch1_awprot  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_lite_ch1_awvalid : OUT STD_LOGIC;
    m_axi_lite_ch1_awready : IN STD_LOGIC;
    m_axi_lite_ch1_wdata   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_lite_ch1_wstrb   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_lite_ch1_wvalid  : OUT STD_LOGIC;
    m_axi_lite_ch1_wready  : IN STD_LOGIC;
    m_axi_lite_ch1_bresp   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_lite_ch1_bvalid  : IN STD_LOGIC;
    m_axi_lite_ch1_bready  : OUT STD_LOGIC;
    m_axi_lite_ch1_araddr  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_lite_ch1_arvalid : OUT STD_LOGIC;
    m_axi_lite_ch1_arready : IN STD_LOGIC;
    m_axi_lite_ch1_rvalid  : IN STD_LOGIC;
    m_axi_lite_ch1_rready  : OUT STD_LOGIC;
    m_axi_lite_ch1_rdata   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_lite_ch1_rresp   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_lite_ch2_awaddr  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_lite_ch2_awprot  : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);
    m_axi_lite_ch2_awvalid : OUT STD_LOGIC;
    m_axi_lite_ch2_awready : IN STD_LOGIC;
    m_axi_lite_ch2_wdata   : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_lite_ch2_wstrb   : OUT STD_LOGIC_VECTOR(3 DOWNTO 0);
    m_axi_lite_ch2_wvalid  : OUT STD_LOGIC;
    m_axi_lite_ch2_wready  : IN STD_LOGIC;
    m_axi_lite_ch2_bresp   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    m_axi_lite_ch2_bvalid  : IN STD_LOGIC;
    m_axi_lite_ch2_bready  : OUT STD_LOGIC;
    m_axi_lite_ch2_araddr  : OUT STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_lite_ch2_arvalid : OUT STD_LOGIC;
    m_axi_lite_ch2_arready : IN STD_LOGIC;
    m_axi_lite_ch2_rvalid  : IN STD_LOGIC;
    m_axi_lite_ch2_rready  : OUT STD_LOGIC;
    m_axi_lite_ch2_rdata   : IN STD_LOGIC_VECTOR(31 DOWNTO 0);
    m_axi_lite_ch2_rresp   : IN STD_LOGIC_VECTOR(1 DOWNTO 0);
    done                   : OUT STD_LOGIC;
    status                 : OUT STD_LOGIC_VECTOR(31 DOWNTO 0)
  );
END COMPONENT;


BEGIN

    aclk_buf: bufg
    PORT MAP(
      i => aclk,
      o => aclk_i
    );
 
  test_status   <= lite_gen_status(1 DOWNTO 0) & data_status;

  m_axis_tready <= s_axis_tready;
  s_axis_tvalid <= m_axis_tvalid;
  s_axis_tlast  <= m_axis_tlast;
  s_axis_tdata  <= m_axis_tdata;
  s_axis_tstrb  <= m_axis_tstrb;
  s_axis_tkeep  <= m_axis_tkeep;
  s_axis_tuser  <= m_axis_tuser;
  s_axis_tid    <= m_axis_tid;
  s_axis_tdest  <= m_axis_tdest;

  data_status   <= '0';




  
  
  
  wdata_512             <= m_axi_lite_ch2_wdata & m_axi_lite_ch2_wdata & m_axi_lite_ch2_wdata & m_axi_lite_ch2_wdata 
			  & m_axi_lite_ch2_wdata & m_axi_lite_ch2_wdata & m_axi_lite_ch2_wdata & m_axi_lite_ch2_wdata
                          & m_axi_lite_ch2_wdata & m_axi_lite_ch2_wdata & m_axi_lite_ch2_wdata & m_axi_lite_ch2_wdata 
			  & m_axi_lite_ch2_wdata & m_axi_lite_ch2_wdata & m_axi_lite_ch2_wdata & m_axi_lite_ch2_wdata;
  m_axi_lite_ch2_rdata <= rdata_512(31 DOWNTO 0);
  


  axi_fifo_mm_s_1_inst : axi_fifo_mm_s_1
  PORT MAP( 
          --axi4 lite SIGNALs
          s_axi_aclk          => aclk_i,
          s_axi_aresetn       => aresetn,
          s_axi_awaddr        => m_axi_lite_ch1_awaddr,
          s_axi_awvalid       => m_axi_lite_ch1_awvalid,
          s_axi_awready       => m_axi_lite_ch1_awready,
          s_axi_wdata         => m_axi_lite_ch1_wdata,
          s_axi_wstrb         => m_axi_lite_ch1_wstrb,
          s_axi_wvalid        => m_axi_lite_ch1_wvalid,
          s_axi_wready        => m_axi_lite_ch1_wready,
          s_axi_bresp         => m_axi_lite_ch1_bresp,
          s_axi_bvalid        => m_axi_lite_ch1_bvalid,
          s_axi_bready        => m_axi_lite_ch1_bready,
          s_axi_araddr        => m_axi_lite_ch1_araddr,
          s_axi_arvalid       => m_axi_lite_ch1_arvalid,
          s_axi_arready       => m_axi_lite_ch1_arready,
          s_axi_rdata         => m_axi_lite_ch1_rdata,
          s_axi_rresp         => m_axi_lite_ch1_rresp,
          s_axi_rvalid        => m_axi_lite_ch1_rvalid,
          s_axi_rready        => m_axi_lite_ch1_rready,

	  --axi4 full interface
          --axi SIGNALs         
          s_axi4_awid => (OTHERS => '0'),                
          s_axi4_awaddr => m_axi_lite_ch2_awaddr,              
          s_axi4_awlen => (OTHERS => '0'),               
          s_axi4_awsize => STD_LOGIC_VECTOR(to_unsigned(6, 3)),              
          s_axi4_awburst => STD_LOGIC_VECTOR(to_unsigned(1, 2)),             
          s_axi4_awlock => '0',              
          s_axi4_awcache => (OTHERS => '0'),             
          s_axi4_awprot => (OTHERS => '0'),              
          s_axi4_awvalid => m_axi_lite_ch2_awvalid,             
          s_axi4_awready => m_axi_lite_ch2_awready,             

 
          s_axi4_wdata => wdata_512,               
          s_axi4_wstrb => (OTHERS => '1'),               
          s_axi4_wlast => '1',               
          s_axi4_wvalid => m_axi_lite_ch2_wvalid,              
          s_axi4_wready => m_axi_lite_ch2_wready,              

          s_axi4_bid => open,                 
          s_axi4_bresp => m_axi_lite_ch2_bresp,               
          s_axi4_bvalid => m_axi_lite_ch2_bvalid,              
          s_axi4_bready => m_axi_lite_ch2_bready,              
          s_axi4_arid => (OTHERS => '0'),                
          s_axi4_araddr => m_axi_lite_ch2_araddr,              
          s_axi4_arlen => (OTHERS => '0'),               
          s_axi4_arsize => STD_LOGIC_VECTOR(to_unsigned(6, 3)),              
          s_axi4_arburst => STD_LOGIC_VECTOR(to_unsigned(1, 2)),             
          s_axi4_arlock => '0',              
          s_axi4_arcache => (OTHERS => '0'),             
          s_axi4_arprot => (OTHERS => '0'),              
          s_axi4_arvalid => m_axi_lite_ch2_arvalid,             
          s_axi4_arready => m_axi_lite_ch2_arready,             

          s_axi4_rid => open,                 
          s_axi4_rdata => rdata_512,               
          s_axi4_rresp => m_axi_lite_ch2_rresp,               
          s_axi4_rlast => open,               
          s_axi4_rvalid => m_axi_lite_ch2_rvalid,              
          s_axi4_rready => m_axi_lite_ch2_rready,              
          --tx axi streaming    
          mm2s_prmry_reset_out_n => open,
          axi_str_txd_tvalid => m_axis_tvalid,
          axi_str_txd_tready => m_axis_tready,
          axi_str_txd_tlast => m_axis_tlast,
          axi_str_txd_tdata => m_axis_tdata,
          -- rx axi streaming   
          s2mm_prmry_reset_out_n => open,
          axi_str_rxd_tvalid => s_axis_tvalid,
          axi_str_rxd_tready => s_axis_tready,
          axi_str_rxd_tlast => s_axis_tlast,
          axi_str_rxd_tdata => s_axis_tdata,

	  -- tx axi control streaming
          mm2s_cntrl_reset_out_n => open,
          axi_str_txc_tvalid => open,
          axi_str_txc_tready => '1',
          axi_str_txc_tlast => open,
          axi_str_txc_tdata => open,
          interrupt => open 
);


 
   lite_agent:atg_lite_agent
   port map
   (
    s_axi_aclk             => aclk_i,
    s_axi_aresetn          => aresetn,
    m_axi_lite_ch1_awaddr  => m_axi_lite_ch1_awaddr,
    m_axi_lite_ch1_awprot  => m_axi_lite_ch1_awprot,
    m_axi_lite_ch1_awvalid => m_axi_lite_ch1_awvalid,
    m_axi_lite_ch1_awready => m_axi_lite_ch1_awready,
    m_axi_lite_ch1_wdata   => m_axi_lite_ch1_wdata,
    m_axi_lite_ch1_wstrb   => m_axi_lite_ch1_wstrb,
    m_axi_lite_ch1_wvalid  => m_axi_lite_ch1_wvalid,
    m_axi_lite_ch1_wready  => m_axi_lite_ch1_wready,
    m_axi_lite_ch1_bresp   => m_axi_lite_ch1_bresp,
    m_axi_lite_ch1_bvalid  => m_axi_lite_ch1_bvalid,
    m_axi_lite_ch1_bready  => m_axi_lite_ch1_bready,
    m_axi_lite_ch1_araddr  => m_axi_lite_ch1_araddr,
    m_axi_lite_ch1_arvalid => m_axi_lite_ch1_arvalid,
    m_axi_lite_ch1_arready => m_axi_lite_ch1_arready,
    m_axi_lite_ch1_rdata   => m_axi_lite_ch1_rdata,
    m_axi_lite_ch1_rvalid  => m_axi_lite_ch1_rvalid,
    m_axi_lite_ch1_rready  => m_axi_lite_ch1_rready,
    m_axi_lite_ch1_rresp   => m_axi_lite_ch1_rresp,
    m_axi_lite_ch2_awaddr  => m_axi_lite_ch2_awaddr,
    m_axi_lite_ch2_awprot  => m_axi_lite_ch2_awprot,
    m_axi_lite_ch2_awvalid => m_axi_lite_ch2_awvalid,
    m_axi_lite_ch2_awready => m_axi_lite_ch2_awready,
    m_axi_lite_ch2_wdata   => m_axi_lite_ch2_wdata,
    m_axi_lite_ch2_wstrb   => m_axi_lite_ch2_wstrb,
    m_axi_lite_ch2_wvalid  => m_axi_lite_ch2_wvalid,
    m_axi_lite_ch2_wready  => m_axi_lite_ch2_wready,
    m_axi_lite_ch2_bresp   => m_axi_lite_ch2_bresp,
    m_axi_lite_ch2_bvalid  => m_axi_lite_ch2_bvalid,
    m_axi_lite_ch2_bready  => m_axi_lite_ch2_bready,
    m_axi_lite_ch2_araddr  => m_axi_lite_ch2_araddr,
    m_axi_lite_ch2_arvalid => m_axi_lite_ch2_arvalid,
    m_axi_lite_ch2_arready => m_axi_lite_ch2_arready,
    m_axi_lite_ch2_rdata   => m_axi_lite_ch2_rdata,
    m_axi_lite_ch2_rvalid  => m_axi_lite_ch2_rvalid,
    m_axi_lite_ch2_rready  => m_axi_lite_ch2_rready,
    m_axi_lite_ch2_rresp   => m_axi_lite_ch2_rresp,
    done                   => done,
    status                 => lite_gen_status
    );


end arch_axi_fifo_mm_s_1_exdes;
