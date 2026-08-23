/**
 * 
 * Autor: JW
 *
 * Opis:
 * Fizyka krazka. Pozycja aktualizowana na frame_tick
 * Odbicie od krawedzi, bramka na lewej i prawej (testowo)
 * Przejscie przez krawedz bramki skutkuje golem
 * predkosc krazka zmienia sie podczas kolizji z paletka
 *
 * Predkosc zamieniana na liczbe calkowitra o kroku px/frame 
 * jedna stala predkosc
 */

module puck_ctl
    import game_pkg::*;
(
    input  logic clk,
    input  logic rst,
    input  logic frame_tick,
    input  logic active,   

    input  logic [11:0] p1_x, p1_y,
    input  logic [11:0] p2_x, p2_y,

    output logic [11:0] puck_x, puck_y,
    output logic goal_p1,   // 1-cycle pulse: gracz 1 zdobywa punkt (krazek przekroczyl linie TABLE_X1)
    output logic goal_p2    // 1-cycle pulse: gracz 2 zdobywa punkt (krazek przekroczyl linie TABLE_X0)
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int CENTER_X = MID_X - PUCK_SIZE/2;
    localparam int CENTER_Y = (TABLE_Y0 + TABLE_Y1)/2 - PUCK_SIZE/2;

    logic signed [12:0] vx, vy;

    function automatic logic paddle_hit(
        input logic [11:0] px, py,
        input logic [11:0] bx, by
    );
        paddle_hit = (px < bx + PADDLE_W) && (px + PUCK_SIZE > bx) &&
                     (py < by + PADDLE_H) && (py + PUCK_SIZE > by);
    endfunction

    // Zwraca predkosc + PUCK_SPEED_STEP, ograniczenie na PUCK_SPEED_MAX.
    function automatic logic signed [12:0] speed_up(input logic signed [12:0] speed);
        logic signed [12:0] mag, boosted;
        mag     = (speed < 0) ? -speed : speed;
        boosted = mag + PUCK_SPEED_STEP;
        speed_up = (boosted > PUCK_SPEED_MAX) ? PUCK_SPEED_MAX : boosted;
    endfunction

    always_ff @(posedge clk) begin
        if (rst || !active) begin
            puck_x  <= CENTER_X[11:0];
            puck_y  <= CENTER_Y[11:0];
            vx      <= -PUCK_SPEED_INIT;
            vy      <= PUCK_SPEED_INIT;
            goal_p1 <= 1'b0;
            goal_p2 <= 1'b0;
        end else begin
            goal_p1 <= 1'b0;
            goal_p2 <= 1'b0;

            if (frame_tick) begin
                logic signed [12:0] nx, ny, nvx, nvy;

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
                if (nvx < 0 && paddle_hit(nx[11:0], ny[11:0], p1_x, p1_y)) begin
                    nvx = speed_up(nvx);              
                    nx  = $signed({1'b0, p1_x}) + PADDLE_W;
                end else if (nvx > 0 && paddle_hit(nx[11:0], ny[11:0], p2_x, p2_y)) begin
                    nvx = -speed_up(nvx);              
                    nx  = $signed({1'b0, p2_x}) - PUCK_SIZE;
                end

                // Detekcja bramki
                if (nx < TABLE_X0 - PUCK_SIZE) begin
                    goal_p2 <= 1'b1;
                    puck_x  <= CENTER_X[11:0];
                    puck_y  <= CENTER_Y[11:0];
                    vx      <= PUCK_SPEED_INIT;
                    vy      <= nvy;
                end else if (nx > TABLE_X1) begin
                    goal_p1 <= 1'b1;
                    puck_x  <= CENTER_X[11:0];
                    puck_y  <= CENTER_Y[11:0];
                    vx      <= -PUCK_SPEED_INIT;
                    vy      <= nvy;
                end else begin
                    puck_x <= nx[11:0];
                    puck_y <= ny[11:0];
                    vx     <= nvx;
                    vy     <= nvy;
                end
            end
        end
    end

endmodule
