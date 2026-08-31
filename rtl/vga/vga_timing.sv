
/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Vga timing controller.
 */
 
module vga_timing (
        input  logic clk,
        input  logic rst_n,
        output logic [10:0] vcount,
        output logic vsync,
        output logic vblnk,
        output logic [10:0] hcount,
        output logic hsync,
        output logic hblnk
    );

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


    /**
     * Local variables and signals
     */
    logic [10:0] vcount_nxt;
    logic [10:0] hcount_nxt;
    logic vsync_nxt;
    logic vblnk_nxt;
    logic hsync_nxt;
    logic hblnk_nxt;

    // Add your signals and variables here.


    /**
     * Internal logic
     */

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            hcount <= 0;
            vcount <= 0;
            hblnk <= 0;
            hsync <= 0;
            vblnk <= 0;
            vsync <= 0;
        end else begin
            hcount <= hcount_nxt;
            vcount <= vcount_nxt;
            hsync  <= hsync_nxt;
            hblnk  <= hblnk_nxt;
            vsync  <= vsync_nxt;
            vblnk  <= vblnk_nxt;
        end
    end

    always_comb begin
        if (hcount == HOR_TOTAL_TIME - 1) begin
            hcount_nxt = 0;
            if (vcount == VER_TOTAL_TIME - 1)
                vcount_nxt = 0;
            else
                vcount_nxt = vcount + 1; 
        end else begin
            hcount_nxt = hcount + 1;
            vcount_nxt = vcount;
        end
        vblnk_nxt = (vcount_nxt >= VER_PIXELS);
        hblnk_nxt = (hcount_nxt >= HOR_PIXELS);

        hsync_nxt = (hcount_nxt >= HOR_SYNC_START) && (hcount_nxt < HOR_SYNC_START + HOR_SYNC_TIME) ;
        vsync_nxt = (vcount_nxt >= VER_SYNC_START) && (vcount_nxt < VER_SYNC_START + VER_SYNC_TIME);
    end
endmodule
