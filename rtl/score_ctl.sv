/**
 * 
 * Autor: KH
 *
 * Opis:
 * Wynik dwu cyfrowy
 */

module score_ctl (
    input  logic clk,
    input  logic rst,

    input  logic goal_p1,
    input  logic goal_p2,

    output logic [3:0] score_p1,
    output logic [3:0] score_p2
);

    timeunit 1ns;
    timeprecision 1ps;

    always_ff @(posedge clk) begin
        if (rst) begin
            score_p1 <= 4'd0;
            score_p2 <= 4'd0;
        end else begin
            if (goal_p1 && score_p1 < 4'd9)
                score_p1 <= score_p1 + 4'd1;
            if (goal_p2 && score_p2 < 4'd9)
                score_p2 <= score_p2 + 4'd1;
        end
    end

endmodule
