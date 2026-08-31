/**
 * 
 * Autor: JW
 *
 * Opis:
 * Rysuje wypelnione kolo w czasie rzeczywistym o pozycji x/y.
 * ten sam 2-cycle pipeline co draw_sprite/button
 */

module draw_circle #(
    parameter int DIAMETER = 40,
    parameter logic [11:0] FILL_COLOR    = 12'hF_F_F,
    parameter logic [11:0] HILIGHT_COLOR = 12'hF_F_F,
    parameter bit          USE_HILIGHT   = 1'b1
)(
    input  logic clk,
    input  logic rst,
    input  logic active,

    input  logic [11:0] x_pos,   
    input  logic [11:0] y_pos,

    vga_if.in  vga_in,
    vga_if.out vga_out
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int RADIUS       = DIAMETER/2;
    localparam int RADIUS_SQ    = RADIUS*RADIUS;
    localparam int HI_OFFSET    = RADIUS/3;
    localparam int HI_RADIUS    = RADIUS/3;
    localparam int HI_RADIUS_SQ = HI_RADIUS*HI_RADIUS;

    logic signed [12:0] dx, dy, hdx, hdy;
    logic [25:0] dist_sq, hi_dist_sq;
    logic in_circle, in_hilight;

    assign dx = $signed({1'b0, vga_in.hcount}) - $signed({1'b0, x_pos}) - RADIUS;
    assign dy = $signed({1'b0, vga_in.vcount}) - $signed({1'b0, y_pos}) - RADIUS;
    assign dist_sq = dx*dx + dy*dy;
    assign in_circle = active && (dist_sq <= RADIUS_SQ[25:0]);

    assign hdx = dx + HI_OFFSET;
    assign hdy = dy + HI_OFFSET;
    assign hi_dist_sq = hdx*hdx + hdy*hdy;
    assign in_hilight = USE_HILIGHT && in_circle && (hi_dist_sq <= HI_RADIUS_SQ[25:0]);

    logic [10:0] hcount_d1, vcount_d1, hcount_d2, vcount_d2;
    logic hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
    logic hsync_d2, vsync_d2, hblnk_d2, vblnk_d2;
    logic [11:0] rgb_d1, rgb_d2;
    logic in_circle_d1, in_circle_d2;
    logic in_hilight_d1, in_hilight_d2;

    always_ff @(posedge clk) begin
        if (rst) begin
            hcount_d1 <= '0; vcount_d1 <= '0; hcount_d2 <= '0; vcount_d2 <= '0;
            hsync_d1  <= 0;  vsync_d1  <= 0;  hblnk_d1  <= 0;  vblnk_d1  <= 0;
            hsync_d2  <= 0;  vsync_d2  <= 0;  hblnk_d2  <= 0;  vblnk_d2  <= 0;
            rgb_d1    <= '0; rgb_d2    <= '0;
            in_circle_d1  <= 0; in_circle_d2  <= 0;
            in_hilight_d1 <= 0; in_hilight_d2 <= 0;
        end else begin
            hcount_d1 <= vga_in.hcount; vcount_d1 <= vga_in.vcount;
            hsync_d1  <= vga_in.hsync;  vsync_d1  <= vga_in.vsync;
            hblnk_d1  <= vga_in.hblnk;  vblnk_d1  <= vga_in.vblnk;
            rgb_d1    <= vga_in.rgb;
            in_circle_d1  <= in_circle;  in_hilight_d1 <= in_hilight;

            hcount_d2 <= hcount_d1; vcount_d2 <= vcount_d1;
            hsync_d2  <= hsync_d1;  vsync_d2  <= vsync_d1;
            hblnk_d2  <= hblnk_d1;  vblnk_d2  <= vblnk_d1;
            rgb_d2    <= rgb_d1;
            in_circle_d2  <= in_circle_d1;  in_hilight_d2 <= in_hilight_d1;
        end
    end

    assign vga_out.hcount = hcount_d2;
    assign vga_out.vcount = vcount_d2;
    assign vga_out.hsync  = hsync_d2;
    assign vga_out.vsync  = vsync_d2;
    assign vga_out.hblnk  = hblnk_d2;
    assign vga_out.vblnk  = vblnk_d2;

    always_comb begin
        if (!hblnk_d2 && !vblnk_d2 && in_circle_d2) begin
            vga_out.rgb = in_hilight_d2 ? HILIGHT_COLOR : FILL_COLOR;
        end else begin
            vga_out.rgb = rgb_d2;
        end
    end

endmodule
