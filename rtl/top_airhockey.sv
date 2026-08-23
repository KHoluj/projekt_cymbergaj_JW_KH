/**
 * 
 * Autor: KH
 *
 * Opis:
 * Modul top gry cymbergaj
 * Wersja na jednego gracza i AI placeholder
 */

module top_airhockey
    import game_pkg::*;
    import vga_pkg::*;
(
        input  logic clk,          // 65 MHz VGA pixel clock (1024x768@60)
        input  logic clk100MHz,    // 100 MHz, used by the PS/2 mouse core
        input  logic btn_rst,      

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

    /**
     * Reset
     */

    logic rst;     
    logic rst_n;   // zachowane poniewaz nie zostaly jeszcze usuniete wszystkie pliki z labu

    rst_ctl u_rst_ctl (
        .clk(clk),
        .btn_rst(btn_rst),
        .rst(rst)
    );

    assign rst_n = ~rst;

    /**
     * Game state
     */

    game_state_t game_state;
    logic play_active;
    logic menu_active;

    assign play_active = (game_state == ST_PLAY);
    assign menu_active = (game_state == ST_MENU);

    /**
     * VGA pipeline interfaces
     */

    vga_if vga_tim_to_bg();
    vga_if vga_bg_to_p1();
    vga_if vga_p1_to_p2();
    vga_if vga_p2_to_puck();
    vga_if vga_puck_to_s1t();
    vga_if vga_s1t_to_s1o();
    vga_if vga_s1o_to_s2t();
    vga_if vga_s2t_to_s2o();
    vga_if vga_s2o_to_btn();
    vga_if vga_btn_to_title();
    vga_if vga_title_to_label();
    vga_if vga_label_to_mouse();
    vga_if vga_out_final();

    assign vga_tim_to_bg.rgb = 12'h0_0_0;

    
    assign vs = ~vga_out_final.vsync;
    assign hs = ~vga_out_final.hsync;
    assign {r, g, b} = vga_out_final.rgb;

    /**
     * Per-frame tick (~60 Hz), fizyka paletka clamp/AI/krazek 
     */

    logic frame_tick;

    frame_tick_gen u_frame_tick_gen (
        .clk(clk),
        .rst(rst),
        .vsync(vga_tim_to_bg.vsync),
        .frame_tick(frame_tick)
    );

    /**
     * Mouse raw + synchronised + screen-restricted
     */

    logic [11:0] mouse_x, mouse_y;
    logic mouse_left;

    logic [11:0] mouse_x_sync1, mouse_x_sync2;
    logic [11:0] mouse_y_sync1, mouse_y_sync2;
    logic [11:0] mouse_x_restricted, mouse_y_restricted;

    MouseCtl u_mouse (
        .clk(clk100MHz),
        .rst(rst),

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

    always_ff @(posedge clk) begin
        mouse_x_sync1 <= mouse_x;
        mouse_x_sync2 <= mouse_x_sync1;

        mouse_y_sync1 <= mouse_y;
        mouse_y_sync2 <= mouse_y_sync1;
    end

    always_comb begin
        if (mouse_x_sync2 > HOR_PIXELS - 3)
            mouse_x_restricted = HOR_PIXELS - 3;
        else
            mouse_x_restricted = mouse_x_sync2;

        if (mouse_y_sync2 > VER_PIXELS - 2)
            mouse_y_restricted = VER_PIXELS - 2;
        else
            mouse_y_restricted = mouse_y_sync2;
    end

    /**
     * Menu: przycisk + top-level FSM
     */

    logic btn_hover, btn_click;

    menu_ctl #(
        .BTN_X(BTN_X),
        .BTN_Y(BTN_Y),
        .BTN_W(BTN_W),
        .BTN_H(BTN_H)
    ) u_menu_ctl (
        .clk(clk),
        .rst(rst),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted),
        .mouse_left(mouse_left),
        .hover(btn_hover),
        .click_pulse(btn_click)
    );

    game_fsm u_game_fsm (
        .clk(clk),
        .rst(rst),
        .start_click(btn_click),
        .game_state(game_state)
    );

    /**
     * Paletka gracza 1 porusza sie za pomoca myszy po lewej stronie
     */

    logic [11:0] p1_x, p1_y;

    paddle_ctl #(
        .MIN_X(P1_MIN_X),
        .MAX_X(P1_MAX_X),
        .MIN_Y(PADDLE_MIN_Y),
        .MAX_Y(PADDLE_MAX_Y)
    ) u_paddle1_ctl (
        .clk(clk),
        .rst(rst),
        .in_x(mouse_x_restricted),
        .in_y(mouse_y_restricted),
        .paddle_x(p1_x),
        .paddle_y(p1_y)
    );

    

    logic [11:0] puck_x, puck_y;

    /**
     * Gracz 2: placeholder AI
     */

    logic [11:0] p2_x, p2_y;

    paddle2_ai u_paddle2_ai (
        .clk(clk),
        .rst(rst),
        .frame_tick(frame_tick),
        .puck_y(puck_y),
        .ai_x(p2_x),
        .ai_y(p2_y)
    );

    /**
     * Fizyka krazka i wynik
     */

    logic goal_p1, goal_p2;
    logic [3:0] score_p1_tens, score_p1_ones, score_p2_tens, score_p2_ones;

    puck_ctl u_puck_ctl (
        .clk(clk),
        .rst(rst),
        .frame_tick(frame_tick),
        .active(play_active),
        .p1_x(p1_x), .p1_y(p1_y),
        .p2_x(p2_x), .p2_y(p2_y),
        .puck_x(puck_x), .puck_y(puck_y),
        .goal_p1(goal_p1),
        .goal_p2(goal_p2)
    );

    score_ctl u_score_ctl (
        .clk(clk),
        .rst(rst),
        .goal_p1(goal_p1),
        .goal_p2(goal_p2),
        .score_p1_tens(score_p1_tens),
        .score_p1_ones(score_p1_ones),
        .score_p2_tens(score_p2_tens),
        .score_p2_ones(score_p2_ones)
    );

    /**
     * Text ROMs: tytul ("AIR HOCKEY") napis przycisku ("START")
     */

    logic [10:0] title_font_addr, label_font_addr;
    logic [7:0]  title_font_pixels, label_font_pixels;
    logic [7:0]  title_char_xy, label_char_xy;
    logic [3:0]  title_char_line, label_char_line;
    logic [6:0]  title_char_code, label_char_code;

    assign title_font_addr = {title_char_code, title_char_line};
    assign label_font_addr = {label_char_code, label_char_line};

    /**
     * Submodules
     */

    vga_timing u_vga_timing (
        .clk    (clk),
        .rst_n  (rst_n),
        .vcount (vga_tim_to_bg.vcount),
        .vsync  (vga_tim_to_bg.vsync),
        .vblnk  (vga_tim_to_bg.vblnk),
        .hcount (vga_tim_to_bg.hcount),
        .hsync  (vga_tim_to_bg.hsync),
        .hblnk  (vga_tim_to_bg.hblnk)
    );

    draw_bg u_draw_bg (
        .clk    (clk),
        .rst_n  (rst_n),
        .vga_in (vga_tim_to_bg.in),
        .vga_out(vga_bg_to_p1.out)
    );

    draw_sprite #(
        .WIDTH (PADDLE_W),
        .HEIGHT(PADDLE_H),
        .FILL_COLOR(PADDLE1_COLOR)
    ) u_draw_p1 (
        .clk(clk), .rst(rst),
        .active(play_active),
        .x_pos(p1_x), .y_pos(p1_y),
        .vga_in (vga_bg_to_p1.in),
        .vga_out(vga_p1_to_p2.out)
    );

    draw_sprite #(
        .WIDTH (PADDLE_W),
        .HEIGHT(PADDLE_H),
        .FILL_COLOR(PADDLE2_COLOR)
    ) u_draw_p2 (
        .clk(clk), .rst(rst),
        .active(play_active),
        .x_pos(p2_x), .y_pos(p2_y),
        .vga_in (vga_p1_to_p2.in),
        .vga_out(vga_p2_to_puck.out)
    );

    draw_sprite #(
        .WIDTH (PUCK_SIZE),
        .HEIGHT(PUCK_SIZE),
        .FILL_COLOR(PUCK_COLOR),
        .DRAW_BORDER(1'b0)
    ) u_draw_puck (
        .clk(clk), .rst(rst),
        .active(play_active),
        .x_pos(puck_x), .y_pos(puck_y),
        .vga_in (vga_p2_to_puck.in),
        .vga_out(vga_puck_to_s1t.out)
    );

    draw_digit #(
        .X_POS(SCORE1_TENS_X),
        .Y_POS(SCORE_Y)
    ) u_draw_score1_tens (
        .clk(clk), .rst(rst),
        .active(play_active),
        .value(score_p1_tens),
        .vga_in (vga_puck_to_s1t.in),
        .vga_out(vga_s1t_to_s1o.out)
    );

    draw_digit #(
        .X_POS(SCORE1_ONES_X),
        .Y_POS(SCORE_Y)
    ) u_draw_score1_ones (
        .clk(clk), .rst(rst),
        .active(play_active),
        .value(score_p1_ones),
        .vga_in (vga_s1t_to_s1o.in),
        .vga_out(vga_s1o_to_s2t.out)
    );

    draw_digit #(
        .X_POS(SCORE2_TENS_X),
        .Y_POS(SCORE_Y)
    ) u_draw_score2_tens (
        .clk(clk), .rst(rst),
        .active(play_active),
        .value(score_p2_tens),
        .vga_in (vga_s1o_to_s2t.in),
        .vga_out(vga_s2t_to_s2o.out)
    );

    draw_digit #(
        .X_POS(SCORE2_ONES_X),
        .Y_POS(SCORE_Y)
    ) u_draw_score2_ones (
        .clk(clk), .rst(rst),
        .active(play_active),
        .value(score_p2_ones),
        .vga_in (vga_s2t_to_s2o.in),
        .vga_out(vga_s2o_to_btn.out)
    );

    draw_button #(
        .X_POS       (BTN_X),
        .Y_POS       (BTN_Y),
        .WIDTH       (BTN_W),
        .HEIGHT      (BTN_H),
        .FILL_COLOR  (BTN_FILL_COLOR),
        .BORDER_COLOR(BTN_BORDER_COLOR)
    ) u_draw_button (
        .clk    (clk),
        .rst    (rst),
        .active (menu_active),
        .vga_in (vga_s2o_to_btn.in),
        .vga_out(vga_btn_to_title.out)
    );

    font_rom u_font_rom_title (
        .clk(clk),
        .addr(title_font_addr),
        .char_line_pixels(title_font_pixels)
    );

    char_rom #(
        .TEXT({
            "                                ",
            "                                ",
            "          AIR HOCKEY            ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_title (
        .clk(clk),
        .char_xy(title_char_xy),
        .char_code(title_char_code)
    );

    draw_rect_char #(
        .X_POS(TITLE_X),
        .Y_POS(TITLE_Y)
    ) u_draw_title (
        .clk   (clk),
        .rst   (rst),
        .active(menu_active),
        .vga_in (vga_btn_to_title.in),
        .vga_out(vga_title_to_label.out),
        .char_xy(title_char_xy),
        .char_line(title_char_line),
        .char_line_pixels(title_font_pixels)
    );

    font_rom u_font_rom_label (
        .clk(clk),
        .addr(label_font_addr),
        .char_line_pixels(label_font_pixels)
    );

    char_rom #(
        .TEXT({
            "START                           ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_label (
        .clk(clk),
        .char_xy(label_char_xy),
        .char_code(label_char_code)
    );

    draw_rect_char #(
        .X_POS    (BTN_LABEL_X),
        .Y_POS    (BTN_LABEL_Y),
        .WIDTH_PX (BTN_LABEL_W),
        .HEIGHT_PX(BTN_LABEL_H)
    ) u_draw_label (
        .clk   (clk),
        .rst   (rst),
        .active(menu_active),
        .vga_in (vga_title_to_label.in),
        .vga_out(vga_label_to_mouse.out),
        .char_xy(label_char_xy),
        .char_line(label_char_line),
        .char_line_pixels(label_font_pixels)
    );

    draw_mouse u_draw_mouse (
        .clk   (clk),
        .rst_n (rst_n),
        .active(menu_active),
        .vga_in(vga_label_to_mouse.in),
        .vga_out(vga_out_final.out),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted)
    );

endmodule
