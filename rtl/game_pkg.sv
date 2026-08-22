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
        ST_MENU = 2'b00,
        ST_PLAY = 2'b01
    } game_state_t;

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
     * Pozycja napisu ("AIR HOCKEY")
     */
    localparam int TITLE_X = (HOR_PIXELS/2) - 128;
    localparam int TITLE_Y = 180;

    /**
     * Geometria pola gry,
     */
    localparam int TABLE_X0 = 80;
    localparam int TABLE_X1 = HOR_PIXELS - 80;   // 944
    localparam int TABLE_Y0 = 60;
    localparam int TABLE_Y1 = VER_PIXELS - 60;   // 708
    localparam int MID_X    = (TABLE_X0 + TABLE_X1) / 2;

    // Bramki na krancach
    localparam int GOAL_H  = 220;
    localparam int GOAL_Y0 = (TABLE_Y0 + TABLE_Y1)/2 - GOAL_H/2;
    localparam int GOAL_Y1 = (TABLE_Y0 + TABLE_Y1)/2 + GOAL_H/2;

    /**
     * Paddles.
     */
    localparam int PADDLE_W = 16;
    localparam int PADDLE_H = 100;
    localparam int PADDLE_ZONE_GAP = 8;  // powstrzymuje przed przejsciem przez srodkowa linie

    localparam logic [11:0] PADDLE1_COLOR = 12'hF_0_0;  // red  - player 1 (left)
    localparam logic [11:0] PADDLE2_COLOR = 12'h0_0_F;  // blue - player 2 (right)

    localparam int P1_MIN_X = TABLE_X0;
    localparam int P1_MAX_X = MID_X - PADDLE_ZONE_GAP - PADDLE_W;
    localparam int P2_MIN_X = MID_X + PADDLE_ZONE_GAP;
    localparam int P2_MAX_X = TABLE_X1 - PADDLE_W;
    localparam int PADDLE_MIN_Y = TABLE_Y0;
    localparam int PADDLE_MAX_Y = TABLE_Y1 - PADDLE_H;

    
    localparam int P2_AI_X = TABLE_X1 - 60;

    /**
     * Krazek.
     */
    localparam int PUCK_SIZE = 20;
    localparam logic [11:0] PUCK_COLOR = 12'hF_F_F;
    localparam int PUCK_SPEED_INIT = 3;   // px per frame tick, each axis

    /**
     * Wyswietlanie wyniku.
     */
    localparam logic [11:0] SCORE_COLOR = 12'hF_F_0;
    localparam int SCORE1_X = MID_X - 40;
    localparam int SCORE2_X = MID_X + 32;
    localparam int SCORE_Y  = 20;

endpackage