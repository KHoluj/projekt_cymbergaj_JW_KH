/**
 * 
 * Autor: KH
 * 
 * Opis:
 * Rysuje wypelnione paletki w czasie rzeczywistym x/y pozycja
 * bramkowanie 'active'
 */

module draw_sprite #(
    parameter int WIDTH  = 20,
    parameter int HEIGHT = 20,
    parameter logic [11:0] FILL_COLOR   = 12'hF_F_F,
    parameter bit           DRAW_BORDER = 1'b1,
    parameter logic [11:0] BORDER_COLOR = 12'h0_0_0
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

    logic [10:0] hcount_d1, vcount_d1, hcount_d2, vcount_d2;
    logic hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
    logic hsync_d2, vsync_d2, hblnk_d2, vblnk_d2;
    logic [11:0] rgb_d1, rgb_d2;
    logic in_rect_d1, in_rect_d2;
    logic on_border_d1, on_border_d2;

    logic in_rect;
    logic on_border;

    assign in_rect = active &&
                      (vga_in.hcount >= x_pos) && (vga_in.hcount < x_pos + WIDTH) &&
                      (vga_in.vcount >= y_pos) && (vga_in.vcount < y_pos + HEIGHT);

    assign on_border = DRAW_BORDER && in_rect &&
                        ((vga_in.hcount == x_pos) || (vga_in.hcount == x_pos + WIDTH - 1) ||
                         (vga_in.vcount == y_pos) || (vga_in.vcount == y_pos + HEIGHT - 1));

    always_ff @(posedge clk) begin
        if (rst) begin
            hcount_d1 <= '0; vcount_d1 <= '0; hcount_d2 <= '0; vcount_d2 <= '0;
            hsync_d1  <= 0;  vsync_d1  <= 0;  hblnk_d1  <= 0;  vblnk_d1  <= 0;
            hsync_d2  <= 0;  vsync_d2  <= 0;  hblnk_d2  <= 0;  vblnk_d2  <= 0;
            rgb_d1    <= '0; rgb_d2    <= '0;
            in_rect_d1 <= 0; in_rect_d2 <= 0;
            on_border_d1 <= 0; on_border_d2 <= 0;
        end else begin
            hcount_d1 <= vga_in.hcount; vcount_d1 <= vga_in.vcount;
            hsync_d1  <= vga_in.hsync;  vsync_d1  <= vga_in.vsync;
            hblnk_d1  <= vga_in.hblnk;  vblnk_d1  <= vga_in.vblnk;
            rgb_d1    <= vga_in.rgb;
            in_rect_d1 <= in_rect;      on_border_d1 <= on_border;

            hcount_d2 <= hcount_d1; vcount_d2 <= vcount_d1;
            hsync_d2  <= hsync_d1;  vsync_d2  <= vsync_d1;
            hblnk_d2  <= hblnk_d1;  vblnk_d2  <= vblnk_d1;
            rgb_d2    <= rgb_d1;
            in_rect_d2 <= in_rect_d1;   on_border_d2 <= on_border_d1;
        end
    end

    assign vga_out.hcount = hcount_d2;
    assign vga_out.vcount = vcount_d2;
    assign vga_out.hsync  = hsync_d2;
    assign vga_out.vsync  = vsync_d2;
    assign vga_out.hblnk  = hblnk_d2;
    assign vga_out.vblnk  = vblnk_d2;

    always_comb begin
        if (!hblnk_d2 && !vblnk_d2 && in_rect_d2) begin
            vga_out.rgb = on_border_d2 ? BORDER_COLOR : FILL_COLOR;
        end else begin
            vga_out.rgb = rgb_d2;
        end
    end

endmodule
