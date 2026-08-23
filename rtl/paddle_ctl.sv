/**
 * 
 * Autor: JW
 *
 * Opis:
 * Sterowanie paletka: input x/y pozycja myszy, ograniczenie do polowy
 * plus paletka sterowana ai
 */

module paddle_ctl #(
    parameter int MIN_X = 0,
    parameter int MAX_X = 1023,
    parameter int MIN_Y = 0,
    parameter int MAX_Y = 767
)(
    input  logic clk,
    input  logic rst,

    input  logic [11:0] in_x,
    input  logic [11:0] in_y,

    output logic [11:0] paddle_x,
    output logic [11:0] paddle_y
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [11:0] clamped_x, clamped_y;

    always_comb begin
        if (in_x < MIN_X)
            clamped_x = MIN_X[11:0];
        else if (in_x > MAX_X)
            clamped_x = MAX_X[11:0];
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
