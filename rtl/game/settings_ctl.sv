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
 * Trub: solo : 2p
 */

module settings_ctl
    import game_pkg::*;
(
    input  logic clk,
    input  logic rst,

    input  logic win_score_inc, win_score_dec,
    input  logic difficulty_inc, difficulty_dec,
    input  logic mode_inc, mode_dec,

    output logic [3:0] win_score,
    output logic [1:0] difficulty_sel,   
    output logic [3:0] ai_step,
    output logic        mode_sel         
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [1:0] win_score_idx;

    always_ff @(posedge clk) begin
        if (rst) begin
            win_score_idx  <= 2'd2;   // default: 7 
            difficulty_sel <= 2'd1;   // default: NORMAL
            mode_sel       <= 1'b0;   // default: SOLO 
        end else begin
            
            if (win_score_inc)
                win_score_idx <= win_score_idx + 2'd1;
            else if (win_score_dec)
                win_score_idx <= win_score_idx - 2'd1;

            
            if (difficulty_inc) begin
                if (difficulty_sel == 2'd2)
                    difficulty_sel <= 2'd0;
                else
                    difficulty_sel <= difficulty_sel + 2'd1;
            end else if (difficulty_dec) begin
                if (difficulty_sel == 2'd0)
                    difficulty_sel <= 2'd2;
                else
                    difficulty_sel <= difficulty_sel - 2'd1;
            end

            if (mode_inc || mode_dec)
                mode_sel <= ~mode_sel;
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
