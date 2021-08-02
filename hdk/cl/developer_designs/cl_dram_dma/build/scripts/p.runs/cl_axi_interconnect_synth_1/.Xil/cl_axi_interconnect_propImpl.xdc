set_property SRC_FILE_INFO {cfile:/home/centos/src/aws-fpga/hdk/common/shell_v04261818/design/ip/cl_axi_interconnect/ip/cl_axi_interconnect_s00_regslice_0/cl_axi_interconnect_s00_regslice_0_clocks.xdc rfile:../../../../../../../../common/shell_v04261818/design/ip/cl_axi_interconnect/ip/cl_axi_interconnect_s00_regslice_0/cl_axi_interconnect_s00_regslice_0_clocks.xdc id:1 order:LATE scoped_inst:axi_interconnect_0/s00_couplers/s00_regslice/inst} [current_design]
set_property SRC_FILE_INFO {cfile:/home/centos/src/aws-fpga/hdk/common/shell_v04261818/design/ip/cl_axi_interconnect/ip/cl_axi_interconnect_s01_regslice_0/cl_axi_interconnect_s01_regslice_0_clocks.xdc rfile:../../../../../../../../common/shell_v04261818/design/ip/cl_axi_interconnect/ip/cl_axi_interconnect_s01_regslice_0/cl_axi_interconnect_s01_regslice_0_clocks.xdc id:2 order:LATE scoped_inst:axi_interconnect_0/s01_couplers/s01_regslice/inst} [current_design]
set_property SRC_FILE_INFO {cfile:/home/centos/src/aws-fpga/hdk/common/shell_v04261818/design/ip/cl_axi_interconnect/ip/cl_axi_interconnect_m00_regslice_0/cl_axi_interconnect_m00_regslice_0_clocks.xdc rfile:../../../../../../../../common/shell_v04261818/design/ip/cl_axi_interconnect/ip/cl_axi_interconnect_m00_regslice_0/cl_axi_interconnect_m00_regslice_0_clocks.xdc id:3 order:LATE scoped_inst:axi_interconnect_0/m00_couplers/m00_regslice/inst} [current_design]
set_property SRC_FILE_INFO {cfile:/home/centos/src/aws-fpga/hdk/common/shell_v04261818/design/ip/cl_axi_interconnect/ip/cl_axi_interconnect_m01_regslice_0/cl_axi_interconnect_m01_regslice_0_clocks.xdc rfile:../../../../../../../../common/shell_v04261818/design/ip/cl_axi_interconnect/ip/cl_axi_interconnect_m01_regslice_0/cl_axi_interconnect_m01_regslice_0_clocks.xdc id:4 order:LATE scoped_inst:axi_interconnect_0/m01_couplers/m01_regslice/inst} [current_design]
set_property SRC_FILE_INFO {cfile:/home/centos/src/aws-fpga/hdk/common/shell_v04261818/design/ip/cl_axi_interconnect/ip/cl_axi_interconnect_m02_regslice_0/cl_axi_interconnect_m02_regslice_0_clocks.xdc rfile:../../../../../../../../common/shell_v04261818/design/ip/cl_axi_interconnect/ip/cl_axi_interconnect_m02_regslice_0/cl_axi_interconnect_m02_regslice_0_clocks.xdc id:5 order:LATE scoped_inst:axi_interconnect_0/m02_couplers/m02_regslice/inst} [current_design]
set_property SRC_FILE_INFO {cfile:/home/centos/src/aws-fpga/hdk/common/shell_v04261818/design/ip/cl_axi_interconnect/ip/cl_axi_interconnect_m03_regslice_0/cl_axi_interconnect_m03_regslice_0_clocks.xdc rfile:../../../../../../../../common/shell_v04261818/design/ip/cl_axi_interconnect/ip/cl_axi_interconnect_m03_regslice_0/cl_axi_interconnect_m03_regslice_0_clocks.xdc id:6 order:LATE scoped_inst:axi_interconnect_0/m03_couplers/m03_regslice/inst} [current_design]
current_instance axi_interconnect_0/s00_couplers/s00_regslice/inst
set_property src_info {type:SCOPED_XDC file:1 line:10 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -scope -type CDC -id CDC-7 -user axi_register_slice -tags "1040889" -to [get_pins -filter {REF_PIN_NAME=~CLR} -of_objects  [get_cells -hierarchical -regexp .*15.*_multi/.*/common.srl_fifo_0/asyncclear_.*]] -description {Waiving CDC-7, CDC between 2 known synchronous clock domains}
current_instance
current_instance axi_interconnect_0/s01_couplers/s01_regslice/inst
set_property src_info {type:SCOPED_XDC file:2 line:10 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -scope -type CDC -id CDC-7 -user axi_register_slice -tags "1040889" -to [get_pins -filter {REF_PIN_NAME=~CLR} -of_objects  [get_cells -hierarchical -regexp .*15.*_multi/.*/common.srl_fifo_0/asyncclear_.*]] -description {Waiving CDC-7, CDC between 2 known synchronous clock domains}
current_instance
current_instance axi_interconnect_0/m00_couplers/m00_regslice/inst
set_property src_info {type:SCOPED_XDC file:3 line:10 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -scope -type CDC -id CDC-7 -user axi_register_slice -tags "1040889" -to [get_pins -filter {REF_PIN_NAME=~CLR} -of_objects  [get_cells -hierarchical -regexp .*15.*_multi/.*/common.srl_fifo_0/asyncclear_.*]] -description {Waiving CDC-7, CDC between 2 known synchronous clock domains}
current_instance
current_instance axi_interconnect_0/m01_couplers/m01_regslice/inst
set_property src_info {type:SCOPED_XDC file:4 line:10 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -scope -type CDC -id CDC-7 -user axi_register_slice -tags "1040889" -to [get_pins -filter {REF_PIN_NAME=~CLR} -of_objects  [get_cells -hierarchical -regexp .*15.*_multi/.*/common.srl_fifo_0/asyncclear_.*]] -description {Waiving CDC-7, CDC between 2 known synchronous clock domains}
current_instance
current_instance axi_interconnect_0/m02_couplers/m02_regslice/inst
set_property src_info {type:SCOPED_XDC file:5 line:10 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -scope -type CDC -id CDC-7 -user axi_register_slice -tags "1040889" -to [get_pins -filter {REF_PIN_NAME=~CLR} -of_objects  [get_cells -hierarchical -regexp .*15.*_multi/.*/common.srl_fifo_0/asyncclear_.*]] -description {Waiving CDC-7, CDC between 2 known synchronous clock domains}
current_instance
current_instance axi_interconnect_0/m03_couplers/m03_regslice/inst
set_property src_info {type:SCOPED_XDC file:6 line:10 export:INPUT save:INPUT read:READ} [current_design]
create_waiver -internal -scope -type CDC -id CDC-7 -user axi_register_slice -tags "1040889" -to [get_pins -filter {REF_PIN_NAME=~CLR} -of_objects  [get_cells -hierarchical -regexp .*15.*_multi/.*/common.srl_fifo_0/asyncclear_.*]] -description {Waiving CDC-7, CDC between 2 known synchronous clock domains}
