/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2 - Air Hockey Project
 *
 * Description:
 * Draws the mouse cursor overlay. Gated by 'active' so the cursor
 * can be hidden during gameplay (it would otherwise sit drawn right
 * on top of the paddle it's controlling) and shown only in the menu.
 */

module draw_mouse (
    input  logic clk,
    input  logic rst_n,
    input  logic active,   // draw the cursor only when high; passthrough otherwise

    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,

    vga_if.in  vga_in,
    vga_if.out vga_out
);

    logic [11:0] rgb_mouse;
    logic blank;

   
    assign blank = vga_in.hblnk | vga_in.vblnk;

    MouseDisplay u_mouse_display (
        .pixel_clk(clk),
        .xpos(mouse_x),
        .ypos(mouse_y),
        .hcount(vga_in.hcount),
        .vcount(vga_in.vcount),

        .blank(blank),          
        .rgb_in(vga_in.rgb),    

        .enable_mouse_display_out(), 
        .rgb_out(rgb_mouse)
    );

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vga_out.vcount <= 0;
            vga_out.hcount <= 0;
            vga_out.vsync  <= 0;
            vga_out.hsync  <= 0;
            vga_out.vblnk  <= 0;
            vga_out.hblnk  <= 0;
            vga_out.rgb    <= 0;
        end else begin
            
            vga_out.vcount <= vga_in.vcount;
            vga_out.hcount <= vga_in.hcount;
            vga_out.vsync  <= vga_in.vsync;
            vga_out.hsync  <= vga_in.hsync;
            vga_out.vblnk  <= vga_in.vblnk;
            vga_out.hblnk  <= vga_in.hblnk;

            vga_out.rgb <= active ? rgb_mouse : vga_in.rgb;
        end
    end

endmodule
