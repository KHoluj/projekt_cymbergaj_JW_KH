/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Draw background.
 */


 module draw_bg (
    input  logic clk,
    input  logic rst_n,

    vga_if.in   vga_in,
    vga_if.out  vga_out
);

timeunit 1ns;
timeprecision 1ps;

import vga_pkg::*;

/**
 * Local variables and signals
 */
logic [11:0] rgb_nxt;

logic [3:0] grad_r;
logic [3:0] grad_b;

assign grad_r = 4'h4 + vga_in.vcount[9:6]; 
assign grad_b = 4'hF - vga_in.vcount[9:7]; 

/**
 * Internal logic
 */
always_ff @(posedge clk or negedge rst_n) begin : bg_ff_blk
    if (!rst_n) begin
        vga_out.vcount <= '0;
        vga_out.vsync  <= '0;
        vga_out.vblnk  <= '0;
        vga_out.hcount <= '0;
        vga_out.hsync  <= '0;
        vga_out.hblnk  <= '0;
        vga_out.rgb    <= '0;
    end else begin
        vga_out.vcount <= vga_in.vcount;
        vga_out.vsync  <= vga_in.vsync;
        vga_out.vblnk  <= vga_in.vblnk;
        vga_out.hcount <= vga_in.hcount;
        vga_out.hsync  <= vga_in.hsync;
        vga_out.hblnk  <= vga_in.hblnk;
        vga_out.rgb    <= rgb_nxt;
    end
end

always_comb begin : bg_comb_blk
    if (vga_in.vblnk || vga_in.hblnk) begin             // Blanking region:
        rgb_nxt = 12'h0_0_0;                            // - make it black.
    end else begin                                      // Active region:
        if (vga_in.vcount == 0)                         // - top edge:
            rgb_nxt = 12'hf_f_0;                        // - - make a yellow line.
        else if (vga_in.vcount == VER_PIXELS - 1)       // - bottom edge:
            rgb_nxt = 12'hf_0_0;                        // - - make a red line.
        else if (vga_in.hcount == 0)                    // - left edge:
            rgb_nxt = 12'h0_f_0;                        // - - make a green line.
        else if (vga_in.hcount == HOR_PIXELS - 1)       // - right edge:
            rgb_nxt = 12'h0_0_f;                        // - - make a blue line.

        else if ((vga_in.hcount >= 50 && vga_in.hcount <= 80 && vga_in.vcount >= 200 && vga_in.vcount <= 400) ||
             (vga_in.hcount >= 80 && vga_in.hcount <= 180 && vga_in.vcount >= 200 && vga_in.vcount <= 300 && (vga_in.hcount + vga_in.vcount >= 360 && vga_in.hcount + vga_in.vcount <= 400)) ||
             (vga_in.hcount >= 80 && vga_in.hcount <= 180 && vga_in.vcount >= 300 && vga_in.vcount <= 400 && (vga_in.vcount - vga_in.hcount >= 200 && vga_in.vcount - vga_in.hcount <= 240)))
        rgb_nxt = 12'h3_F_9; //K
        
        else if ((vga_in.hcount >= 220 && vga_in.hcount <= 250 && vga_in.vcount >= 200 && vga_in.vcount <= 400) ||
             (vga_in.hcount >= 250 && vga_in.hcount <= 310 && vga_in.vcount >= 285 && vga_in.vcount <= 315) ||
             (vga_in.hcount >= 310 && vga_in.hcount <= 340 && vga_in.vcount >= 200 && vga_in.vcount <= 400))
        rgb_nxt = 12'hC_6_0; //H

        else if ((vga_in.hcount >= 460 && vga_in.hcount <= 490 && vga_in.vcount >= 370 && vga_in.vcount <= 400) ||
             (vga_in.hcount >= 430 && vga_in.hcount <= 460 && vga_in.vcount >= 340 && vga_in.vcount <= 400) ||
             (vga_in.hcount >= 490 && vga_in.hcount <= 520 && vga_in.vcount >= 200 && vga_in.vcount <= 400))
        rgb_nxt = 12'hC_6_0; //J

        else if (
             (vga_in.hcount >= 580 && vga_in.hcount <= 610 && vga_in.vcount >= 200 && vga_in.vcount <= 400) || 
             (vga_in.hcount >= 710 && vga_in.hcount <= 740 && vga_in.vcount >= 200 && vga_in.vcount <= 400) || 
             (vga_in.hcount >= 610 && vga_in.hcount <= 660 && vga_in.vcount >= 300 && vga_in.vcount <= 400 && (vga_in.hcount + vga_in.vcount >= 960 && vga_in.hcount + vga_in.vcount <= 1010)) ||
             (vga_in.hcount >= 660 && vga_in.hcount <= 710 && vga_in.vcount >= 300 && vga_in.vcount <= 400 && (vga_in.vcount - vga_in.hcount >= -370 && vga_in.vcount - vga_in.hcount <= -310))
        )
        rgb_nxt = 12'h3_F_9; //W
        
        else begin 
            rgb_nxt = {grad_r, 4'h0, grad_b}; 
        end
    end
end

endmodule
