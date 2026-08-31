/**
 * 
 * Autor: KH
 *
 * Opis:
 * Modul top gry cymbergaj
 * Wersja koncowa, 2 graczy + ai
 */

 module top_airhockey
    import game_pkg::*;
    import vga_pkg::*;
(
        input  logic clk,          // 65 MHz VGA pixel clock (1024x768@60)
        input  logic clk100MHz,    // 100 MHz
        input  logic btn_rst,      
        input  logic btn_exit,     
        input  logic sw_is_host,   

        inout  logic ps2_clk,
        inout  logic ps2_data,

        output logic link_tx,      
        input  logic link_rx,      
        output logic led_link_ok,  

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
    logic rst_n;   

    rst_ctl u_rst_ctl (
        .clk(clk),
        .btn_rst(btn_rst),
        .rst(rst)
    );

    assign rst_n = ~rst;

    /**
     * Zmiana roli gracza
     */

    (* ASYNC_REG = "TRUE" *) logic is_host_sync1, is_host_sync2;

    always_ff @(posedge clk) begin
        if (rst) begin
            is_host_sync1 <= 1'b0;
            is_host_sync2 <= 1'b0;
        end else begin
            is_host_sync1 <= sw_is_host;
            is_host_sync2 <= is_host_sync1;
        end
    end

    logic is_host;
    assign is_host = is_host_sync2;

    /**
     * Przycisk "EXIT" (btnL)
     */

    logic exit_btn_click;

    btn_edge u_btn_edge_exit (
        .clk(clk),
        .rst(rst),
        .btn_raw(btn_exit),
        .pulse(exit_btn_click)
    );

    game_state_t local_game_state;
    logic local_winner_p2;
    logic local_score_clear;

    logic [11:0] local_p1_x, local_p1_y;   // P1 (left) zone
    logic [11:0] local_p2_x, local_p2_y;   // P2 (right) zone

    logic [11:0] ai_p2_x, ai_p2_y;
    logic [11:0] p2_source_x, p2_source_y;

    // Lokalna fizyka krążka i wynik
    logic [11:0] local_puck_x, local_puck_y;
    logic local_goal_p1, local_goal_p2;
    logic local_puck_served;
    logic local_server_is_p2;   
    logic [3:0] local_score_p1_tens, local_score_p1_ones;
    logic [3:0] local_score_p2_tens, local_score_p2_ones;

    // Ustawienia (zmienia host)
    logic [3:0] win_score;
    logic [1:0] difficulty_sel;
    logic [3:0] ai_step;
    logic       mode_sel;   

    game_state_t rx_game_state;
    logic rx_winner_p2;
    logic rx_puck_served;
    logic rx_server_is_p2;
    logic [11:0] rx_puck_x, rx_puck_y;
    logic [11:0] rx_p1_x, rx_p1_y;
    logic [3:0] rx_score_p1_tens, rx_score_p1_ones;
    logic [3:0] rx_score_p2_tens, rx_score_p2_ones;
    logic [11:0] rx_p2_x, rx_p2_y;
    logic link_ok;

    logic exclude_p1_host;
    logic exclude_p2_host_ai;
    logic exclude_p2_client;

    game_state_t disp_state;
    logic disp_winner_p2;
    logic [11:0] disp_puck_x, disp_puck_y;
    logic [11:0] disp_p1_x, disp_p1_y;
    logic [11:0] disp_p2_x, disp_p2_y;
    logic [3:0] disp_score_p1_tens, disp_score_p1_ones;
    logic [3:0] disp_score_p2_tens, disp_score_p2_ones;

    logic disp_menu_active, disp_play_active, disp_game_over_active, disp_settings_active;

    assign disp_menu_active      = (disp_state == ST_MENU);
    assign disp_play_active      = (disp_state == ST_PLAY);
    assign disp_game_over_active = (disp_state == ST_GAME_OVER);
    assign disp_settings_active  = (disp_state == ST_SETTINGS);

    /**
     * VGA pipeline interfaces
     */

    vga_if vga_tim_to_bg();
    vga_if vga_menubg_to_rink();
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
    vga_if vga_label_to_settingsbtn();
    vga_if vga_settingsbtn_to_settingslabel();
    vga_if vga_settingslabel_to_winlabel();
    vga_if vga_winlabel_to_winminus();
    vga_if vga_winminus_to_winminuslabel();
    vga_if vga_winminuslabel_to_windigit();
    vga_if vga_windigit_to_winplus();
    vga_if vga_winplus_to_winpluslabel();
    vga_if vga_winpluslabel_to_difflabel();
    vga_if vga_difflabel_to_diffminus();
    vga_if vga_diffminus_to_diffminuslabel();
    vga_if vga_diffminuslabel_to_diffvalue();
    vga_if vga_diffvalue_to_diffplus();
    vga_if vga_diffplus_to_diffpluslabel();
    vga_if vga_diffpluslabel_to_modelabel();
    vga_if vga_modelabel_to_modeminus();
    vga_if vga_modeminus_to_modeminuslabel();
    vga_if vga_modeminuslabel_to_modevalue();
    vga_if vga_modevalue_to_modeplus();
    vga_if vga_modeplus_to_modepluslabel();
    vga_if vga_modepluslabel_to_mouse();
    vga_if vga_out_final();

    assign vga_tim_to_bg.rgb = 12'h0_0_0;

    assign vs = ~vga_out_final.vsync;
    assign hs = ~vga_out_final.hsync;
    assign {r, g, b} = vga_out_final.rgb;

    /**
     * frame tick (~60 Hz)
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

    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_x_sync1, mouse_x_sync2;
    (* ASYNC_REG = "TRUE" *) logic [11:0] mouse_y_sync1, mouse_y_sync2;
    (* ASYNC_REG = "TRUE" *) logic mouse_left_sync1, mouse_left_sync2;
    logic [11:0] mouse_x_restricted, mouse_y_restricted;

    logic rst100;

    rst_ctl u_rst_ctl_100 (
        .clk(clk100MHz),
        .btn_rst(btn_rst),
        .rst(rst100)
    );

    MouseCtl u_mouse (
        .clk(clk100MHz),
        .rst(rst100),

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

        mouse_left_sync1 <= mouse_left;
        mouse_left_sync2 <= mouse_left_sync1;
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
     * Menu/Start/Back: przycisk + top-level FSM
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
        .mouse_left(mouse_left_sync2),
        .hover(shared_btn_hover),
        .click_pulse(shared_btn_click)
    );

    logic settings_btn_hover, settings_btn_click;

    menu_ctl #(
        .BTN_X(SETTINGS_BTN_X),
        .BTN_Y(SETTINGS_BTN_Y),
        .BTN_W(SETTINGS_BTN_W),
        .BTN_H(SETTINGS_BTN_H)
    ) u_menu_ctl_settings (
        .clk(clk),
        .rst(rst),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted),
        .mouse_left(mouse_left_sync2),
        .hover(settings_btn_hover),
        .click_pulse(settings_btn_click)
    );

    logic win_plus_hover, win_plus_click;
    logic win_minus_hover, win_minus_click;

    menu_ctl #(
        .BTN_X(OPT_PLUS_BTN_X),
        .BTN_Y(OPT_PLUS_BTN1_Y),
        .BTN_W(OPT_PLUS_BTN_W),
        .BTN_H(OPT_PLUS_BTN_H)
    ) u_menu_ctl_win_plus (
        .clk(clk),
        .rst(rst),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted),
        .mouse_left(mouse_left_sync2),
        .hover(win_plus_hover),
        .click_pulse(win_plus_click)
    );

    menu_ctl #(
        .BTN_X(OPT_MINUS_BTN_X),
        .BTN_Y(OPT_MINUS_BTN1_Y),
        .BTN_W(OPT_PLUS_BTN_W),
        .BTN_H(OPT_PLUS_BTN_H)
    ) u_menu_ctl_win_minus (
        .clk(clk),
        .rst(rst),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted),
        .mouse_left(mouse_left_sync2),
        .hover(win_minus_hover),
        .click_pulse(win_minus_click)
    );

    logic diff_plus_hover, diff_plus_click;
    logic diff_minus_hover, diff_minus_click;

    menu_ctl #(
        .BTN_X(OPT_PLUS_BTN_X),
        .BTN_Y(OPT_PLUS_BTN2_Y),
        .BTN_W(OPT_PLUS_BTN_W),
        .BTN_H(OPT_PLUS_BTN_H)
    ) u_menu_ctl_diff_plus (
        .clk(clk),
        .rst(rst),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted),
        .mouse_left(mouse_left_sync2),
        .hover(diff_plus_hover),
        .click_pulse(diff_plus_click)
    );

    menu_ctl #(
        .BTN_X(OPT_MINUS_BTN_X),
        .BTN_Y(OPT_MINUS_BTN2_Y),
        .BTN_W(OPT_PLUS_BTN_W),
        .BTN_H(OPT_PLUS_BTN_H)
    ) u_menu_ctl_diff_minus (
        .clk(clk),
        .rst(rst),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted),
        .mouse_left(mouse_left_sync2),
        .hover(diff_minus_hover),
        .click_pulse(diff_minus_click)
    );

    logic mode_plus_hover, mode_plus_click;
    logic mode_minus_hover, mode_minus_click;

    menu_ctl #(
        .BTN_X(OPT_PLUS_BTN_X),
        .BTN_Y(OPT_PLUS_BTN3_Y),
        .BTN_W(OPT_PLUS_BTN_W),
        .BTN_H(OPT_PLUS_BTN_H)
    ) u_menu_ctl_mode_plus (
        .clk(clk),
        .rst(rst),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted),
        .mouse_left(mouse_left_sync2),
        .hover(mode_plus_hover),
        .click_pulse(mode_plus_click)
    );

    menu_ctl #(
        .BTN_X(OPT_MINUS_BTN_X),
        .BTN_Y(OPT_MINUS_BTN3_Y),
        .BTN_W(OPT_PLUS_BTN_W),
        .BTN_H(OPT_PLUS_BTN_H)
    ) u_menu_ctl_mode_minus (
        .clk(clk),
        .rst(rst),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted),
        .mouse_left(mouse_left_sync2),
        .hover(mode_minus_hover),
        .click_pulse(mode_minus_click)
    );

    settings_ctl u_settings_ctl (
        .clk(clk),
        .rst(rst),
        .win_score_inc(win_plus_click),
        .win_score_dec(win_minus_click),
        .difficulty_inc(diff_plus_click),
        .difficulty_dec(diff_minus_click),
        .mode_inc(mode_plus_click),
        .mode_dec(mode_minus_click),
        .win_score(win_score),
        .difficulty_sel(difficulty_sel),
        .ai_step(ai_step),
        .mode_sel(mode_sel)
    );

    game_fsm u_game_fsm (
        .clk(clk),
        .rst(rst),
        .start_click(shared_btn_click),
        .settings_click(settings_btn_click),
        .back_click(shared_btn_click),
        .menu_click(shared_btn_click),
        .exit_click(exit_btn_click),
        .win_score(win_score),
        .score_p1_tens(local_score_p1_tens),
        .score_p1_ones(local_score_p1_ones),
        .score_p2_tens(local_score_p2_tens),
        .score_p2_ones(local_score_p2_ones),
        .game_state(local_game_state),
        .winner_p2(local_winner_p2),
        .score_clear(local_score_clear)
    );

    /**
     * Paletki
     */

    paddle_ctl #(
        .MIN_X(P1_MIN_X),
        .MAX_X(P1_MAX_X),
        .MIN_Y(PADDLE_MIN_Y),
        .MAX_Y(PADDLE_MAX_Y)
    ) u_paddle_local_p1zone (
        .clk     (clk),
        .rst     (rst),
        .in_x    (mouse_x_restricted),
        .in_y    (mouse_y_restricted),
        .paddle_x(local_p1_x),
        .paddle_y(local_p1_y)
    );

    paddle_ctl #(
        .MIN_X(P2_MIN_X),
        .MAX_X(P2_MAX_X),
        .MIN_Y(PADDLE_MIN_Y),
        .MAX_Y(PADDLE_MAX_Y)
    ) u_paddle_local_p2zone (
        .clk     (clk),
        .rst     (rst),
        .in_x    (mouse_x_restricted),
        .in_y    (mouse_y_restricted),
        .paddle_x(local_p2_x),
        .paddle_y(local_p2_y)
    );

    /**
     * Paletka ai
     */

    paddle2_ai u_paddle2_ai (
        .clk(clk),
        .rst(rst),
        .frame_tick(frame_tick),
        .puck_served(local_puck_served),
        .exclude_me(exclude_p2_host_ai),
        .ai_step(ai_step),
        .puck_x(local_puck_x),
        .puck_y(local_puck_y),
        .p1_y(local_p1_y),
        .ai_x(ai_p2_x),
        .ai_y(ai_p2_y)
    );

    /**
     * UART
     */

    link_tx_ctl u_link_tx_ctl (
        .clk(clk),
        .rst(rst),
        .frame_tick(frame_tick),
        .is_host(is_host),
        .game_state(local_game_state),
        .winner_p2(local_winner_p2),
        .puck_served(local_puck_served),
        .server_is_p2(local_server_is_p2),
        .puck_x(local_puck_x), .puck_y(local_puck_y),
        .p1_x(local_p1_x), .p1_y(local_p1_y),
        .score_p1_tens(local_score_p1_tens), .score_p1_ones(local_score_p1_ones),
        .score_p2_tens(local_score_p2_tens), .score_p2_ones(local_score_p2_ones),
        .p2_x(local_p2_x), .p2_y(local_p2_y),
        .tx(link_tx)
    );

    link_rx_ctl u_link_rx_ctl (
        .clk(clk),
        .rst(rst),
        .is_host(is_host),
        .rx(link_rx),
        .rx_game_state(rx_game_state),
        .rx_winner_p2(rx_winner_p2),
        .rx_puck_served(rx_puck_served),
        .rx_server_is_p2(rx_server_is_p2),
        .rx_puck_x(rx_puck_x), .rx_puck_y(rx_puck_y),
        .rx_p1_x(rx_p1_x), .rx_p1_y(rx_p1_y),
        .rx_score_p1_tens(rx_score_p1_tens), .rx_score_p1_ones(rx_score_p1_ones),
        .rx_score_p2_tens(rx_score_p2_tens), .rx_score_p2_ones(rx_score_p2_ones),
        .rx_p2_x(rx_p2_x), .rx_p2_y(rx_p2_y),
        .link_ok(link_ok)
    );

    assign exclude_p1_host    = !local_puck_served && local_server_is_p2;
    assign exclude_p2_host_ai = !local_puck_served && !local_server_is_p2;
    assign exclude_p2_client  = !rx_puck_served && !rx_server_is_p2;

    logic [23:0] link_led_timer;
    always_ff @(posedge clk) begin
        if (rst) begin
            link_led_timer <= 24'd0;
        end else if (link_ok) begin
            link_led_timer <= 24'd6_500_000;  
        end else if (link_led_timer != 0) begin
            link_led_timer <= link_led_timer - 24'd1;
        end
    end
    assign led_link_ok = (link_led_timer != 0);

    /**
     * Fizyka krazka i wynik
     */

    assign p2_source_x = mode_sel ? rx_p2_x : ai_p2_x;
    assign p2_source_y = mode_sel ? rx_p2_y : ai_p2_y;

    puck_ctl u_puck_ctl (
        .clk(clk),
        .rst(rst),
        .frame_tick(frame_tick),
        .active(local_game_state == ST_PLAY),
        .p1_x(local_p1_x), .p1_y(local_p1_y),
        .p2_x(p2_source_x), .p2_y(p2_source_y),
        .puck_x(local_puck_x), .puck_y(local_puck_y),
        .goal_p1(local_goal_p1),
        .goal_p2(local_goal_p2),
        .puck_served(local_puck_served),
        .server_is_p2(local_server_is_p2)
    );

    score_ctl u_score_ctl (
        .clk(clk),
        .rst(rst),
        .clear(local_score_clear),
        .goal_p1(local_goal_p1),
        .goal_p2(local_goal_p2),
        .score_p1_tens(local_score_p1_tens),
        .score_p1_ones(local_score_p1_ones),
        .score_p2_tens(local_score_p2_tens),
        .score_p2_ones(local_score_p2_ones)
    );

    assign disp_state          = is_host ? local_game_state    : rx_game_state;
    assign disp_winner_p2      = is_host ? local_winner_p2     : rx_winner_p2;
    assign disp_puck_x         = is_host ? local_puck_x        : rx_puck_x;
    assign disp_puck_y         = is_host ? local_puck_y        : rx_puck_y;
    assign disp_p1_x           = is_host ? local_p1_x          : rx_p1_x;
    assign disp_p1_y           = is_host ? local_p1_y          : rx_p1_y;
    assign disp_p2_x           = is_host ? p2_source_x         : local_p2_x;
    assign disp_p2_y           = is_host ? p2_source_y         : local_p2_y;
    assign disp_score_p1_tens  = is_host ? local_score_p1_tens : rx_score_p1_tens;
    assign disp_score_p1_ones  = is_host ? local_score_p1_ones : rx_score_p1_ones;
    assign disp_score_p2_tens  = is_host ? local_score_p2_tens : rx_score_p2_tens;
    assign disp_score_p2_ones  = is_host ? local_score_p2_ones : rx_score_p2_ones;

    logic settings_detail_active;
    assign settings_detail_active = disp_settings_active && is_host;

    /**
     * VGA pipeline
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

    draw_menu_bg u_draw_menu_bg (
        .clk(clk), .rst(rst),
        .active(!disp_play_active),
        .vga_in (vga_tim_to_bg.in),
        .vga_out(vga_menubg_to_rink.out)
    );

    draw_rink u_draw_rink (
        .clk(clk), .rst(rst),
        .active(disp_play_active),
        .vga_in (vga_menubg_to_rink.in),
        .vga_out(vga_rink_to_p1.out)
    );

    draw_circle #(
        .DIAMETER(PADDLE_W),
        .FILL_COLOR(PADDLE1_COLOR),
        .HILIGHT_COLOR(PADDLE1_HILIGHT_COLOR)
    ) u_draw_p1 (
        .clk(clk), .rst(rst),
        .active(disp_play_active),
        .x_pos(disp_p1_x), .y_pos(disp_p1_y),
        .vga_in (vga_rink_to_p1.in),
        .vga_out(vga_p1_to_p2.out)
    );

    draw_circle #(
        .DIAMETER(PADDLE_W),
        .FILL_COLOR(PADDLE2_COLOR),
        .HILIGHT_COLOR(PADDLE2_HILIGHT_COLOR)
    ) u_draw_p2 (
        .clk(clk), .rst(rst),
        .active(disp_play_active),
        .x_pos(disp_p2_x), .y_pos(disp_p2_y),
        .vga_in (vga_p1_to_p2.in),
        .vga_out(vga_p2_to_puck.out)
    );

    draw_circle #(
        .DIAMETER(PUCK_SIZE),
        .FILL_COLOR(PUCK_COLOR),
        .HILIGHT_COLOR(PUCK_HILIGHT_COLOR)
    ) u_draw_puck (
        .clk(clk), .rst(rst),
        .active(disp_play_active),
        .x_pos(disp_puck_x), .y_pos(disp_puck_y),
        .vga_in (vga_p2_to_puck.in),
        .vga_out(vga_puck_to_s1t.out)
    );

    draw_digit #(
        .X_POS(SCORE1_TENS_X),
        .Y_POS(SCORE_Y)
    ) u_draw_score1_tens (
        .clk(clk), .rst(rst),
        .active(disp_play_active || disp_game_over_active),
        .value(disp_score_p1_tens),
        .vga_in (vga_puck_to_s1t.in),
        .vga_out(vga_s1t_to_s1o.out)
    );

    draw_digit #(
        .X_POS(SCORE1_ONES_X),
        .Y_POS(SCORE_Y)
    ) u_draw_score1_ones (
        .clk(clk), .rst(rst),
        .active(disp_play_active || disp_game_over_active),
        .value(disp_score_p1_ones),
        .vga_in (vga_s1t_to_s1o.in),
        .vga_out(vga_s1o_to_s2t.out)
    );

    draw_digit #(
        .X_POS(SCORE2_TENS_X),
        .Y_POS(SCORE_Y)
    ) u_draw_score2_tens (
        .clk(clk), .rst(rst),
        .active(disp_play_active || disp_game_over_active),
        .value(disp_score_p2_tens),
        .vga_in (vga_s1o_to_s2t.in),
        .vga_out(vga_s2t_to_s2o.out)
    );

    draw_digit #(
        .X_POS(SCORE2_ONES_X),
        .Y_POS(SCORE_Y)
    ) u_draw_score2_ones (
        .clk(clk), .rst(rst),
        .active(disp_play_active || disp_game_over_active),
        .value(disp_score_p2_ones),
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
        .active (disp_menu_active || disp_game_over_active || disp_settings_active),
        .vga_in (vga_s2o_to_btn.in),
        .vga_out(vga_btn_to_title.out)
    );

    /**
     * Tytuł
     */

    logic [7:0]  title_char_xy;
    logic [3:0]  title_char_line;
    logic [7:0]  title_font_pixels;
    logic [10:0] title_font_addr;
    logic [6:0]  title_code_menu, title_code_p1win, title_code_p2win, title_code_settings;
    logic [6:0]  title_char_code;

    assign title_font_addr = {title_char_code, title_char_line};

    always_comb begin
        if (disp_menu_active)
            title_char_code = title_code_menu;
        else if (disp_settings_active)
            title_char_code = title_code_settings;
        else if (disp_winner_p2)
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

    char_rom #(
        .TEXT({
            "                                ",
            "                                ",
            "           SETTINGS             ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_title_settings (
        .clk(clk),
        .char_xy(title_char_xy),
        .char_code(title_code_settings)
    );

    font_rom u_font_rom_title (
        .clk(clk),
        .addr(title_font_addr),
        .char_line_pixels(title_font_pixels)
    );

    draw_rect_char #(
        .X_POS(275),
        .Y_POS(TITLE_Y - 48),
        .WIDTH_PX(320),
        .HEIGHT_PX(96),
        .SCALE_SHIFT(1)
    ) u_draw_title (
        .clk   (clk),
        .rst   (rst),
        .active(disp_menu_active || disp_game_over_active || disp_settings_active),
        .vga_in (vga_btn_to_title.in),
        .vga_out(vga_title_to_label.out),
        .char_xy(title_char_xy),
        .char_line(title_char_line),
        .char_line_pixels(title_font_pixels)
    );

    /**
     * Przycisk Start/ Menu/ Back
     */

    logic [7:0]  label_char_xy;
    logic [3:0]  label_char_line;
    logic [7:0]  label_font_pixels;
    logic [10:0] label_font_addr;
    logic [6:0]  label_code_start, label_code_menu, label_code_back;
    logic [6:0]  label_char_code;

    assign label_font_addr = {label_char_code, label_char_line};

    always_comb begin
        if (disp_menu_active)
            label_char_code = label_code_start;
        else if (disp_settings_active)
            label_char_code = label_code_back;
        else
            label_char_code = label_code_menu;
    end

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

    char_rom #(
        .TEXT({
            "BACK                            ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_label_back (
        .clk(clk),
        .char_xy(label_char_xy),
        .char_code(label_code_back)
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
        .active(disp_menu_active || disp_game_over_active || disp_settings_active),
        .vga_in (vga_title_to_label.in),
        .vga_out(vga_label_to_settingsbtn.out),
        .char_xy(label_char_xy),
        .char_line(label_char_line),
        .char_line_pixels(label_font_pixels)
    );

    /**
     * Settings
     */

    draw_button #(
        .X_POS       (SETTINGS_BTN_X),
        .Y_POS       (SETTINGS_BTN_Y),
        .WIDTH       (SETTINGS_BTN_W),
        .HEIGHT      (SETTINGS_BTN_H),
        .FILL_COLOR  (BTN_FILL_COLOR),
        .BORDER_COLOR(BTN_BORDER_COLOR)
    ) u_draw_settings_button (
        .clk    (clk),
        .rst    (rst),
        .active (disp_menu_active),
        .vga_in (vga_label_to_settingsbtn.in),
        .vga_out(vga_settingsbtn_to_settingslabel.out)
    );

    logic [7:0]  settings_label_char_xy;
    logic [3:0]  settings_label_char_line;
    logic [7:0]  settings_label_font_pixels;
    logic [10:0] settings_label_font_addr;
    logic [6:0]  settings_label_char_code;

    assign settings_label_font_addr = {settings_label_char_code, settings_label_char_line};

    char_rom #(
        .TEXT({
            "SETTINGS                        ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_settings_label (
        .clk(clk),
        .char_xy(settings_label_char_xy),
        .char_code(settings_label_char_code)
    );

    font_rom u_font_rom_settings_label (
        .clk(clk),
        .addr(settings_label_font_addr),
        .char_line_pixels(settings_label_font_pixels)
    );

    draw_rect_char #(
        .X_POS    (SETTINGS_LABEL_X),          
        .Y_POS    (SETTINGS_LABEL_Y),
        .WIDTH_PX (SETTINGS_LABEL_W),       
        .HEIGHT_PX(SETTINGS_LABEL_H)       
    ) u_draw_settings_label (
        .clk   (clk),
        .rst   (rst),
        .active(disp_menu_active), 
        .vga_in (vga_settingsbtn_to_settingslabel.in),
        .vga_out(vga_settingslabel_to_winlabel.out),
        .char_xy(settings_label_char_xy),
        .char_line(settings_label_char_line),
        .char_line_pixels(settings_label_font_pixels)
    );

    /**
     * WIN SCORE
     */

    logic [7:0]  winlbl_char_xy;
    logic [3:0]  winlbl_char_line;
    logic [7:0]  winlbl_font_pixels;
    logic [10:0] winlbl_font_addr;
    logic [6:0]  winlbl_char_code;

    assign winlbl_font_addr = {winlbl_char_code, winlbl_char_line};

    char_rom #(
        .TEXT({
            "WIN SCORE:                      ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_winlbl (
        .clk(clk),
        .char_xy(winlbl_char_xy),
        .char_code(winlbl_char_code)
    );

    font_rom u_font_rom_winlbl (
        .clk(clk),
        .addr(winlbl_font_addr),
        .char_line_pixels(winlbl_font_pixels)
    );

    draw_rect_char #(
        .X_POS   (OPT_LABEL_X),
        .Y_POS   (WIN_SCORE_ROW_Y),
        .WIDTH_PX(OPT_LABEL_W),
        .HEIGHT_PX(OPT_LABEL_H)
    ) u_draw_winlbl (
        .clk   (clk),
        .rst   (rst),
        .active(settings_detail_active),
        .vga_in (vga_settingslabel_to_winlabel.in),
        .vga_out(vga_winlabel_to_winminus.out),
        .char_xy(winlbl_char_xy),
        .char_line(winlbl_char_line),
        .char_line_pixels(winlbl_font_pixels)
    );

    draw_button #(
        .X_POS       (OPT_MINUS_BTN_X),
        .Y_POS       (OPT_MINUS_BTN1_Y),
        .WIDTH       (OPT_PLUS_BTN_W),
        .HEIGHT      (OPT_PLUS_BTN_H),
        .FILL_COLOR  (BTN_FILL_COLOR),
        .BORDER_COLOR(BTN_BORDER_COLOR)
    ) u_draw_win_minus_button (
        .clk    (clk),
        .rst    (rst),
        .active (settings_detail_active),
        .vga_in (vga_winlabel_to_winminus.in),
        .vga_out(vga_winminus_to_winminuslabel.out)
    );

    logic [7:0]  winminus_char_xy;
    logic [3:0]  winminus_char_line;
    logic [7:0]  winminus_font_pixels;
    logic [10:0] winminus_font_addr;
    logic [6:0]  winminus_char_code;

    assign winminus_font_addr = {winminus_char_code, winminus_char_line};

    char_rom #(
        .TEXT({
            "-                               ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_winminus (
        .clk(clk),
        .char_xy(winminus_char_xy),
        .char_code(winminus_char_code)
    );

    font_rom u_font_rom_winminus (
        .clk(clk),
        .addr(winminus_font_addr),
        .char_line_pixels(winminus_font_pixels)
    );

    draw_rect_char #(
        .X_POS    (OPT_MINUS_LABEL_X),
        .Y_POS    (OPT_MINUS_LABEL1_Y),
        .WIDTH_PX (OPT_PLUS_LABEL_W),
        .HEIGHT_PX(OPT_PLUS_LABEL_H)
    ) u_draw_winminus_label (
        .clk   (clk),
        .rst   (rst),
        .active(settings_detail_active),
        .vga_in (vga_winminus_to_winminuslabel.in),
        .vga_out(vga_winminuslabel_to_windigit.out),
        .char_xy(winminus_char_xy),
        .char_line(winminus_char_line),
        .char_line_pixels(winminus_font_pixels)
    );

    draw_digit #(
        .X_POS(OPT_VALUE_X),
        .Y_POS(WIN_SCORE_ROW_Y)
    ) u_draw_win_value (
        .clk(clk), .rst(rst),
        .active(settings_detail_active),
        .value(win_score),
        .vga_in (vga_winminuslabel_to_windigit.in),
        .vga_out(vga_windigit_to_winplus.out)
    );

    draw_button #(
        .X_POS       (OPT_PLUS_BTN_X),
        .Y_POS       (OPT_PLUS_BTN1_Y),
        .WIDTH       (OPT_PLUS_BTN_W),
        .HEIGHT      (OPT_PLUS_BTN_H),
        .FILL_COLOR  (BTN_FILL_COLOR),
        .BORDER_COLOR(BTN_BORDER_COLOR)
    ) u_draw_win_plus_button (
        .clk    (clk),
        .rst    (rst),
        .active (settings_detail_active),
        .vga_in (vga_windigit_to_winplus.in),
        .vga_out(vga_winplus_to_winpluslabel.out)
    );

    logic [7:0]  winplus_char_xy;
    logic [3:0]  winplus_char_line;
    logic [7:0]  winplus_font_pixels;
    logic [10:0] winplus_font_addr;
    logic [6:0]  winplus_char_code;

    assign winplus_font_addr = {winplus_char_code, winplus_char_line};

    char_rom #(
        .TEXT({
            "+                               ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_winplus (
        .clk(clk),
        .char_xy(winplus_char_xy),
        .char_code(winplus_char_code)
    );

    font_rom u_font_rom_winplus (
        .clk(clk),
        .addr(winplus_font_addr),
        .char_line_pixels(winplus_font_pixels)
    );

    draw_rect_char #(
        .X_POS    (OPT_PLUS_LABEL_X),
        .Y_POS    (OPT_PLUS_LABEL1_Y),
        .WIDTH_PX (OPT_PLUS_LABEL_W),
        .HEIGHT_PX(OPT_PLUS_LABEL_H)
    ) u_draw_winplus_label (
        .clk   (clk),
        .rst   (rst),
        .active(settings_detail_active),
        .vga_in (vga_winplus_to_winpluslabel.in),
        .vga_out(vga_winpluslabel_to_difflabel.out),
        .char_xy(winplus_char_xy),
        .char_line(winplus_char_line),
        .char_line_pixels(winplus_font_pixels)
    );

    /**
     * DIFFICULTY
     */

    logic [7:0]  difflbl_char_xy;
    logic [3:0]  difflbl_char_line;
    logic [7:0]  difflbl_font_pixels;
    logic [10:0] difflbl_font_addr;
    logic [6:0]  difflbl_char_code;

    assign difflbl_font_addr = {difflbl_char_code, difflbl_char_line};

    char_rom #(
        .TEXT({
            "DIFFICULTY:                     ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_difflbl (
        .clk(clk),
        .char_xy(difflbl_char_xy),
        .char_code(difflbl_char_code)
    );

    font_rom u_font_rom_difflbl (
        .clk(clk),
        .addr(difflbl_font_addr),
        .char_line_pixels(difflbl_font_pixels)
    );

    draw_rect_char #(
        .X_POS   (OPT_LABEL_X),
        .Y_POS   (DIFFICULTY_ROW_Y),
        .WIDTH_PX(OPT_LABEL_W),
        .HEIGHT_PX(OPT_LABEL_H)
    ) u_draw_difflbl (
        .clk   (clk),
        .rst   (rst),
        .active(settings_detail_active),
        .vga_in (vga_winpluslabel_to_difflabel.in),
        .vga_out(vga_difflabel_to_diffminus.out),
        .char_xy(difflbl_char_xy),
        .char_line(difflbl_char_line),
        .char_line_pixels(difflbl_font_pixels)
    );

    draw_button #(
        .X_POS       (OPT_MINUS_BTN_X),
        .Y_POS       (OPT_MINUS_BTN2_Y),
        .WIDTH       (OPT_PLUS_BTN_W),
        .HEIGHT      (OPT_PLUS_BTN_H),
        .FILL_COLOR  (BTN_FILL_COLOR),
        .BORDER_COLOR(BTN_BORDER_COLOR)
    ) u_draw_diff_minus_button (
        .clk    (clk),
        .rst    (rst),
        .active (settings_detail_active),
        .vga_in (vga_difflabel_to_diffminus.in),
        .vga_out(vga_diffminus_to_diffminuslabel.out)
    );

    logic [7:0]  diffminus_char_xy;
    logic [3:0]  diffminus_char_line;
    logic [7:0]  diffminus_font_pixels;
    logic [10:0] diffminus_font_addr;
    logic [6:0]  diffminus_char_code;

    assign diffminus_font_addr = {diffminus_char_code, diffminus_char_line};

    char_rom #(
        .TEXT({
            "-                               ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_diffminus (
        .clk(clk),
        .char_xy(diffminus_char_xy),
        .char_code(diffminus_char_code)
    );

    font_rom u_font_rom_diffminus (
        .clk(clk),
        .addr(diffminus_font_addr),
        .char_line_pixels(diffminus_font_pixels)
    );

    draw_rect_char #(
        .X_POS    (OPT_MINUS_LABEL_X),
        .Y_POS    (OPT_MINUS_LABEL2_Y),
        .WIDTH_PX (OPT_PLUS_LABEL_W),
        .HEIGHT_PX(OPT_PLUS_LABEL_H)
    ) u_draw_diffminus_label (
        .clk   (clk),
        .rst   (rst),
        .active(settings_detail_active),
        .vga_in (vga_diffminus_to_diffminuslabel.in),
        .vga_out(vga_diffminuslabel_to_diffvalue.out),
        .char_xy(diffminus_char_xy),
        .char_line(diffminus_char_line),
        .char_line_pixels(diffminus_font_pixels)
    );

    logic [7:0]  diffval_char_xy;
    logic [3:0]  diffval_char_line;
    logic [7:0]  diffval_font_pixels;
    logic [10:0] diffval_font_addr;
    logic [6:0]  diffval_code_easy, diffval_code_normal, diffval_code_hard;
    logic [6:0]  diffval_char_code;

    assign diffval_font_addr = {diffval_char_code, diffval_char_line};

    always_comb begin
        case (difficulty_sel)
            2'd0:    diffval_char_code = diffval_code_easy;
            2'd1:    diffval_char_code = diffval_code_normal;
            default: diffval_char_code = diffval_code_hard;
        endcase
    end

    char_rom #(
        .TEXT({
            "EASY                            ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_diff_easy (
        .clk(clk),
        .char_xy(diffval_char_xy),
        .char_code(diffval_code_easy)
    );

    char_rom #(
        .TEXT({
            "NORMAL                          ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_diff_normal (
        .clk(clk),
        .char_xy(diffval_char_xy),
        .char_code(diffval_code_normal)
    );

    char_rom #(
        .TEXT({
            "HARD                            ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_diff_hard (
        .clk(clk),
        .char_xy(diffval_char_xy),
        .char_code(diffval_code_hard)
    );

    font_rom u_font_rom_diffval (
        .clk(clk),
        .addr(diffval_font_addr),
        .char_line_pixels(diffval_font_pixels)
    );

    draw_rect_char #(
        .X_POS    (OPT_VALUE_X),
        .Y_POS    (DIFFICULTY_ROW_Y),
        .WIDTH_PX (DIFF_VALUE_W),
        .HEIGHT_PX(DIFF_VALUE_H)
    ) u_draw_diffval (
        .clk   (clk),
        .rst   (rst),
        .active(settings_detail_active),
        .vga_in (vga_diffminuslabel_to_diffvalue.in),
        .vga_out(vga_diffvalue_to_diffplus.out),
        .char_xy(diffval_char_xy),
        .char_line(diffval_char_line),
        .char_line_pixels(diffval_font_pixels)
    );

    draw_button #(
        .X_POS       (OPT_PLUS_BTN_X),
        .Y_POS       (OPT_PLUS_BTN2_Y),
        .WIDTH       (OPT_PLUS_BTN_W),
        .HEIGHT      (OPT_PLUS_BTN_H),
        .FILL_COLOR  (BTN_FILL_COLOR),
        .BORDER_COLOR(BTN_BORDER_COLOR)
    ) u_draw_diff_plus_button (
        .clk    (clk),
        .rst    (rst),
        .active (settings_detail_active),
        .vga_in (vga_diffvalue_to_diffplus.in),
        .vga_out(vga_diffplus_to_diffpluslabel.out)
    );

    logic [7:0]  diffplus_char_xy;
    logic [3:0]  diffplus_char_line;
    logic [7:0]  diffplus_font_pixels;
    logic [10:0] diffplus_font_addr;
    logic [6:0]  diffplus_char_code;

    assign diffplus_font_addr = {diffplus_char_code, diffplus_char_line};

    char_rom #(
        .TEXT({
            "+                               ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_diffplus (
        .clk(clk),
        .char_xy(diffplus_char_xy),
        .char_code(diffplus_char_code)
    );

    font_rom u_font_rom_diffplus (
        .clk(clk),
        .addr(diffplus_font_addr),
        .char_line_pixels(diffplus_font_pixels)
    );

    draw_rect_char #(
        .X_POS    (OPT_PLUS_LABEL_X),
        .Y_POS    (OPT_PLUS_LABEL2_Y),
        .WIDTH_PX (OPT_PLUS_LABEL_W),
        .HEIGHT_PX(OPT_PLUS_LABEL_H)
    ) u_draw_diffplus_label (
        .clk   (clk),
        .rst   (rst),
        .active(settings_detail_active),
        .vga_in (vga_diffplus_to_diffpluslabel.in),
        .vga_out(vga_diffpluslabel_to_modelabel.out),
        .char_xy(diffplus_char_xy),
        .char_line(diffplus_char_line),
        .char_line_pixels(diffplus_font_pixels)
    );

    /**
     * MODE
     */

    logic [7:0]  modelbl_char_xy;
    logic [3:0]  modelbl_char_line;
    logic [7:0]  modelbl_font_pixels;
    logic [10:0] modelbl_font_addr;
    logic [6:0]  modelbl_char_code;

    assign modelbl_font_addr = {modelbl_char_code, modelbl_char_line};

    char_rom #(
        .TEXT({
            "MODE:                           ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_modelbl (
        .clk(clk),
        .char_xy(modelbl_char_xy),
        .char_code(modelbl_char_code)
    );

    font_rom u_font_rom_modelbl (
        .clk(clk),
        .addr(modelbl_font_addr),
        .char_line_pixels(modelbl_font_pixels)
    );

    draw_rect_char #(
        .X_POS   (OPT_LABEL_X),
        .Y_POS   (MODE_ROW_Y),
        .WIDTH_PX(OPT_LABEL_W),
        .HEIGHT_PX(OPT_LABEL_H)
    ) u_draw_modelbl (
        .clk   (clk),
        .rst   (rst),
        .active(settings_detail_active),
        .vga_in (vga_diffpluslabel_to_modelabel.in),
        .vga_out(vga_modelabel_to_modeminus.out),
        .char_xy(modelbl_char_xy),
        .char_line(modelbl_char_line),
        .char_line_pixels(modelbl_font_pixels)
    );

    draw_button #(
        .X_POS       (OPT_MINUS_BTN_X),
        .Y_POS       (OPT_MINUS_BTN3_Y),
        .WIDTH       (OPT_PLUS_BTN_W),
        .HEIGHT      (OPT_PLUS_BTN_H),
        .FILL_COLOR  (BTN_FILL_COLOR),
        .BORDER_COLOR(BTN_BORDER_COLOR)
    ) u_draw_mode_minus_button (
        .clk    (clk),
        .rst    (rst),
        .active (settings_detail_active),
        .vga_in (vga_modelabel_to_modeminus.in),
        .vga_out(vga_modeminus_to_modeminuslabel.out)
    );

    logic [7:0]  modeminus_char_xy;
    logic [3:0]  modeminus_char_line;
    logic [7:0]  modeminus_font_pixels;
    logic [10:0] modeminus_font_addr;
    logic [6:0]  modeminus_char_code;

    assign modeminus_font_addr = {modeminus_char_code, modeminus_char_line};

    char_rom #(
        .TEXT({
            "-                               ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_modeminus (
        .clk(clk),
        .char_xy(modeminus_char_xy),
        .char_code(modeminus_char_code)
    );

    font_rom u_font_rom_modeminus (
        .clk(clk),
        .addr(modeminus_font_addr),
        .char_line_pixels(modeminus_font_pixels)
    );

    draw_rect_char #(
        .X_POS    (OPT_MINUS_LABEL_X),
        .Y_POS    (OPT_MINUS_LABEL3_Y),
        .WIDTH_PX (OPT_PLUS_LABEL_W),
        .HEIGHT_PX(OPT_PLUS_LABEL_H)
    ) u_draw_modeminus_label (
        .clk   (clk),
        .rst   (rst),
        .active(settings_detail_active),
        .vga_in (vga_modeminus_to_modeminuslabel.in),
        .vga_out(vga_modeminuslabel_to_modevalue.out),
        .char_xy(modeminus_char_xy),
        .char_line(modeminus_char_line),
        .char_line_pixels(modeminus_font_pixels)
    );

    logic [7:0]  modeval_char_xy;
    logic [3:0]  modeval_char_line;
    logic [7:0]  modeval_font_pixels;
    logic [10:0] modeval_font_addr;
    logic [6:0]  modeval_code_solo, modeval_code_2p;
    logic [6:0]  modeval_char_code;

    assign modeval_font_addr = {modeval_char_code, modeval_char_line};
    assign modeval_char_code = mode_sel ? modeval_code_2p : modeval_code_solo;

    char_rom #(
        .TEXT({
            "SOLO                            ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_mode_solo (
        .clk(clk),
        .char_xy(modeval_char_xy),
        .char_code(modeval_code_solo)
    );

    char_rom #(
        .TEXT({
            "2P                              ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_mode_2p (
        .clk(clk),
        .char_xy(modeval_char_xy),
        .char_code(modeval_code_2p)
    );

    font_rom u_font_rom_modeval (
        .clk(clk),
        .addr(modeval_font_addr),
        .char_line_pixels(modeval_font_pixels)
    );

    draw_rect_char #(
        .X_POS    (OPT_VALUE_X),
        .Y_POS    (MODE_ROW_Y),
        .WIDTH_PX (MODE_VALUE_W),
        .HEIGHT_PX(MODE_VALUE_H)
    ) u_draw_modeval (
        .clk   (clk),
        .rst   (rst),
        .active(settings_detail_active),
        .vga_in (vga_modeminuslabel_to_modevalue.in),
        .vga_out(vga_modevalue_to_modeplus.out),
        .char_xy(modeval_char_xy),
        .char_line(modeval_char_line),
        .char_line_pixels(modeval_font_pixels)
    );

    draw_button #(
        .X_POS       (OPT_PLUS_BTN_X),
        .Y_POS       (OPT_PLUS_BTN3_Y),
        .WIDTH       (OPT_PLUS_BTN_W),
        .HEIGHT      (OPT_PLUS_BTN_H),
        .FILL_COLOR  (BTN_FILL_COLOR),
        .BORDER_COLOR(BTN_BORDER_COLOR)
    ) u_draw_mode_plus_button (
        .clk    (clk),
        .rst    (rst),
        .active (settings_detail_active),
        .vga_in (vga_modevalue_to_modeplus.in),
        .vga_out(vga_modeplus_to_modepluslabel.out)
    );

    logic [7:0]  modeplus_char_xy;
    logic [3:0]  modeplus_char_line;
    logic [7:0]  modeplus_font_pixels;
    logic [10:0] modeplus_font_addr;
    logic [6:0]  modeplus_char_code;

    assign modeplus_font_addr = {modeplus_char_code, modeplus_char_line};

    char_rom #(
        .TEXT({
            "+                               ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                ",
            "                                "
        })
    ) u_char_rom_modeplus (
        .clk(clk),
        .char_xy(modeplus_char_xy),
        .char_code(modeplus_char_code)
    );

    font_rom u_font_rom_modeplus (
        .clk(clk),
        .addr(modeplus_font_addr),
        .char_line_pixels(modeplus_font_pixels)
    );

    draw_rect_char #(
        .X_POS    (OPT_PLUS_LABEL_X),
        .Y_POS    (OPT_PLUS_LABEL3_Y),
        .WIDTH_PX (OPT_PLUS_LABEL_W),
        .HEIGHT_PX(OPT_PLUS_LABEL_H)
    ) u_draw_modeplus_label (
        .clk   (clk),
        .rst   (rst),
        .active(settings_detail_active),
        .vga_in (vga_modeplus_to_modepluslabel.in),
        .vga_out(vga_modepluslabel_to_mouse.out),
        .char_xy(modeplus_char_xy),
        .char_line(modeplus_char_line),
        .char_line_pixels(modeplus_font_pixels)
    );

    draw_mouse u_draw_mouse (
        .clk   (clk),
        .rst_n (rst_n),
        .active(disp_menu_active || disp_game_over_active || disp_settings_active),
        .vga_in(vga_modepluslabel_to_mouse.in),
        .vga_out(vga_out_final.out),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted)
    );

endmodule
