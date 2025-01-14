-makelib ies_lib/xpm -sv \
  "/opt/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_cdc/hdl/xpm_cdc.sv" \
  "/opt/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_fifo/hdl/xpm_fifo.sv" \
  "/opt/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_memory/hdl/xpm_memory.sv" \
-endlib
-makelib ies_lib/xpm \
  "/opt/Xilinx/Vivado/2020.1/data/ip/xpm/xpm_VCOMP.vhd" \
-endlib
-makelib ies_lib/dist_mem_gen_v8_0_13 \
  "../../../ipstatic/simulation/dist_mem_gen_v8_0.v" \
-endlib
-makelib ies_lib/blk_mem_gen_v8_4_4 \
  "../../../ipstatic/simulation/blk_mem_gen_v8_4.v" \
-endlib
-makelib ies_lib/lib_bmg_v1_0_13 \
  "../../../ipstatic/hdl/lib_bmg_v1_0_rfs.vhd" \
-endlib
-makelib ies_lib/lib_cdc_v1_0_2 \
  "../../../ipstatic/hdl/lib_cdc_v1_0_rfs.vhd" \
-endlib
-makelib ies_lib/axi_traffic_gen_v3_0_7 \
  "../../../ipstatic/hdl/axi_traffic_gen_v3_0_rfs.vhd" \
-endlib
-makelib ies_lib/axi_traffic_gen_v3_0_7 \
  "../../../ipstatic/hdl/axi_traffic_gen_v3_0_rfs.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  "../../../../axi_fifo_mm_s_1_ex.srcs/sources_1/ip/atg_lite_agent/sim/atg_lite_agent.v" \
-endlib
-makelib ies_lib/xil_defaultlib \
  glbl.v
-endlib

