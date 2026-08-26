/**
/**
 * 
 * Autor: JW
 *
 * Opis:
 * Ustawienia gry:
 * - win_score: okresla ilosc zdobytych goli potrzebnych do wygrania
 * 3/ 5/ 7/ 9,
 * - difficulty_sel: ustawia trudnosc gracza AI
 * EASY/ NORMAL/ HARD
 */

module settings_ctl (
    input  logic clk,
    input  logic rst,

    input  logic win_score_click,
    input  logic difficulty_click,

    output logic [3:0] win_score,
    output logic [1:0] difficulty_sel,   
    output logic [3:0] ai_step
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [1:0] win_score_idx;

    always_ff @(posedge clk) begin
        if (rst) begin
            win_score_idx  <= 2'd2;   
            difficulty_sel <= 2'd1;   
        end else begin
            if (win_score_click)
                win_score_idx <= win_score_idx + 2'd1;  

            if (difficulty_click) begin
                if (difficulty_sel == 2'd2)
                    difficulty_sel <= 2'd0;
                else
                    difficulty_sel <= difficulty_sel + 2'd1;
            end
        end
    end

    always_comb begin
        case (win_score_idx)
            2'd0:    win_score = 4'd3;
            2'd1:    win_score = 4'd5;
            2'd2:    win_score = 4'd7;
            default: win_score = 4'd9;
        endcase
    end

    always_comb begin
        case (difficulty_sel)
            2'd0:    ai_step = 4'd1;   // EASY
            2'd1:    ai_step = 4'd2;   // NORMAL
            default: ai_step = 4'd4;   // HARD
        endcase
    end

endmodule
