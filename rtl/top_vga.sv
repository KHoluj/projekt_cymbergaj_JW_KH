/**
 * San Jose State University
 * EE178 Lab #4
 * Author: prof. Eric Crabilla
 *
 * Modified by:
 * 2025  AGH University of Science and Technology
 * MTM UEC2
 * Piotr Kaczmarczyk
 *
 * Description:
 * The project top module.
 */

module top_vga (
        input  logic clk,
        input  logic rst_n,
        input  logic clk100MHz,

        inout  logic ps2_clk,
        inout  logic ps2_data,

        output logic vs,
        output logic hs,
        output logic [3:0] r,
        output logic [3:0] g,
        output logic [3:0] b
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;

    /**
     * Local variables and signals
     */

    vga_if vga_tim_to_bg(); 
    vga_if vga_bg_to_rect(); 
    vga_if vga_rect_to_mouse();
    vga_if vga_out_final();
    vga_if vga_char_out();



     /**
     * Mouse raw input
     */

    logic [11:0] mouse_x;
    logic [11:0] mouse_y;
    logic mouse_left;


     /**
     * Mouse input synchronised
     */

    logic [11:0] mouse_x_sync1, mouse_x_sync2;
    logic [11:0] mouse_y_sync1, mouse_y_sync2;

     /**
     * Mouse input restricted to display
     */

     logic [11:0] mouse_x_restricted;
     logic [11:0] mouse_y_restricted;
     
     /**
     * Rect control
     */

     logic [11:0] rect_x_ctl;
     logic [11:0] rect_y_ctl;


    // VGA signals from timing
    wire [10:0] vcount_tim, hcount_tim;
    wire vsync_tim, hsync_tim;
    wire vblnk_tim, hblnk_tim;

    // VGA signals from background
    wire [10:0] vcount_bg, hcount_bg;
    wire vsync_bg, hsync_bg;
    wire vblnk_bg, hblnk_bg;
    wire [11:0] rgb_bg;

    //font_rom
    logic [10:0] font_addr;
    logic [7:0] font_pixels;

    logic [7:0] char_xy_sig;
    logic [3:0] char_line_sig;
    logic [6:0] char_code_sig; 



    /**
     * Signals assignments
     */

    // 1024x768@60 uses NEGATIVE sync polarity (pulse is active-low on the
    // pin), while every vga_if signal in the pipeline stays "1 = pulse
    // active" throughout -- so invert only here, at the final pin drive.
    assign vs = ~vga_out_final.vsync;
    assign hs = ~vga_out_final.hsync;
    assign {r, g, b} = vga_out_final.rgb;

    assign vga_tim_to_bg.rgb = 12'h0_0_0;

    assign font_addr = {char_code_sig, char_line_sig};



    MouseCtl u_mouse (
        .clk(clk100MHz),
        .rst(~rst_n),

        .ps2_clk(ps2_clk),
        .ps2_data(ps2_data),

        .xpos(mouse_x),
        .ypos(mouse_y),
        .left(mouse_left),

        .zpos(),
        .middle(),
        .right(),
        .new_event(),
        .value(),
        .setx(),
        .sety(),
        .setmax_x(),
        .setmax_y()
    );


    /**
     * Mouse sync
     */

    always_ff @(posedge clk) begin
        mouse_x_sync1 <= mouse_x;
        mouse_x_sync2 <= mouse_x_sync1;

        mouse_y_sync1 <= mouse_y;
        mouse_y_sync2 <= mouse_y_sync1;
    end

    /**
     * Mouse restriction
     */

    always_comb begin
        if (mouse_x_sync2 > 797)
            mouse_x_restricted = 797;
        else
            mouse_x_restricted = mouse_x_sync2;

        if (mouse_y_sync2 > 598)
            mouse_y_restricted = 598;
        else
            mouse_y_restricted = mouse_y_sync2;
    end

    /**
     * Submodules instances
     */



    vga_timing u_vga_timing (
        .clk,
        .rst_n,
        .vcount (vga_tim_to_bg.vcount),
        .vsync  (vga_tim_to_bg.vsync),
        .vblnk  (vga_tim_to_bg.vblnk),
        .hcount (vga_tim_to_bg.hcount),
        .hsync  (vga_tim_to_bg.hsync),
        .hblnk  (vga_tim_to_bg.hblnk)
    );

    draw_bg u_draw_bg (
        .clk,
        .rst_n,
        .vga_in (vga_tim_to_bg.in),
        .vga_out(vga_bg_to_rect.out)
    );

    draw_rect_ctl u_rect_ctl (
        .clk(clk),
        .rst_n(rst_n),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted),
        .mouse_left(mouse_left),

        .rect_x(rect_x_ctl),
        .rect_y(rect_y_ctl)
    );

    draw_rect u_draw_rect (
        .clk,
        .rst_n,
        .rect_x(rect_x_ctl),
        .rect_y(rect_y_ctl),
        .vga_in (vga_char_out.in),
        .vga_out(vga_rect_to_mouse.out)
    );


    draw_mouse u_draw_mouse (
    .clk(clk),
    .rst_n(rst_n),
    .vga_in(vga_rect_to_mouse.in),
    .vga_out(vga_out_final.out),

    .mouse_x(mouse_x_restricted),
    .mouse_y(mouse_y_restricted)
);

   font_rom u_font_rom (
    .clk(clk),
    .addr(font_addr),
    .char_line_pixels(font_pixels)
);

   draw_rect_char #(
    .X_POS(200),
    .Y_POS(150)
   ) u_draw_rect_char(
    .clk(clk),
    .rst(~rst_n),
    .vga_in(vga_bg_to_rect.in),
    .vga_out(vga_char_out.out),
    .char_xy(char_xy_sig),
    .char_line(char_line_sig),
    .char_line_pixels(font_pixels)
);
   
   char_rom u_rom(
    .clk(clk),
    .char_xy(char_xy_sig),
    .char_code(char_code_sig)
);


endmodule
