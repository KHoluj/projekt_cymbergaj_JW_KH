module draw_rect_ctl_prog(
    output logic clk,
    output logic rst_n,
    output logic mouse_left,
    output logic [11:0] mouse_xpos,
    output logic [11:0] mouse_ypos
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam CLK_PERIOD = 25; // 40 MHz

    initial clk = 0;
    always #(CLK_PERIOD/2) clk = ~clk;

   

    initial begin
        
        rst_n = 0;

        mouse_left = 0;
        mouse_xpos = 12'd400;
        mouse_ypos = 12'd10;

        
        #100;
        rst_n = 1;

        
        #5000;
        mouse_xpos = 12'd400;
        mouse_ypos = 12'd10;
        mouse_left = 0;

      
        #5000;
        mouse_left = 1;

        #50;
        mouse_left = 0;

        
        #300_000_000;

        
        mouse_left = 1;

        #50;
        mouse_left = 0;

        #50_000_000;

        $finish;
    end

endmodule