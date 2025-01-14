onbreak {quit -f}
onerror {quit -f}

vsim -voptargs="+acc" -L xpm -L axi_lite_ipif_v3_0_4 -L lib_pkg_v1_0_2 -L fifo_generator_v13_2_5 -L lib_fifo_v1_0_14 -L axi_fifo_mm_s_v4_2_3 -L xil_defaultlib -L unisims_ver -L unimacro_ver -L secureip -lib xil_defaultlib xil_defaultlib.axi_fifo_mm_s_1 xil_defaultlib.glbl

do {wave.do}

view wave
view structure
view signals

do {axi_fifo_mm_s_1.udo}

run -all

quit -force
