/**
 * 
 * Autor: JW
 * 
 * Opis:
 * Modul tworzy jednocyklowy 'frame_tick' raz na klatke video
 * uzyte do fizyki paletek i krazka, niezaleznie od pixel-clock
 */

module frame_tick_gen (
    input  logic clk,
    input  logic rst,
    input  logic vsync,
    output logic frame_tick
);

    timeunit 1ns;
    timeprecision 1ps;

    logic vsync_d;

    always_ff @(posedge clk) begin
        if (rst) begin
            vsync_d    <= 1'b0;
            frame_tick <= 1'b0;
        end else begin
            vsync_d    <= vsync;
            frame_tick <= vsync & ~vsync_d;
        end
    end

endmodule
