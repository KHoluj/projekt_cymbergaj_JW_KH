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

    localparam int BORDER_THICK = 6;
    localparam int POST_THICK   = 8;
    localparam int RING_THICK   = 3;
    localparam int LINE_THICK   = 2;   

    localparam logic [11:0] BG_COLOR      = 12'hF_F_F;  // kolor stolu
    localparam logic [11:0] BORDER_COLOR  = 12'h0_0_0;  // kolor lini bocznych
    localparam logic [11:0] LINE_COLOR    = 12'hF_0_0;  // czerwone linie
    localparam logic [11:0] GOAL_POST_COLOR = 12'hF_F_0;
    localparam logic [11:0] TEXTURE_COLOR = 12'hD_D_D;  

    logic in_table_bounds, in_table_x, in_table_y;
    logic on_left_edge, on_right_edge, on_top_edge, on_bottom_edge, in_goal_gap_y;
    logic on_border, on_goal_post;
    logic on_midline, on_left_line, on_right_line, on_faceoff_ring, on_center_dot, on_line;
    logic on_dot_texture, on_black;

    assign in_table_x = (vga_in.hcount >= TABLE_X0) && (vga_in.hcount < TABLE_X1);
    assign in_table_y = (vga_in.vcount >= TABLE_Y0) && (vga_in.vcount < TABLE_Y1);
    assign in_table_bounds = in_table_x && in_table_y;

    assign on_left_edge  = (vga_in.hcount >= TABLE_X0) && (vga_in.hcount < TABLE_X0 + BORDER_THICK);
    assign on_right_edge = (vga_in.hcount >= TABLE_X1 - BORDER_THICK) && (vga_in.hcount < TABLE_X1);
    assign on_top_edge    = (vga_in.vcount >= TABLE_Y0) && (vga_in.vcount < TABLE_Y0 + BORDER_THICK);
    assign on_bottom_edge = (vga_in.vcount >= TABLE_Y1 - BORDER_THICK) && (vga_in.vcount < TABLE_Y1);

    // Bramka
    assign in_goal_gap_y = (vga_in.vcount >= GOAL_Y0) && (vga_in.vcount < GOAL_Y1);

    assign on_border = active && (
        ((on_left_edge || on_right_edge) && in_table_y && !in_goal_gap_y) ||
        ((on_top_edge  || on_bottom_edge) && in_table_x)
    );

    
    assign on_goal_post = active && (on_left_edge || on_right_edge) && (
        (vga_in.vcount >= GOAL_Y0 - POST_THICK && vga_in.vcount < GOAL_Y0) ||
        (vga_in.vcount >= GOAL_Y1 && vga_in.vcount < GOAL_Y1 + POST_THICK)
    );

    assign on_black = active && (on_border || !in_table_bounds);

    logic in_active_bg;
    assign in_active_bg = active && in_table_bounds;

    // Czerwone linie
    assign on_midline    = active && (vga_in.hcount >= MID_X - LINE_THICK)        && (vga_in.hcount <= MID_X + LINE_THICK)        && in_table_y;
    assign on_left_line  = active && (vga_in.hcount >= LEFT_LINE_X - LINE_THICK)  && (vga_in.hcount <= LEFT_LINE_X + LINE_THICK)  && in_table_y;
    assign on_right_line = active && (vga_in.hcount >= RIGHT_LINE_X - LINE_THICK) && (vga_in.hcount <= RIGHT_LINE_X + LINE_THICK) && in_table_y;

    // Centralne kolo
    logic signed [12:0] cdx, cdy;
    logic [25:0] cdist_sq;
    localparam int FACEOFF_RADIUS_SQ       = CENTER_CIRCLE_RADIUS * CENTER_CIRCLE_RADIUS;
    localparam int FACEOFF_INNER_RADIUS    = CENTER_CIRCLE_RADIUS - RING_THICK;
    localparam int FACEOFF_INNER_RADIUS_SQ = FACEOFF_INNER_RADIUS * FACEOFF_INNER_RADIUS;
    localparam int CENTER_DOT_RADIUS_SQ    = CENTER_DOT_RADIUS * CENTER_DOT_RADIUS;

    assign cdx = $signed({1'b0, vga_in.hcount}) - MID_X;
    assign cdy = $signed({1'b0, vga_in.vcount}) - CENTER_Y;
    assign cdist_sq = cdx*cdx + cdy*cdy;

    assign on_faceoff_ring = active && (cdist_sq <= FACEOFF_RADIUS_SQ[25:0]) &&
                              (cdist_sq >= FACEOFF_INNER_RADIUS_SQ[25:0]);
    assign on_center_dot   = active && (cdist_sq <= CENTER_DOT_RADIUS_SQ[25:0]);

    assign on_line = on_midline || on_left_line || on_right_line || on_faceoff_ring || on_center_dot;

    
    assign on_dot_texture = active && (vga_in.hcount[4:0] == 5'd0) && (vga_in.vcount[4:0] == 5'd0);

    logic [10:0] hcount_d1, vcount_d1, hcount_d2, vcount_d2;
    logic hsync_d1, vsync_d1, hblnk_d1, vblnk_d1;
    logic hsync_d2, vsync_d2, hblnk_d2, vblnk_d2;
    logic [11:0] rgb_d1, rgb_d2;
    logic on_goal_post_d1, on_goal_post_d2;
    logic on_black_d1, on_black_d2;
    logic on_line_d1, on_line_d2;
    logic on_dot_texture_d1, on_dot_texture_d2;
    logic in_active_bg_d1, in_active_bg_d2;

    always_ff @(posedge clk) begin
        if (rst) begin
            hcount_d1 <= '0; vcount_d1 <= '0; hcount_d2 <= '0; vcount_d2 <= '0;
            hsync_d1  <= 0;  vsync_d1  <= 0;  hblnk_d1  <= 0;  vblnk_d1  <= 0;
            hsync_d2  <= 0;  vsync_d2  <= 0;  hblnk_d2  <= 0;  vblnk_d2  <= 0;
            rgb_d1    <= '0; rgb_d2    <= '0;
            on_goal_post_d1 <= 0; on_goal_post_d2 <= 0;
            on_black_d1 <= 0; on_black_d2 <= 0;
            on_line_d1 <= 0; on_line_d2 <= 0;
            on_dot_texture_d1 <= 0; on_dot_texture_d2 <= 0;
            in_active_bg_d1 <= 0; in_active_bg_d2 <= 0;
        end else begin
            hcount_d1 <= vga_in.hcount; vcount_d1 <= vga_in.vcount;
            hsync_d1  <= vga_in.hsync;  vsync_d1  <= vga_in.vsync;
            hblnk_d1  <= vga_in.hblnk;  vblnk_d1  <= vga_in.vblnk;
            rgb_d1    <= vga_in.rgb;
            on_goal_post_d1 <= on_goal_post;
            on_black_d1     <= on_black;
            on_line_d1      <= on_line;
            on_dot_texture_d1 <= on_dot_texture;
            in_active_bg_d1   <= in_active_bg;

            hcount_d2 <= hcount_d1; vcount_d2 <= vcount_d1;
            hsync_d2  <= hsync_d1;  vsync_d2  <= vsync_d1;
            hblnk_d2  <= hblnk_d1;  vblnk_d2  <= vblnk_d1;
            rgb_d2    <= rgb_d1;
            on_goal_post_d2 <= on_goal_post_d1;
            on_black_d2     <= on_black_d1;
            on_line_d2      <= on_line_d1;
            on_dot_texture_d2 <= on_dot_texture_d1;
            in_active_bg_d2   <= in_active_bg_d1;
        end
    end

    assign vga_out.hcount = hcount_d2;
    assign vga_out.vcount = vcount_d2;
    assign vga_out.hsync  = hsync_d2;
    assign vga_out.vsync  = vsync_d2;
    assign vga_out.hblnk  = hblnk_d2;
    assign vga_out.vblnk  = vblnk_d2;

    always_comb begin
        if (!hblnk_d2 && !vblnk_d2) begin
            if (on_goal_post_d2)
                vga_out.rgb = GOAL_POST_COLOR;
            else if (on_black_d2)
                vga_out.rgb = BORDER_COLOR;
            else if (on_line_d2)
                vga_out.rgb = LINE_COLOR;
            else if (on_dot_texture_d2)
                vga_out.rgb = TEXTURE_COLOR;
            else if (in_active_bg_d2)
                vga_out.rgb = BG_COLOR;
            else
                vga_out.rgb = rgb_d2;
        end else begin
            vga_out.rgb = rgb_d2;
        end
    end

endmodule
