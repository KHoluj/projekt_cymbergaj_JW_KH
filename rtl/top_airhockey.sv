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
    logic winner_p2;
    logic score_clear;

    logic play_active;
    logic menu_active;
    logic game_over_active;

    assign play_active      = (game_state == ST_PLAY);
    assign menu_active      = (game_state == ST_MENU);
    assign game_over_active = (game_state == ST_GAME_OVER);

    /**
     * Paletki, krazek, wynik - sygnaly deklarowane zawczasu razem
     */

    logic [11:0] p1_x, p1_y;
    logic [11:0] p2_x, p2_y;
    logic [11:0] puck_x, puck_y;
    logic goal_p1, goal_p2;
    logic [3:0] score_p1_tens, score_p1_ones, score_p2_tens, score_p2_ones;

    /**
     * VGA pipeline interfaces
     */

    vga_if vga_tim_to_bg();
    vga_if vga_bg_to_rink();
    vga_if vga_rink_to_p1();
    vga_if vga_p1_to_p2();
    vga_if vga_p2_to_puck();
    vga_if vga_puck_to_s1t();
    vga_if vga_s1t_to_s1o();
    vga_if vga_s1o_to_s2t();
    vga_if vga_s2t_to_s2o();
    vga_if vga_s2o_to_btn();
    vga_if vga_btn_to_title();
    vga_if vga_title_to_label();
    vga_if vga_label_to_exitbtn();
    vga_if vga_exitbtn_to_exitlabel();
    vga_if vga_exitlabel_to_mouse();
    vga_if vga_out_final();

    assign vga_tim_to_bg.rgb = 12'h0_0_0;

    // 1024x768@60 uzywa NEGATIVE polarnosci syncu
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
     * Menu/Start: przycisk + top-level FSM
     */

    logic shared_btn_hover, shared_btn_click;

    menu_ctl #(
        .BTN_X(BTN_X),
        .BTN_Y(BTN_Y),
        .BTN_W(BTN_W),
        .BTN_H(BTN_H)
    ) u_menu_ctl_shared (
        .clk(clk),
        .rst(rst),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted),
        .mouse_left(mouse_left),
        .hover(shared_btn_hover),
        .click_pulse(shared_btn_click)
    );

    logic exit_btn_hover, exit_btn_click;

    menu_ctl #(
        .BTN_X(EXIT_BTN_X),
        .BTN_Y(EXIT_BTN_Y),
        .BTN_W(EXIT_BTN_W),
        .BTN_H(EXIT_BTN_H)
    ) u_menu_ctl_exit (
        .clk(clk),
        .rst(rst),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted),
        .mouse_left(mouse_left),
        .hover(exit_btn_hover),
        .click_pulse(exit_btn_click)
    );

    game_fsm u_game_fsm (
        .clk(clk),
        .rst(rst),
        .start_click(shared_btn_click),
        .menu_click(shared_btn_click),
        .exit_click(exit_btn_click),
        .score_p1_tens(score_p1_tens),
        .score_p1_ones(score_p1_ones),
        .score_p2_tens(score_p2_tens),
        .score_p2_ones(score_p2_ones),
        .game_state(game_state),
        .winner_p2(winner_p2),
        .score_clear(score_clear)
    );

    /**
     * Paletka gracza 1 porusza sie za pomoca myszy po lewej stronie
     */

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

    /**
     * Gracz 2: placeholder AI
     */

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
        .clear(score_clear),
        .goal_p1(goal_p1),
        .goal_p2(goal_p2),
        .score_p1_tens(score_p1_tens),
        .score_p1_ones(score_p1_ones),
        .score_p2_tens(score_p2_tens),
        .score_p2_ones(score_p2_ones)
    );

    /**
     * Submodules: VGA pipeline
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
        .vga_out(vga_bg_to_rink.out)
    );

    draw_rink u_draw_rink (
        .clk(clk), .rst(rst),
        .active(play_active),
        .vga_in (vga_bg_to_rink.in),
        .vga_out(vga_rink_to_p1.out)
    );

    draw_circle #(
        .DIAMETER(PADDLE_W),
        .FILL_COLOR(PADDLE1_COLOR),
        .HILIGHT_COLOR(PADDLE1_HILIGHT_COLOR)
    ) u_draw_p1 (
        .clk(clk), .rst(rst),
        .active(play_active),
        .x_pos(p1_x), .y_pos(p1_y),
        .vga_in (vga_rink_to_p1.in),
        .vga_out(vga_p1_to_p2.out)
    );

    draw_circle #(
        .DIAMETER(PADDLE_W),
        .FILL_COLOR(PADDLE2_COLOR),
        .HILIGHT_COLOR(PADDLE2_HILIGHT_COLOR)
    ) u_draw_p2 (
        .clk(clk), .rst(rst),
        .active(play_active),
        .x_pos(p2_x), .y_pos(p2_y),
        .vga_in (vga_p1_to_p2.in),
        .vga_out(vga_p2_to_puck.out)
    );

    draw_circle #(
        .DIAMETER(PUCK_SIZE),
        .FILL_COLOR(PUCK_COLOR),
        .HILIGHT_COLOR(PUCK_HILIGHT_COLOR)
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
        .active(play_active || game_over_active),
        .value(score_p1_tens),
        .vga_in (vga_puck_to_s1t.in),
        .vga_out(vga_s1t_to_s1o.out)
    );

    draw_digit #(
        .X_POS(SCORE1_ONES_X),
        .Y_POS(SCORE_Y)
    ) u_draw_score1_ones (
        .clk(clk), .rst(rst),
        .active(play_active || game_over_active),
        .value(score_p1_ones),
        .vga_in (vga_s1t_to_s1o.in),
        .vga_out(vga_s1o_to_s2t.out)
    );

    draw_digit #(
        .X_POS(SCORE2_TENS_X),
        .Y_POS(SCORE_Y)
    ) u_draw_score2_tens (
        .clk(clk), .rst(rst),
        .active(play_active || game_over_active),
        .value(score_p2_tens),
        .vga_in (vga_s1o_to_s2t.in),
        .vga_out(vga_s2t_to_s2o.out)
    );

    draw_digit #(
        .X_POS(SCORE2_ONES_X),
        .Y_POS(SCORE_Y)
    ) u_draw_score2_ones (
        .clk(clk), .rst(rst),
        .active(play_active || game_over_active),
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
        .active (menu_active || game_over_active),
        .vga_in (vga_s2o_to_btn.in),
        .vga_out(vga_btn_to_title.out)
    );

    /**
     * Tytul, wiadomosci
     */

    logic [7:0]  title_char_xy;
    logic [3:0]  title_char_line;
    logic [7:0]  title_font_pixels;
    logic [10:0] title_font_addr;
    logic [6:0]  title_code_menu, title_code_p1win, title_code_p2win;
    logic [6:0]  title_char_code;

    assign title_font_addr = {title_char_code, title_char_line};

    always_comb begin
        if (menu_active)
            title_char_code = title_code_menu;
        else if (winner_p2)
            title_char_code = title_code_p2win;
        else
            title_char_code = title_code_p1win;
    end

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
    ) u_char_rom_title_menu (
        .clk(clk),
        .char_xy(title_char_xy),
        .char_code(title_code_menu)
    );

    char_rom #(
        .TEXT({
            "                                ",
            "                                ",
            "        PLAYER 1 WINS!          ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_title_p1win (
        .clk(clk),
        .char_xy(title_char_xy),
        .char_code(title_code_p1win)
    );

    char_rom #(
        .TEXT({
            "                                ",
            "                                ",
            "        PLAYER 2 WINS!          ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_title_p2win (
        .clk(clk),
        .char_xy(title_char_xy),
        .char_code(title_code_p2win)
    );

    font_rom u_font_rom_title (
        .clk(clk),
        .addr(title_font_addr),
        .char_line_pixels(title_font_pixels)
    );

    draw_rect_char #(
        .X_POS(TITLE_X),
        .Y_POS(TITLE_Y)
    ) u_draw_title (
        .clk   (clk),
        .rst   (rst),
        .active(menu_active || game_over_active),
        .vga_in (vga_btn_to_title.in),
        .vga_out(vga_title_to_label.out),
        .char_xy(title_char_xy),
        .char_line(title_char_line),
        .char_line_pixels(title_font_pixels)
    );

    /**
     * Etykieta przycisku dzielonego "START"/"MENU"
     */

    logic [7:0]  label_char_xy;
    logic [3:0]  label_char_line;
    logic [7:0]  label_font_pixels;
    logic [10:0] label_font_addr;
    logic [6:0]  label_code_start, label_code_menu;
    logic [6:0]  label_char_code;

    assign label_font_addr = {label_char_code, label_char_line};
    assign label_char_code = menu_active ? label_code_start : label_code_menu;

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
    ) u_char_rom_label_start (
        .clk(clk),
        .char_xy(label_char_xy),
        .char_code(label_code_start)
    );

    char_rom #(
        .TEXT({
            "MENU                            ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_label_menu (
        .clk(clk),
        .char_xy(label_char_xy),
        .char_code(label_code_menu)
    );

    font_rom u_font_rom_label (
        .clk(clk),
        .addr(label_font_addr),
        .char_line_pixels(label_font_pixels)
    );

    draw_rect_char #(
        .X_POS    (BTN_LABEL_X),
        .Y_POS    (BTN_LABEL_Y),
        .WIDTH_PX (BTN_LABEL_W),
        .HEIGHT_PX(BTN_LABEL_H)
    ) u_draw_label (
        .clk   (clk),
        .rst   (rst),
        .active(menu_active || game_over_active),
        .vga_in (vga_title_to_label.in),
        .vga_out(vga_label_to_exitbtn.out),
        .char_xy(label_char_xy),
        .char_line(label_char_line),
        .char_line_pixels(label_font_pixels)
    );

    /**
     * Przycisk "EXIT" w grze
     */

    draw_button #(
        .X_POS       (EXIT_BTN_X),
        .Y_POS       (EXIT_BTN_Y),
        .WIDTH       (EXIT_BTN_W),
        .HEIGHT      (EXIT_BTN_H),
        .FILL_COLOR  (BTN_FILL_COLOR),
        .BORDER_COLOR(BTN_BORDER_COLOR)
    ) u_draw_exit_button (
        .clk    (clk),
        .rst    (rst),
        .active (play_active),
        .vga_in (vga_label_to_exitbtn.in),
        .vga_out(vga_exitbtn_to_exitlabel.out)
    );

    logic [7:0]  exit_char_xy;
    logic [3:0]  exit_char_line;
    logic [7:0]  exit_font_pixels;
    logic [10:0] exit_font_addr;
    logic [6:0]  exit_char_code;

    assign exit_font_addr = {exit_char_code, exit_char_line};

    char_rom #(
        .TEXT({
            "EXIT                            ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_exit (
        .clk(clk),
        .char_xy(exit_char_xy),
        .char_code(exit_char_code)
    );

    font_rom u_font_rom_exit (
        .clk(clk),
        .addr(exit_font_addr),
        .char_line_pixels(exit_font_pixels)
    );

    draw_rect_char #(
        .X_POS    (EXIT_LABEL_X),
        .Y_POS    (EXIT_LABEL_Y),
        .WIDTH_PX (EXIT_LABEL_W),
        .HEIGHT_PX(EXIT_LABEL_H)
    ) u_draw_exit_label (
        .clk   (clk),
        .rst   (rst),
        .active(play_active),
        .vga_in (vga_exitbtn_to_exitlabel.in),
        .vga_out(vga_exitlabel_to_mouse.out),
        .char_xy(exit_char_xy),
        .char_line(exit_char_line),
        .char_line_pixels(exit_font_pixels)
    );

    draw_mouse u_draw_mouse (
        .clk   (clk),
        .rst_n (rst_n),
        .active(menu_active || game_over_active),
        .vga_in(vga_exitlabel_to_mouse.in),
        .vga_out(vga_out_final.out),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted)
    );

endmodule
