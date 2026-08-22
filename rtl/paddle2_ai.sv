/**
 * 
 * Autor: JW
 *
 * Opis:
 * Placeholder dla drugiego gracz (brak mozliwosci testu z 2 plytka)
 * Podaza za pozycja krazka w osi y
 */

module paddle2_ai
    import game_pkg::*;
(
    input  logic clk,
    input  logic rst,
    input  logic frame_tick,

    input  logic [11:0] puck_y,

    output logic [11:0] ai_x,
    output logic [11:0] ai_y
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int AI_STEP = 2;  // px per frame tick

    logic [11:0] target_y;

    always_comb begin
        if (puck_y < PADDLE_MIN_Y)
            target_y = PADDLE_MIN_Y[11:0];
        else if (puck_y > PADDLE_MAX_Y)
            target_y = PADDLE_MAX_Y[11:0];
        else
            target_y = puck_y;
    end

    assign ai_x = P2_AI_X[11:0];

    always_ff @(posedge clk) begin
        if (rst) begin
            ai_y <= ((PADDLE_MIN_Y + PADDLE_MAX_Y) / 2);
        end else if (frame_tick) begin
            if (target_y > ai_y + AI_STEP)
                ai_y <= ai_y + AI_STEP;
            else if (target_y + AI_STEP < ai_y)
                ai_y <= ai_y - AI_STEP;
            else
                ai_y <= target_y;
        end
    end

endmodule
