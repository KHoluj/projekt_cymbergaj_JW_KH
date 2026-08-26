# Copyright (C) 2025  AGH University of Science and Technology
# MTM UEC2
# Author: Piotr Kaczmarczyk
#
# Description:
# Project detiles required for generate_bitstream.tcl
# Make sure that project_name, top_module and target are correct.
# Provide paths to all the files required for synthesis and implementation.
# Depending on the file type, it should be added in the corresponding section.
# If the project does not use files of some type, leave the corresponding section commented out.

#-----------------------------------------------------#
#                   Project details                   #
#-----------------------------------------------------#
# Project name                                  -- EDIT
set project_name airhockey_project

# Top module name                               -- EDIT
set top_module top_airhockey_basys3

# FPGA device
set target xc7a35tcpg236-1

#-----------------------------------------------------#
#                    Design sources                   #
#-----------------------------------------------------#
# Specify .xdc files location                   -- EDIT
set xdc_files {
    constraints/top_airhockey_basys3.xdc
    constraints/clk_wiz_0.xdc
    constraints/clk_wiz_0_late.xdc
    constraints/top_airhockey_basys3.xdc
}

# Specify SystemVerilog design files location   -- EDIT
set sv_files {
    ../rtl/comm/link_rx_ctl.sv
    ../rtl/comm/link_tx_ctl.sv 
    ../rtl/comm/uart_rx.sv 
    ../rtl/comm/uart_tx.sv 

    ../rtl/common/btn_edge.sv
    ../rtl/common/rst_ctl.sv

    ../rtl/draw/char_rom.sv
    ../rtl/draw/draw_bg.sv
    ../rtl/draw/draw_button.sv
    ../rtl/draw/draw_circle.sv
    ../rtl/draw/draw_digit.sv
    ../rtl/draw/draw_menu_bg.sv
    ../rtl/draw/draw_mouse.sv
    ../rtl/draw/draw_rect_char.sv
    ../rtl/draw/draw_rink.sv
    ../rtl/draw/font_rom.sv

    
    ../rtl/game/game_fsm.sv
    ../rtl/game/game_pkg.sv
    ../rtl/game/menu_ctl.sv
    ../rtl/game/paddle_ctl.sv
    ../rtl/game/paddle2_ai.sv
    ../rtl/game/puck_ctl.sv
    ../rtl/game/score_ctl.sv
    ../rtl/game/settings_ctl.sv


    ../rtl/vga/frame_tick_gen.sv
    ../rtl/vga/vga_if.sv
    ../rtl/vga/vga_pkg.sv
    ../rtl/vga/vga_timing.sv
    
    ../rtl/top_airhockey.sv

    rtl/top_airhockey_basys3.sv
}

# Specify Verilog design files location         -- EDIT
 set verilog_files {
     ../fpga/rtl/clk_wiz_0.v
     ../fpga/rtl/clk_wiz_0_clk_wiz.v
 }

# Specify VHDL design files location            -- EDIT
 set vhdl_files {
    ../fpga/rtl/MouseCtl.vhd
    ../fpga/rtl/MouseDisplay.vhd
    ../fpga/rtl/Ps2Interface.vhd
 }

# Specify files for a memory initialization     -- EDIT
# set mem_files {
#}
