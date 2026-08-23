/**
 * 
 * Autor: JW
 * 
 * Opis:
 * Wizualna dekoracja pola do gry, ograniczenie stolu
 * wraz z nieprzekraczalna linia na srodku
 * otwarte linie, placeholder na bramke, czysta
 * indykacja goal
 */

module draw_rink
    import game_pkg::*;
(
    input  logic clk,
    input  logic rst,
    input  logic active,

    vga_if.in  vga_in,
    vga_if.out vga_out
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int BORDER_THICK = 4;
    localparam logic [11:0] RINK_COLOR      = 12'hC_C_C;
    localparam logic [11:0] GOAL_MARK_COLOR = 12'hF_F_0;

    logic on_left_edge, on_right_edge, on_top_edge, on_bottom_edge;
    logic on_border, on_midline, on_goal_mark;

    assign on_left_edge  = (vga_in.hcount >= TABLE_X0) && (vga_in.hcount < TABLE_X0 + BORDER_THICK);
    assign on_right_edge = (vga_in.hcount >= TABLE_X1 - BORDER_THICK) && (vga_in.hcount < TABLE_X1);
    assign on_top_edge    = (vga_in.vcount >= TABLE_Y0) && (vga_in.vcount < TABLE_Y0 + BORDER_THICK);
    assign on_bottom_edge = (vga_in.vcount >= TABLE_Y1 - BORDER_THICK) && (vga_in.vcount < TABLE_Y1);

    logic in_table_x, in_table_y;
    assign in_table_x = (vga_in.hcount >= TABLE_X0) && (vga_in.hcount < TABLE_X1);
    assign in_table_y = (vga_in.vcount >= TABLE_Y0) && (vga_in.vcount < TABLE_Y1);

    assign on_border = active && (
        ((on_left_edge || on_right_edge) && in_table_y) ||
        ((on_top_edge  || on_bottom_edge) && in_table_x)
    );

    assign on_midline = active &&
                         (vga_in.hcount >= MID_X - 1) && (vga_in.hcount <= MID_X + 1) &&
                         in_table_y;

    assign on_goal_mark = active &&
                           (on_left_edge || on_right_edge) &&
                           (vga_in.vcount >= GOAL_Y0) && (vga_in.vcount < GOAL_Y1);

    logic [10:0] hcount_d1, vcount_d1, hcount_d2, vcount_d2;
    logic hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
    logic hsync_d2, vsync_d2, hblnk_d2, vblnk_d2;
    logic [11:0] rgb_d1, rgb_d2;
    logic on_border_d1, on_border_d2;
    logic on_midline_d1, on_midline_d2;
    logic on_goal_mark_d1, on_goal_mark_d2;

    always_ff @(posedge clk) begin
        if (rst) begin
            hcount_d1 <= '0; vcount_d1 <= '0; hcount_d2 <= '0; vcount_d2 <= '0;
            hsync_d1  <= 0;  vsync_d1  <= 0;  hblnk_d1  <= 0;  vblnk_d1  <= 0;
            hsync_d2  <= 0;  vsync_d2  <= 0;  hblnk_d2  <= 0;  vblnk_d2  <= 0;
            rgb_d1    <= '0; rgb_d2    <= '0;
            on_border_d1 <= 0; on_border_d2 <= 0;
            on_midline_d1 <= 0; on_midline_d2 <= 0;
            on_goal_mark_d1 <= 0; on_goal_mark_d2 <= 0;
        end else begin
            hcount_d1 <= vga_in.hcount; vcount_d1 <= vga_in.vcount;
            hsync_d1  <= vga_in.hsync;  vsync_d1  <= vga_in.vsync;
            hblnk_d1  <= vga_in.hblnk;  vblnk_d1  <= vga_in.vblnk;
            rgb_d1    <= vga_in.rgb;
            on_border_d1 <= on_border; on_midline_d1 <= on_midline; on_goal_mark_d1 <= on_goal_mark;

            hcount_d2 <= hcount_d1; vcount_d2 <= vcount_d1;
            hsync_d2  <= hsync_d1;  vsync_d2  <= vsync_d1;
            hblnk_d2  <= hblnk_d1;  vblnk_d2  <= vblnk_d1;
            rgb_d2    <= rgb_d1;
            on_border_d2 <= on_border_d1; on_midline_d2 <= on_midline_d1; on_goal_mark_d2 <= on_goal_mark_d1;
        end
    end

    assign vga_out.hcount = hcount_d2;
    assign vga_out.vcount = vcount_d2;
    assign vga_out.hsync  = hsync_d2;
    assign vga_out.vsync  = vsync_d2;
    assign vga_out.hblnk  = hblnk_d2;
    assign vga_out.vblnk  = vblnk_d2;

    always_comb begin
        if (!hblnk_d2 && !vblnk_d2 && on_goal_mark_d2) begin
            vga_out.rgb = GOAL_MARK_COLOR;
        end else if (!hblnk_d2 && !vblnk_d2 && (on_border_d2 || on_midline_d2)) begin
            vga_out.rgb = RINK_COLOR;
        end else begin
            vga_out.rgb = rgb_d2;
        end
    end

endmodule
