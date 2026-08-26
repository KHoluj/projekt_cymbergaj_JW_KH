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
        ST_GAME_OVER = 2'b10
    } game_state_t;

    /**
     * Przycisk dzielony pomiedzy start gry w ST_MENU oraz wyjscie do menu
     * w ST_GAME_OVER
     */
    localparam int BTN_W = 160;
    localparam int BTN_H = 56;
    localparam int BTN_X = (HOR_PIXELS/2) - (BTN_W/2);
    localparam int BTN_Y = 380;

    localparam logic [11:0] BTN_FILL_COLOR   = 12'h2_6_A;
    localparam logic [11:0] BTN_BORDER_COLOR = 12'hF_F_F;

    // Napis dzielonego przycisku ("START"/"MENU")
    localparam int BTN_LABEL_W = 48;   // 6 chars * 8 px
    localparam int BTN_LABEL_H = 16;   // 1 char row
    localparam int BTN_LABEL_X = BTN_X + (BTN_W - BTN_LABEL_W)/2;
    localparam int BTN_LABEL_Y = BTN_Y + (BTN_H - BTN_LABEL_H)/2;

    /**
     * Pozycja napisu ("AIR HOCKEY") w ST_MENU,
     * "PLAYER 1 WINS!" / "PLAYER 2 WINS!" w ST_GAME_OVER 
     */
    localparam int TITLE_X = (HOR_PIXELS/2) - 128;
    localparam int TITLE_Y = 180;

    /**
     * Przycisk "EXIT" do wyjscia z gry w ST_PLAY
     */
    localparam int EXIT_BTN_W = 90;
    localparam int EXIT_BTN_H = 32;
    localparam int EXIT_BTN_X = HOR_PIXELS - EXIT_BTN_W - 20;
    localparam int EXIT_BTN_Y = 16;

    localparam int EXIT_LABEL_W = 32;  // 4 chars * 8 px ("EXIT")
    localparam int EXIT_LABEL_H = 16;
    localparam int EXIT_LABEL_X = EXIT_BTN_X + (EXIT_BTN_W - EXIT_LABEL_W)/2;
    localparam int EXIT_LABEL_Y = EXIT_BTN_Y + (EXIT_BTN_H - EXIT_LABEL_H)/2;

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

    
    localparam int CENTER_Y = (TABLE_Y0 + TABLE_Y1) / 2;
    localparam int CENTER_CIRCLE_RADIUS = 70;

     /**
     * Paletki.
     */
    localparam int PADDLE_SIZE = 40;
    localparam int PADDLE_W = PADDLE_SIZE;
    localparam int PADDLE_H = PADDLE_SIZE;
    localparam int PADDLE_ZONE_GAP = 8;  // powstrzymuje przed przejsciem przez srodkowa linie

    localparam logic [11:0] PADDLE1_COLOR         = 12'hF_0_0;  // czerwony  - gracz 1 (lewo)
    localparam logic [11:0] PADDLE1_HILIGHT_COLOR = 12'hF_9_9;
    localparam logic [11:0] PADDLE2_COLOR         = 12'h0_0_F;  // niebieski - gracz 2 (prawo)
    localparam logic [11:0] PADDLE2_HILIGHT_COLOR = 12'h9_9_F;

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
    localparam int PUCK_SIZE = 24;
    localparam logic [11:0] PUCK_COLOR         = 12'hC_C_C;  
    localparam logic [11:0] PUCK_HILIGHT_COLOR = 12'hF_F_F;  

    // Zmiana predkosci krazka podczas odbicia od paletki
    // brak zmiany podczas odbicia od sciany
    localparam int PUCK_SPEED_STEP = 1;
    localparam int PUCK_SPEED_MAX  = 9;

   /**
     * Wyswietlanie wyniku.
     */
    localparam logic [11:0] SCORE_COLOR = 12'hF_F_0;
    localparam int SCORE_DIGIT_GAP = 10;  

    localparam int SCORE1_ONES_X = MID_X - 40;
    localparam int SCORE1_TENS_X = SCORE1_ONES_X - SCORE_DIGIT_GAP;
    localparam int SCORE2_TENS_X = MID_X + 32;
    localparam int SCORE2_ONES_X = SCORE2_TENS_X + SCORE_DIGIT_GAP;
    localparam int SCORE_Y  = 20;

    /**
     * Kondycja wygranej
     */
    localparam int WIN_SCORE = 7;

endpackage
