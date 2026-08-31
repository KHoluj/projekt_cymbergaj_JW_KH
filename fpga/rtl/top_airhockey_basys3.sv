/**
 * Autor: KH
 * Plik top basys3 gry airhockey
 */


module top_airhockey_basys3 (
        input  wire clk,
        input  wire btnC,
        input  wire btnL,
        input  wire sw0,

        inout wire PS2Clk,
        inout wire PS2Data,

        output wire ja_tx,
        input  wire ja_rx,
        output wire led0,

        output wire Vsync,
        output wire Hsync,
        output wire [3:0] vgaRed,
        output wire [3:0] vgaGreen,
        output wire [3:0] vgaBlue,
        output wire JA1
    );

    timeunit 1ns;
    timeprecision 1ps;

    /**
     * Local variables and signals
     */

    wire clk_pix, clk100MHz, locked;   
    wire pclk_mirror;

    /**
     * Signals assignments
     */

    assign JA1 = pclk_mirror;

    /**
     * FPGA submodules
     */

    
    clk_wiz_0 u_clk_wiz (
        .clk(clk),
        .clk_pix(clk_pix),
        .clk100MHz(clk100MHz),
        .locked(locked)
    );

    

    ODDR pclk_oddr (
        .Q(pclk_mirror),
        .C(clk_pix),
        .CE(1'b1),
        .D1(1'b1),
        .D2(1'b0),
        .R(1'b0),
        .S(1'b0)
    );

    /**
     * Project functional top module
     */

    top_airhockey u_top_airhockey (
        .clk(clk_pix),
        .clk100MHz(clk100MHz),
        .btn_rst(btnC),
        .btn_exit(btnL),
        .sw_is_host(sw0),

        .ps2_clk(PS2Clk),
        .ps2_data(PS2Data),

        .link_tx(ja_tx),
        .link_rx(ja_rx),
        .led_link_ok(led0),

        .r(vgaRed),
        .g(vgaGreen),
        .b(vgaBlue),
        .hs(Hsync),
        .vs(Vsync)
    );

endmodule
