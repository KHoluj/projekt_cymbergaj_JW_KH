/**
 * Autor: KH
 * Plik top gry airhockey
 */

module top_airhockey_basys3 (
        input  wire clk,
        input  wire btnC,
        inout wire PS2Clk,
        inout wire PS2Data,
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

    wire clk40MHz, clk100MHz, locked;
    wire pclk_mirror;

    /**
     * Signals assignments
     */

    assign JA1 = pclk_mirror;

    /**
     * FPGA submodules placement
     */

    clk_wiz_0 u_clk_wiz (
        .clk(clk),
        .clk40MHz(clk40MHz),
        .clk100MHz(clk100MHz),
        .locked(locked)
    );

    // Mirror pclk on a pin for use by the testbench;
    // not functionally required for this design to work.

    ODDR pclk_oddr (
        .Q(pclk_mirror),
        .C(clk40MHz),
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
        .clk(clk40MHz),
        .clk100MHz(clk100MHz),
        .btn_rst(btnC),

        .ps2_clk(PS2Clk),
        .ps2_data(PS2Data),

        .r(vgaRed),
        .g(vgaGreen),
        .b(vgaBlue),
        .hs(Hsync),
        .vs(Vsync)
    );

endmodule
