/**
 * 
 * Autor: KH
 *
 * Opis:
 * Paczka z parametrami i stanami do gry cymbergaj
 */

package game_pkg;

    import vga_pkg::*;

    // FSM states, top level.
    typedef enum logic [1:0] {
        ST_MENU      = 2'b00,
        ST_PLAY      = 2'b01,
        ST_GOAL      = 2'b10,
        ST_GAME_OVER = 2'b11
    } game_state_t;

    /**
     * Geometria pola gry, paletki i krazek
     * Dzielone przez kontrolery (paddle_button_ctl, puck_ctl, score_ctl)
     */
    localparam int PADDLE_W = 16;
    localparam int PADDLE_H = 120;
    localparam int PADDLE_L_X = 40;
    localparam int PADDLE_R_X = HOR_PIXELS - 40 - PADDLE_W;
    localparam int PADDLE_Y_MIN = 0;
    localparam int PADDLE_Y_MAX = VER_PIXELS - PADDLE_H;

    localparam logic [11:0] PADDLE_L_COLOR = 12'h0_F_F;   // cyan
    localparam logic [11:0] PADDLE_R_COLOR = 12'hF_8_0;   // orange

    localparam int PUCK_SIZE = 20;
    localparam logic [11:0] PUCK_COLOR = 12'hF_F_F;       // white

    // Pierwszy do WIN_SCORE wygrywa mecz.
    localparam int WIN_SCORE = 7;

    /**
     * Przycisk "START", wartosci w menu gry.
     */
    localparam int BTN_W = 160;
    localparam int BTN_H = 56;
    localparam int BTN_X = (HOR_PIXELS/2) - (BTN_W/2);
    localparam int BTN_Y = 380;

    localparam logic [11:0] BTN_FILL_COLOR   = 12'h2_6_A;
    localparam logic [11:0] BTN_BORDER_COLOR = 12'hF_F_F;

    // Napis przycisku ("START")
    localparam int BTN_LABEL_W = 48;   // 6 chars * 8 px
    localparam int BTN_LABEL_H = 16;   // 1 char row
    localparam int BTN_LABEL_X = BTN_X + (BTN_W - BTN_LABEL_W)/2;
    localparam int BTN_LABEL_Y = BTN_Y + (BTN_H - BTN_LABEL_H)/2;

    /**
     * Pozycja tytulu AIRHOCKEY
     */
    localparam int TITLE_X = (HOR_PIXELS/2) - 128;
    localparam int TITLE_Y = 180;

endpackage