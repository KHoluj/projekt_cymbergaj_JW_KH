/**
 * 
 * Autor: KH
 *
 * 
 */

module draw_rect (
    input  logic clk,
    input  logic rst_n,
    input  logic active,   
    input  logic [11:0] rect_x,
    input logic  [11:0] rect_y,
    vga_if.in  vga_in, 
    vga_if.out vga_out
);

    // ----------------------
    // Local rect param
    // ----------------------

    localparam int RECT_W     = 48;         
    localparam int RECT_H     = 64;         
   
    // ----------------------
    // Pipeline
    // ----------------------
    
    logic [10:0] h_d1, h_d2;
    logic [10:0] v_d1, v_d2;
    logic hsync_d1, hsync_d2;
    logic vsync_d1, vsync_d2;
    logic hblnk_d1, hblnk_d2;
    logic vblnk_d1, vblnk_d2;
    logic [11:0] rgb_d1, rgb_d2;

    always_ff @(posedge clk) begin
        
        h_d1 <= vga_in.hcount;
        v_d1 <= vga_in.vcount;
        hsync_d1 <= vga_in.hsync;
        vsync_d1 <= vga_in.vsync;
        hblnk_d1 <= vga_in.hblnk;
        vblnk_d1 <= vga_in.vblnk;
        rgb_d1   <= vga_in.rgb;

        
        h_d2 <= h_d1;
        v_d2 <= v_d1;
        hsync_d2 <= hsync_d1;
        vsync_d2 <= vsync_d1;
        hblnk_d2 <= hblnk_d1;
        vblnk_d2 <= vblnk_d1;
        rgb_d2   <= rgb_d1;
    end

    // -----------
    // Coords
    // -----------

    logic [5:0] x_d1, x_d2;
    logic [5:0] y_d1, y_d2;
    logic inside_d1, inside_d2;

    always_ff @(posedge clk) begin
        x_d1 <= h_d1 - rect_x;
        y_d1 <= v_d1 - rect_y;

        x_d2 <= x_d1;
        y_d2 <= y_d1;

        inside_d1 <= active &&
                     (h_d1 >= rect_x) &&
                     (h_d1 < rect_x + RECT_W) &&
                     (v_d1 >= rect_y) &&
                     (v_d1 < rect_y + RECT_H);

        inside_d2 <= inside_d1;
    end

    // -----------
    // ROM
    // -----------

    logic [11:0] pixel_data;
    logic [11:0] rom_addr;

    assign rom_addr = {y_d1, x_d1};

    image_rom u_rom (
        .clk(clk),
        .address(rom_addr),
        .rgb(pixel_data)
    );



    logic [11:0] rgb_nxt;
    always_comb begin
        rgb_nxt = rgb_d2;

        if (!hblnk_d2 && !vblnk_d2 && inside_d2) begin

            if (x_d2 == 0)
                rgb_nxt = 12'h0_F_0;
            else if (x_d2 == RECT_W-1)
                rgb_nxt = 12'h0_0_F;
            else if (y_d2 == 0)
                rgb_nxt = 12'hF_F_0;
            else if (y_d2 == RECT_H-1)
                rgb_nxt = 12'hF_0_0;
            else
                rgb_nxt = pixel_data;
        end
    end


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            vga_out.vcount <= 0;
            vga_out.hcount <= 0;
            vga_out.vsync  <= 0;
            vga_out.hsync  <= 0;
            vga_out.vblnk  <= 0;
            vga_out.hblnk  <= 0;
            vga_out.rgb    <= 0;
        end else begin
            vga_out.vcount <= v_d2;
            vga_out.hcount <= h_d2;
            vga_out.vsync  <= vsync_d2;
            vga_out.hsync  <= hsync_d2;
            vga_out.vblnk  <= vblnk_d2;
            vga_out.hblnk  <= hblnk_d2;
            vga_out.rgb    <= rgb_nxt;
        end
    end

endmodule