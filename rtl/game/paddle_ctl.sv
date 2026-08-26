/**
 * 
 * Autor: JW
 *
 * Opis:
 * Sterowanie paletka: input x/y pozycja myszy, ograniczenie do polowy
 * 
 */

module paddle_ctl #(
    parameter int MIN_X = 0,
    parameter int MAX_X = 1023,
    parameter int MIN_Y = 0,
    parameter int MAX_Y = 767,
    parameter int EXCLUDED_MIN_X = MIN_X,
    parameter int EXCLUDED_MAX_X = MAX_X,
    parameter bit TIGHTEN_MIN = 1'b0,   
    parameter bit TIGHTEN_MAX = 1'b0    
)(
    input  logic clk,
    input  logic rst,

    input  logic exclude_center,

    input  logic [11:0] in_x,
    input  logic [11:0] in_y,

    output logic [11:0] paddle_x,
    output logic [11:0] paddle_y
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [11:0] eff_min_x, eff_max_x;

    assign eff_min_x = (exclude_center && TIGHTEN_MIN) ? EXCLUDED_MIN_X[11:0] : MIN_X[11:0];
    assign eff_max_x = (exclude_center && TIGHTEN_MAX) ? EXCLUDED_MAX_X[11:0] : MAX_X[11:0];

    logic [11:0] clamped_x, clamped_y;

    always_comb begin
        if (in_x < eff_min_x)
            clamped_x = eff_min_x;
        else if (in_x > eff_max_x)
            clamped_x = eff_max_x;
        else
            clamped_x = in_x;

        if (in_y < MIN_Y)
            clamped_y = MIN_Y[11:0];
        else if (in_y > MAX_Y)
            clamped_y = MAX_Y[11:0];
        else
            clamped_y = in_y;
    end

    always_ff @(posedge clk) begin
        if (rst) begin
            paddle_x <= MIN_X[11:0];
            paddle_y <= ((MIN_Y + MAX_Y) / 2);
        end else begin
            paddle_x <= clamped_x;
            paddle_y <= clamped_y;
        end
    end

endmodule
