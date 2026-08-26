/**
/**
 * 
 * Autor: JW
 *
 * Opis:
 * Wynik dwucyfrowy
 */


module score_ctl (
    input  logic clk,
    input  logic rst,
    input  logic clear,

    input  logic goal_p1,
    input  logic goal_p2,

    output logic [3:0] score_p1_tens,
    output logic [3:0] score_p1_ones,
    output logic [3:0] score_p2_tens,
    output logic [3:0] score_p2_ones
);

    timeunit 1ns;
    timeprecision 1ps;

    always_ff @(posedge clk) begin
        if (rst || clear) begin
            score_p1_tens <= 4'd0;
            score_p1_ones <= 4'd0;
        end else if (goal_p1) begin
            if (score_p1_tens == 4'd9 && score_p1_ones == 4'd9) begin
                
            end else if (score_p1_ones == 4'd9) begin
                score_p1_ones <= 4'd0;
                score_p1_tens <= score_p1_tens + 4'd1;
            end else begin
                score_p1_ones <= score_p1_ones + 4'd1;
            end
        end
    end

    always_ff @(posedge clk) begin
        if (rst || clear) begin
            score_p2_tens <= 4'd0;
            score_p2_ones <= 4'd0;
        end else if (goal_p2) begin
            if (score_p2_tens == 4'd9 && score_p2_ones == 4'd9) begin
                
            end else if (score_p2_ones == 4'd9) begin
                score_p2_ones <= 4'd0;
                score_p2_tens <= score_p2_tens + 4'd1;
            end else begin
                score_p2_ones <= score_p2_ones + 4'd1;
            end
        end
    end

endmodule
