/**
 *  Copyright (C) 2025  AGH University of Science and Technology
 * MTM UEC2
 * Author: Piotr Kaczmarczyk
 *
 * Description:
 * Testbench for vga_timing module.
 */

module vga_timing_tb;

    timeunit 1ns;
    timeprecision 1ps;

    import vga_pkg::*;


    /**
     *  Local parameters
     */

    localparam CLK_PERIOD = 25;     // 40 MHz
    localparam RST_START_TIME  = 1.25*CLK_PERIOD;
    localparam RST_ACTIVE_TIME = 2.00*CLK_PERIOD;


    /**
     * Local variables and signals
     */

    logic clk;
    logic rst_n;

    wire [10:0] vcount, hcount;
    wire        vsync,  hsync;
    wire        vblnk,  hblnk;


    /**
     * Clock generation
     */

    initial begin
        clk = 1'b0;
        forever #(CLK_PERIOD/2) clk = ~clk;
    end


    /**
     * Reset generation
     */

    initial begin
        rst_n = 1'b1;
        #(RST_START_TIME) rst_n = 1'b0;
        #(RST_ACTIVE_TIME) rst_n = 1'b1;
    end


    /**
     * Dut placement
     */

    vga_timing dut(
        .clk(clk),
        .rst_n(rst_n),
        .vcount(vcount),
        .vsync(vsync),
        .vblnk(vblnk),
        .hcount(hcount),
        .hsync(hsync),
        .hblnk(hblnk)
    );

    /**
     * Tasks and functions
     */

    // Here you can declare tasks with immediate assertions (assert).


    /**
     * Assertions
     */

    property p_hcount;
        @(posedge clk) disable iff (!rst_n) hcount < HOR_TOTAL_TIME;
    endproperty
    assert_h_limit: assert property (p_hcount) else $error("hcount assertion failed: hcount over HOR_TOTAL_TIME");

    
    property p_vcount;
        @(posedge clk) disable iff (!rst_n) vcount < VER_TOTAL_TIME;
    endproperty
    assert_v_limit: assert property (p_vcount) else $error("vcount assertion failde: vcount over VER_TOTAL_TIME");

    
    property p_hblnk;
        @(posedge clk) disable iff (!rst_n) (hcount >= HOR_PIXELS) |-> hblnk;
    endproperty
    assert_hblnk: assert property (p_hblnk) else $error("hblnk assertion error: wrong hblnk area");

    
    property p_vblnk;
        @(posedge clk) disable iff (!rst_n) (vcount >= VER_PIXELS) |-> vblnk;
    endproperty
    assert_vblnk: assert property (p_vblnk) else $error("vblnk assertion error: wrong vblnk area");

    
    property p_hsync;
        @(posedge clk) disable iff (!rst_n) 
        (hcount >= HOR_SYNC_START && hcount < (HOR_SYNC_START + HOR_SYNC_TIME)) |-> hsync;
    endproperty
    assert_hsync: assert property (p_hsync) else $error("hsync assertion error: wrong hsync time");

    
    property p_vsync;
        @(posedge clk) disable iff (!rst_n) 
        (vcount >= VER_SYNC_START && vcount < (VER_SYNC_START + VER_SYNC_TIME)) |-> vsync;
    endproperty
    assert_vsync: assert property (p_vsync) else $error("vsync assertion error: wrong vsync time");
    /**
     * Main test
     */

    initial begin
        @(negedge rst_n);
        @(posedge rst_n);

        wait (vsync == 1'b0);
        @(negedge vsync);
        @(negedge vsync);

        $finish;
    end

endmodule
