/**
 * 
 * Autor: KH
 *
 * Opis:
 * Rysuje wynik jednocyfrowy w okreslonej pozycji na ekranie
 * Zmiany w czasie rzeczywistym
 */

module draw_digit #(
    parameter int X_POS = 0,
    parameter int Y_POS = 0
)(
    input  logic clk,
    input  logic rst,
    input  logic active,

    input  logic [3:0] value,   // 0-9

    vga_if.in  vga_in,
    vga_if.out vga_out
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [7:0]  char_xy_unused;
    logic [3:0]  char_line;
    logic [7:0]  font_pixels;
    logic [10:0] font_addr;
    logic [6:0]  char_code;

    assign char_code = 7'h30 + {3'b000, value};  // ASCII '0'..'9'
    assign font_addr = {char_code, char_line};

    font_rom u_font_rom (
        .clk(clk),
        .addr(font_addr),
        .char_line_pixels(font_pixels)
    );

    draw_rect_char #(
        .X_POS    (X_POS),
        .Y_POS    (Y_POS),
        .WIDTH_PX (8),
        .HEIGHT_PX(16)
    ) u_draw_char (
        .clk   (clk),
        .rst   (rst),
        .active(active),
        .vga_in (vga_in),
        .vga_out(vga_out),
        .char_xy(char_xy_unused),
        .char_line(char_line),
        .char_line_pixels(font_pixels)
    );

endmodule
