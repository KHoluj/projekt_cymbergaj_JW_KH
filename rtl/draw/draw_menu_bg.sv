/**
 * 
 * Autor: KH
 *
 * Opis:
 * Gradient od gory do dolu w menu i ustawieniach
 */

module draw_menu_bg (
    input  logic clk,
    input  logic rst,
    input  logic active,

    vga_if.in  vga_in,
    vga_if.out vga_out
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [11:0] grad_rgb;
    logic [3:0] grad_b, grad_g;

    assign grad_b = 4'd3 + vga_in.vcount[9:6];
    assign grad_g = {1'b0, vga_in.vcount[9:7]};
    assign grad_rgb = {4'd0, grad_g, grad_b};

    logic [10:0] hcount_d1, vcount_d1, hcount_d2, vcount_d2;
    logic hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
    logic hsync_d2, vsync_d2, hblnk_d2, vblnk_d2;
    logic [11:0] rgb_d1, rgb_d2;
    logic [11:0] grad_rgb_d1, grad_rgb_d2;
    logic active_d1, active_d2;

    always_ff @(posedge clk) begin
        if (rst) begin
            hcount_d1 <= '0; vcount_d1 <= '0; hcount_d2 <= '0; vcount_d2 <= '0;
            hsync_d1  <= 0;  vsync_d1  <= 0;  hblnk_d1  <= 0;  vblnk_d1  <= 0;
            hsync_d2  <= 0;  vsync_d2  <= 0;  hblnk_d2  <= 0;  vblnk_d2  <= 0;
            rgb_d1    <= '0; rgb_d2    <= '0;
            grad_rgb_d1 <= '0; grad_rgb_d2 <= '0;
            active_d1 <= 0; active_d2 <= 0;
        end else begin
            hcount_d1 <= vga_in.hcount; vcount_d1 <= vga_in.vcount;
            hsync_d1  <= vga_in.hsync;  vsync_d1  <= vga_in.vsync;
            hblnk_d1  <= vga_in.hblnk;  vblnk_d1  <= vga_in.vblnk;
            rgb_d1    <= vga_in.rgb;
            grad_rgb_d1 <= grad_rgb;
            active_d1 <= active;

            hcount_d2 <= hcount_d1; vcount_d2 <= vcount_d1;
            hsync_d2  <= hsync_d1;  vsync_d2  <= vsync_d1;
            hblnk_d2  <= hblnk_d1;  vblnk_d2  <= vblnk_d1;
            rgb_d2    <= rgb_d1;
            grad_rgb_d2 <= grad_rgb_d1;
            active_d2 <= active_d1;
        end
    end

    assign vga_out.hcount = hcount_d2;
    assign vga_out.vcount = vcount_d2;
    assign vga_out.hsync  = hsync_d2;
    assign vga_out.vsync  = vsync_d2;
    assign vga_out.hblnk  = hblnk_d2;
    assign vga_out.vblnk  = vblnk_d2;

    always_comb begin
        if (!hblnk_d2 && !vblnk_d2 && active_d2) begin
            vga_out.rgb = grad_rgb_d2;
        end else begin
            vga_out.rgb = rgb_d2;
        end
    end

endmodule
