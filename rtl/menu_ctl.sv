/**
 * 
 * Autor: KH
 *
 * Opis:
 * Generyczny przycisk, click-edge wykrywanie, poprzez pozycje myszy
 */


module menu_ctl #(
    parameter int BTN_X = 0,
    parameter int BTN_Y = 0,
    parameter int BTN_W = 0,
    parameter int BTN_H = 0
)(
    input  logic clk,
    input  logic rst,

    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic mouse_left,

    output logic hover,        // 1 gdy kursor jest nad przyciskiem
    output logic click_pulse   // 1-cycle puls gdy wcisniety lpm nad przyciskiem
);

    timeunit 1ns;
    timeprecision 1ps;

    logic mouse_left_d;

    always_ff @(posedge clk) begin
        if (rst) begin
            mouse_left_d <= 1'b0;
            hover        <= 1'b0;
        end else begin
            mouse_left_d <= mouse_left;
            hover <= (mouse_x >= BTN_X) && (mouse_x < BTN_X + BTN_W) &&
                     (mouse_y >= BTN_Y) && (mouse_y < BTN_Y + BTN_H);
        end
    end

    assign click_pulse = hover & mouse_left & ~mouse_left_d;

endmodule
