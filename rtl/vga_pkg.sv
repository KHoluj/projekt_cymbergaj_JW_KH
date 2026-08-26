/**
 * Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Package with vga related constants.
 */

package vga_pkg;

    // Parameters for VGA Display 1024 x 768 @ 60fps using a 65 MHz pixel clock.
    localparam HOR_PIXELS = 1024;
    localparam VER_PIXELS = 768;

    
    localparam HOR_TOTAL_TIME = 1344;  // 1024 + 24 (fp) + 136 (sync) + 160 (bp)
    localparam HOR_SYNC_START = 1048;  // 1024 + 24
    localparam HOR_SYNC_TIME = 136;

    localparam VER_TOTAL_TIME = 806;   // 768 + 3 (fp) + 6 (sync) + 29 (bp)
    localparam VER_SYNC_START = 771;   // 768 + 3
    localparam VER_SYNC_TIME = 6;
endpackage
