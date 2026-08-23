/**
 * 
 * Autor: KH
 *
 * Opis:
 * Top level fsm:
 * 
 *
 *   ST_MENU:      przejscie do gry poprzez przycisk, zaczecie 
 *                 z wyniku 0-0.
 *   ST_PLAY:      stan gry faktycznej, po osiagnieciu wymaganej 
 *                 liczby punktow gra przechodzi do stanu ST_GAME_OVER,
 *                 mozliwosc wyjscia do menu przez przycisk
 *   ST_GAME_OVER: wcisniecie przyciksku menu powraca do menu gry
 */

module game_fsm
    import game_pkg::*;
(
    input  logic clk,
    input  logic rst,

    input  logic start_click,   // dzielony przycisk, interpretacja w ST_MENU
    input  logic menu_click,    // dzielony przycisk, interpretacja w ST_GAME_OVER
    input  logic exit_click,    // przycisk EXIT, interpretacja w ST_PLAY

    input  logic [3:0] score_p1_tens, score_p1_ones,
    input  logic [3:0] score_p2_tens, score_p2_ones,

    output game_state_t game_state,
    output logic winner_p2,     // 0 = wygral gracz 1, 1 = wygral gracz 2 (wyswietlanie w ST_GAME_OVER)
    output logic score_clear    // 1-cycle pulse: czysci wynik (nowa gra)
);

    timeunit 1ns;
    timeprecision 1ps;

    logic p1_won, p2_won;

    assign p1_won = (score_p1_tens > 4'd0) || (score_p1_ones >= WIN_SCORE[3:0]);
    assign p2_won = (score_p2_tens > 4'd0) || (score_p2_ones >= WIN_SCORE[3:0]);

    always_ff @(posedge clk) begin
        if (rst) begin
            game_state  <= ST_MENU;
            winner_p2   <= 1'b0;
            score_clear <= 1'b0;
        end else begin
            score_clear <= 1'b0;

            unique case (game_state)
                ST_MENU: begin
                    if (start_click) begin
                        game_state  <= ST_PLAY;
                        score_clear <= 1'b1;
                    end
                end

                ST_PLAY: begin
                    if (p1_won) begin
                        game_state <= ST_GAME_OVER;
                        winner_p2  <= 1'b0;
                    end else if (p2_won) begin
                        game_state <= ST_GAME_OVER;
                        winner_p2  <= 1'b1;
                    end else if (exit_click) begin
                        game_state <= ST_MENU;
                    end
                end

                ST_GAME_OVER: begin
                    if (menu_click) game_state <= ST_MENU;
                end

                default: game_state <= ST_MENU;
            endcase
        end
    end

endmodule
