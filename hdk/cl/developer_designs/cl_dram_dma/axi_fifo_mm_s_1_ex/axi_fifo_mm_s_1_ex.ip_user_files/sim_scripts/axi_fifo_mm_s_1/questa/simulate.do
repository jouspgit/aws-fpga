onbreak {quit -f}
onerror {quit -f}

vsim -lib xil_defaultlib axi_fifo_mm_s_1_opt

do {wave.do}

view wave
view structure
view signals

do {axi_fifo_mm_s_1.udo}

run -all

quit -force
