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
     * Pozycja tytulu AIRHOCKEY
     */
    localparam int TITLE_X = (HOR_PIXELS/2) - 128;
    localparam int TITLE_Y = 180;

endpackage
