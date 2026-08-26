/**
 * Copyright (C) 2025  AGH University of Science and Technology
/**
 * 
 * Autor: JW
 *
 * Opis:
 * Fizyka krazka. Pozycja aktualizowana raz na frame_tick.
 *
 * Serwis: krazek pojawia sie w pozycji stacjonarnej na srodku stolu
 * i oczekuje na popchniecie przez ktoras z paletek.
 *
 * Odbicie od scian nie powoduje zmiany predkosci krazka
 * Calkowte przekroczenie lini prawej lub lewej przez krazek 
 * Skutkuje zdobyciem gola
 *
 * Odbicie od paletki: dalszy wektor poruszania sie krazka w osi
 * Zalezy od pozycji krazka oraz paletki, zmiana predkosci
 * Uzalezniona od predkosci paletki
 */
module puck_ctl
    import game_pkg::*;
(
    input  logic clk,
    input  logic rst,
    input  logic frame_tick,
    input  logic active,    // przytrzymanie krazka na srodku stolu


    input  logic [11:0] p1_x, p1_y,
    input  logic [11:0] p2_x, p2_y,

    output logic [11:0] puck_x, puck_y,
    output logic goal_p1,        // 1: gracz 1 zdobywa
    output logic goal_p2,        // 1: gracz 2 zdobywa punkt
    output logic puck_served     // 0 do momentu kontaktu przy serwisie
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int SPAWN_X = MID_X - PUCK_SIZE/2;
    localparam int SPAWN_Y = CENTER_Y - PUCK_SIZE/2;

    logic signed [12:0] vx, vy;
    logic [11:0] p1_x_prev, p1_y_prev, p2_x_prev, p2_y_prev;

    function automatic logic paddle_hit(
        input logic [11:0] px, py,
        input logic [11:0] bx, by
    );
        paddle_hit = (px < bx + PADDLE_W) && (px + PUCK_SIZE > bx) &&
                     (py < by + PADDLE_H) && (py + PUCK_SIZE > by);
    endfunction

    function automatic logic signed [12:0] clamp_speed(input logic signed [12:0] v);
        if (v > PUCK_SPEED_MAX[12:0])
            clamp_speed = PUCK_SPEED_MAX[12:0];
        else if (v < -PUCK_SPEED_MAX[12:0])
            clamp_speed = -PUCK_SPEED_MAX[12:0];
        else
            clamp_speed = v;
    endfunction

    always_ff @(posedge clk) begin
        if (rst || !active) begin
            puck_x      <= SPAWN_X[11:0];
            puck_y      <= SPAWN_Y[11:0];
            vx          <= 0;
            vy          <= 0;
            goal_p1     <= 1'b0;
            goal_p2     <= 1'b0;
            puck_served <= 1'b0;
            p1_x_prev   <= p1_x; p1_y_prev <= p1_y;
            p2_x_prev   <= p2_x; p2_y_prev <= p2_y;
        end else begin
            goal_p1 <= 1'b0;
            goal_p2 <= 1'b0;

            if (frame_tick) begin
                logic signed [12:0] nx, ny, nvx, nvy;
                logic signed [12:0] p1_vx, p1_vy, p2_vx, p2_vy;
                logic signed [12:0] hit_offset, speed_mag;
                logic in_goal_y;

                p1_vx = $signed({1'b0, p1_x}) - $signed({1'b0, p1_x_prev});
                p1_vy = $signed({1'b0, p1_y}) - $signed({1'b0, p1_y_prev});
                p2_vx = $signed({1'b0, p2_x}) - $signed({1'b0, p2_x_prev});
                p2_vy = $signed({1'b0, p2_y}) - $signed({1'b0, p2_y_prev});

                p1_x_prev <= p1_x; p1_y_prev <= p1_y;
                p2_x_prev <= p2_x; p2_y_prev <= p2_y;

                nx  = $signed({1'b0, puck_x}) + vx;
                ny  = $signed({1'b0, puck_y}) + vy;
                nvx = vx;
                nvy = vy;

                // Top / bottom odbicie, brak zmiany predkosci.
                if (ny <= TABLE_Y0) begin
                    ny  = TABLE_Y0;
                    nvy = -vy;
                end else if (ny >= TABLE_Y1 - PUCK_SIZE) begin
                    ny  = TABLE_Y1 - PUCK_SIZE;
                    nvy = -vy;
                end

                // Kolizja z paletka, zapobiega powtarzaniu na kazdy tick
                if (nvx <= 0 && paddle_hit(nx[11:0], ny[11:0], p1_x, p1_y)) begin
                    hit_offset = ny + (PUCK_SIZE/2) - ($signed({1'b0, p1_y}) + (PADDLE_H/2));
                    speed_mag  = (nvx < 0 ? -nvx : nvx) + PUCK_SPEED_STEP +
                                 (p1_vx < 0 ? -p1_vx : p1_vx);
                    nvx = clamp_speed(speed_mag);
                    nvy = clamp_speed((p1_vy <<< 1) + (hit_offset >>> 3));
                    nx  = $signed({1'b0, p1_x}) + PADDLE_W;
                    puck_served <= 1'b1;
                end else if (nvx >= 0 && paddle_hit(nx[11:0], ny[11:0], p2_x, p2_y)) begin
                    hit_offset = ny + (PUCK_SIZE/2) - ($signed({1'b0, p2_y}) + (PADDLE_H/2));
                    speed_mag  = (nvx < 0 ? -nvx : nvx) + PUCK_SPEED_STEP +
                                 (p2_vx < 0 ? -p2_vx : p2_vx);
                    nvx = -clamp_speed(speed_mag);
                    nvy = clamp_speed((p2_vy <<< 1) + (hit_offset >>> 3));
                    nx  = $signed({1'b0, p2_x}) - PUCK_SIZE;
                    puck_served <= 1'b1;
                end

                // Detekcja bramki, odbicie od lewej i prawej sciany.
                in_goal_y = !((ny + PUCK_SIZE <= GOAL_Y0) || (ny >= GOAL_Y1));

                if (!in_goal_y) begin
                    
                    if (nx <= TABLE_X0) begin
                        nx  = TABLE_X0;
                        nvx = -nvx;
                    end else if (nx + PUCK_SIZE >= TABLE_X1) begin
                        nx  = TABLE_X1 - PUCK_SIZE;
                        nvx = -nvx;
                    end
                    puck_x <= nx[11:0];
                    puck_y <= ny[11:0];
                    vx     <= nvx;
                    vy     <= nvy;
                end else begin
                    
                    if (nx < TABLE_X0 - PUCK_SIZE) begin
                        goal_p2     <= 1'b1;
                        puck_x      <= SPAWN_X[11:0];
                        puck_y      <= SPAWN_Y[11:0];
                        vx          <= 0;
                        vy          <= 0;
                        puck_served <= 1'b0;
                    end else if (nx > TABLE_X1) begin
                        goal_p1     <= 1'b1;
                        puck_x      <= SPAWN_X[11:0];
                        puck_y      <= SPAWN_Y[11:0];
                        vx          <= 0;
                        vy          <= 0;
                        puck_served <= 1'b0;
                    end else begin
                        puck_x <= nx[11:0];
                        puck_y <= ny[11:0];
                        vx     <= nvx;
                        vy     <= nvy;
                    end
                end
            end
        end
    end

endmodule
