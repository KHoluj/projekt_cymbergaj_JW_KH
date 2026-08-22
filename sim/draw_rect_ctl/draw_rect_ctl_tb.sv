module draw_rect_ctl_tb;

    timeunit 1ns;
    timeprecision 1ps;

    
    logic clk, rst_n, mouse_left;
    logic [11:0] mouse_xpos, mouse_ypos;
    logic [11:0] rect_x, rect_y;

    
    draw_rect_ctl_prog prog(
        .clk(clk),
        .rst_n(rst_n),
        .mouse_left(mouse_left),
        .mouse_xpos(mouse_xpos),
        .mouse_ypos(mouse_ypos)
    );

   
    draw_rect_ctl dut(
        .clk(clk),
        .rst_n(rst_n),

        .mouse_x(mouse_xpos),
        .mouse_y(mouse_ypos),
        .mouse_left(mouse_left),

        .rect_x(rect_x),
        .rect_y(rect_y)
    );

   
    initial begin
        $monitor(
            "t=%0t | rst_n=%b | mouse_left=%b | mx=%d my=%d | x=%d y=%d",
            $time, rst_n, mouse_left, mouse_xpos, mouse_ypos, rect_x, rect_y
        );
    end

endmodule