/**
 * 
 * Autor: KH
 *
 * Opis:
 * Modul top gry cymbergaj
 * Aktualnie wersja na jedna plytke (chwiloowy brak mozliwosci inaczej)
 * Wersja z prostokatami zamiast paletek i kwadrat krazek
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
    vga_if vga_bg_to_paddle();
    vga_if vga_paddle_to_btn();
    vga_if vga_btn_to_title();
    vga_if vga_title_to_label();
    vga_if vga_label_to_mouse();
    vga_if vga_out_final();

    assign vga_tim_to_bg.rgb = 12'h0_0_0;

    
    assign vs = ~vga_out_final.vsync;
    assign hs = ~vga_out_final.hsync;
    assign {r, g, b} = vga_out_final.rgb;

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
     * Menu: button + top-level FSM
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
     * Placeholder, uproszczone elementy gry
     */

    logic [11:0] rect_x_ctl, rect_y_ctl;

    draw_rect_ctl u_rect_ctl (
        .clk(clk),
        .rst_n(rst_n),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted),
        .mouse_left(mouse_left & play_active),
        .rect_x(rect_x_ctl),
        .rect_y(rect_y_ctl)
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
        .vga_out(vga_bg_to_paddle.out)
    );

    draw_rect u_draw_rect (
        .clk    (clk),
        .rst_n  (rst_n),
        .active (play_active),
        .rect_x (rect_x_ctl),
        .rect_y (rect_y_ctl),
        .vga_in (vga_bg_to_paddle.in),
        .vga_out(vga_paddle_to_btn.out)
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
        .vga_in (vga_paddle_to_btn.in),
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
        .vga_in(vga_label_to_mouse.in),
        .vga_out(vga_out_final.out),
        .mouse_x(mouse_x_restricted),
        .mouse_y(mouse_y_restricted)
    );

endmodule
