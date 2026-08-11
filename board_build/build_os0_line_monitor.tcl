open_project "os0_line_monitor.gprj"
# Always build the SoC top, never an auxiliary renderer module.
set_option -top_module top_pipeline
# Verified Runtime Emerald panel build: release pins 55/56 from SSPI so they
# can drive LCD green bits G[5:4].
set_option -use_sspi_as_gpio 1
run all
run close
