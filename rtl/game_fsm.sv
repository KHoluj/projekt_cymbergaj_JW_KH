/**
 * 
 * Autor: KH
 *
 * Opis:
 * Top level fsm, uklad testowy:
 * AKTAULNIE: MENU -> GRA, brak powrotu, test fsm
 */

module game_fsm
    import game_pkg::*;
(
    input  logic clk,
    input  logic rst,

    input  logic start_click,   // pulse: nacisniecie przycisku start

    output game_state_t game_state
);

    timeunit 1ns;
    timeprecision 1ps;

    always_ff @(posedge clk) begin
        if (rst) begin
            game_state <= ST_MENU;
        end else begin
            unique case (game_state)
                ST_MENU: if (start_click) game_state <= ST_PLAY;
                ST_PLAY: ; // no way back yet
                default: game_state <= ST_MENU;
            endcase
        end
    end

endmodule
