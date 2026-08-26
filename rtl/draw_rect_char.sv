/**
 * 
 * Autor: KH
 * 
 * Opis:
 * Rysowanie przycisku napis
 */

module draw_rect_char #(
    parameter int X_POS = 64,
    parameter int Y_POS = 64,
    parameter int WIDTH_PX  = 256,
    parameter int HEIGHT_PX = 128
)(
    input  logic clk,
    input  logic rst,
    input  logic active,   // rysowanie gdy aktywny 'active'

    vga_if.in  vga_in,
    vga_if.out vga_out,

    output logic [7:0] char_xy,
    output logic [3:0] char_line,
    input  logic [7:0] char_line_pixels
);

    logic [10:0] local_x;
    logic [10:0] local_y;

    assign local_x = vga_in.hcount - X_POS;
    assign local_y = vga_in.vcount - Y_POS;

    
    assign char_xy   = {local_y[6:4], local_x[7:3]};
    assign char_line = local_y[3:0];

    logic in_rect;
    assign in_rect = active && (vga_in.hcount >= X_POS) && (vga_in.hcount < X_POS + WIDTH_PX) && (vga_in.vcount >= Y_POS) && (vga_in.vcount < Y_POS + HEIGHT_PX);

    logic [10:0] hcount_d1, vcount_d1, hcount_d2, vcount_d2;
    logic hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
    logic hsync_d2, vsync_d2, hblnk_d2, vblnk_d2;
    logic [11:0] rgb_d1, rgb_d2;
    logic in_rect_d1, in_rect_d2;

    always_ff @(posedge clk) begin
        if (rst) begin
            hsync_d1 <= 0; vsync_d1 <= 0; hblnk_d1 <= 0; vblnk_d1 <= 0; in_rect_d1 <= 0;
            hsync_d2 <= 0; vsync_d2 <= 0; hblnk_d2 <= 0; vblnk_d2 <= 0; in_rect_d2 <= 0;
        end else begin
            hcount_d1 <= vga_in.hcount; vcount_d1 <= vga_in.vcount;
            hsync_d1  <= vga_in.hsync;  vsync_d1  <= vga_in.vsync;
            hblnk_d1  <= vga_in.hblnk;  vblnk_d1  <= vga_in.vblnk;
            rgb_d1    <= vga_in.rgb;    in_rect_d1 <= in_rect;

            hcount_d2 <= hcount_d1; vcount_d2 <= vcount_d1;
            hsync_d2  <= hsync_d1;  vsync_d2  <= vsync_d1;
            hblnk_d2  <= hblnk_d1;  vblnk_d2  <= vblnk_d1;
            rgb_d2    <= rgb_d1;    in_rect_d2 <= in_rect_d1;
        end
    end

    logic [10:0] local_x_d2;
    logic [2:0] pixel_x;
    logic pixel_on;

    assign local_x_d2 = hcount_d2 - X_POS;

    assign pixel_x = local_x_d2[2:0];
    assign pixel_on = char_line_pixels[3'd7 - pixel_x];

    assign vga_out.hcount = hcount_d2;
    assign vga_out.vcount = vcount_d2;
    assign vga_out.hsync  = hsync_d2;
    assign vga_out.vsync  = vsync_d2;
    assign vga_out.hblnk  = hblnk_d2;
    assign vga_out.vblnk  = vblnk_d2;

    always_comb begin
        if (!vblnk_d2 && !hblnk_d2 && in_rect_d2 && pixel_on) begin
            vga_out.rgb = 12'hF8C;
        end else if (!vblnk_d2 && !hblnk_d2 && in_rect_d2 && !pixel_on) begin
            vga_out.rgb = 12'h000;
        end else begin
            vga_out.rgb = rgb_d2;
        end
    end

endmodule