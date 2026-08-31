/**
 * 
 * Autor: JW
 *
 * Opis:
 * Implementacja ai gracza
 */


module paddle2_ai
    import game_pkg::*;
(
    input  logic clk,
    input  logic rst,
    input  logic frame_tick,
    input  logic puck_served,
    input  logic exclude_me,      
    input  logic [3:0] ai_step,   

    input  logic [11:0] puck_x, puck_y,
    input  logic [11:0] p1_y,     

    output logic [11:0] ai_x,
    output logic [11:0] ai_y
);

    timeunit 1ns;
    timeprecision 1ps;


    localparam int ZONE_W = P2_MAX_X - P2_MIN_X;

    localparam logic [11:0] HOME_X   = P2_MIN_X + (3*ZONE_W)/4;  
    localparam logic [11:0] HOME_Y   = (PADDLE_MIN_Y + PADDLE_MAX_Y) / 2;
    localparam logic [11:0] AIM_BIAS = PADDLE_H / 2;

    // Threshold zaleznie od trudnosci
    localparam logic [11:0] EASY_ENGAGE   = P2_MIN_X + (2*ZONE_W)/3;  
    localparam logic [11:0] NORMAL_ENGAGE = MID_X + 20;               
    localparam logic [11:0] HARD_ENGAGE   = MID_X - 40;               
    localparam logic [11:0] HYSTERESIS    = 40;

    logic [11:0] engage_thresh, disengage_thresh;

    always_comb begin
        case (ai_step)
            4'd1:    engage_thresh = EASY_ENGAGE;
            4'd2:    engage_thresh = NORMAL_ENGAGE;
            default: engage_thresh = HARD_ENGAGE;
        endcase
    end

    assign disengage_thresh = (engage_thresh > HYSTERESIS) ? (engage_thresh - HYSTERESIS) : 12'd0;

    logic engaged;
    logic [11:0] target_x, target_y;
    logic [11:0] puck_x_clamped, puck_y_clamped;

    always_comb begin
        if (puck_x > P2_MAX_X)
            puck_x_clamped = P2_MAX_X[11:0];
        else if (puck_x < P2_MIN_X)
            puck_x_clamped = P2_MIN_X[11:0];
        else
            puck_x_clamped = puck_x;

        if (puck_y < PADDLE_MIN_Y)
            puck_y_clamped = PADDLE_MIN_Y[11:0];
        else if (puck_y > PADDLE_MAX_Y)
            puck_y_clamped = PADDLE_MAX_Y[11:0];
        else
            puck_y_clamped = puck_y;
    end

    always_comb begin
        if (exclude_me) begin
            
            target_x = HOME_X;
            target_y = HOME_Y;
        end else if (!puck_served) begin
            
            target_x = puck_x_clamped;
            target_y = puck_y_clamped;
        end else if (engaged) begin
            
            target_x = puck_x_clamped;
            if (p1_y < HOME_Y) begin
                target_y = (puck_y + AIM_BIAS > PADDLE_MAX_Y) ? PADDLE_MAX_Y[11:0] : puck_y + AIM_BIAS;
            end else begin
                target_y = (puck_y < PADDLE_MIN_Y + AIM_BIAS) ? PADDLE_MIN_Y[11:0] : puck_y - AIM_BIAS;
            end
        end else begin
            
            target_x = HOME_X;
            target_y = puck_y_clamped;
        end
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            ai_x    <= HOME_X;
            ai_y    <= HOME_Y;
            engaged <= 1'b0;
        end else if (frame_tick) begin
            if (!puck_served)
                engaged <= 1'b0;
            else if (!engaged && (puck_x >= engage_thresh))
                engaged <= 1'b1;
            else if (engaged && (puck_x < disengage_thresh))
                engaged <= 1'b0;

            if (target_x > ai_x + ai_step)
                ai_x <= ai_x + ai_step;
            else if (target_x + ai_step < ai_x)
                ai_x <= ai_x - ai_step;
            else
                ai_x <= target_x;

            if (target_y > ai_y + ai_step)
                ai_y <= ai_y + ai_step;
            else if (target_y + ai_step < ai_y)
                ai_y <= ai_y - ai_step;
            else
                ai_y <= target_y;
        end
    end

endmodule
