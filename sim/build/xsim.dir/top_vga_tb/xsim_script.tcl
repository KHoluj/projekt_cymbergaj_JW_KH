set_param project.enableReportConfiguration 0
load_feature core
current_fileset
xsim {top_vga_tb} -autoloadwcfg -tclbatch {/home/student/jwojciechowska/uec2/lab5/tools/sim_cmd.tcl}
