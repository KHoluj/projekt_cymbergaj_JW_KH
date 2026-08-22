module draw_rect_ctl (
    input  logic clk,
    input  logic rst_n,

    input  logic [11:0] mouse_x,
    input  logic [11:0] mouse_y,
    input  logic mouse_left,

    output logic [11:0] rect_x,
    output logic [11:0] rect_y
);

    // -------------------------
    // Screen param
    // -------------------------
    localparam int SCREEN_H = 600;
    localparam int RECT_H   = 64;

    // -------------------------
    // States
    // -------------------------
    typedef enum logic [1:0] {
        FOLLOW,
        FALL,
        STOP
    } state_t;

    state_t state;

    // -------------------------
    // Mouse click detection
    // -------------------------
    logic mouse_left_d;
    logic mouse_left_click;

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            mouse_left_d <= 0;
        else
            mouse_left_d <= mouse_left;
    end

    assign mouse_left_click = mouse_left & ~mouse_left_d;

    // -------------------------
    // Generating ticks 
    // -------------------------
    logic [19:0] tick_cnt;
    logic tick;

    localparam int DIV = 16_597; 

    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            tick_cnt <= 0;
            tick <= 0;
        end else begin
            if (tick_cnt == DIV) begin
                tick_cnt <= 0;
                tick <= 1;
            end else begin
                tick_cnt <= tick_cnt + 1;
                tick <= 0;
            end
        end
    end

    // -------------------------
    // FIXED POINT
    // -------------------------
    logic signed [19:0] y_fp;
    logic signed [19:0] v_fp;

    logic signed [19:0] v_before;
    logic signed [19:0] v_next;
    logic signed [19:0] y_next;

    logic [11:0] rect_x_reg;

    
    localparam signed [19:0] GRAVITY = 20'sd1;
    localparam signed [19:0] RESTIT  = 20'sd235; 
    localparam signed [19:0] V_MIN   = 20'sd3;

    


    always_ff @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= FOLLOW;
            y_fp <= 0;
            v_fp <= 0;
            rect_x_reg <= 0;
        end else begin

            case (state)

               
                FOLLOW: begin
                    rect_x_reg <= mouse_x;
                    y_fp <= mouse_y << 8;
                    v_fp <= 0;

                    if (mouse_left_click)
                        state <= FALL;
                end

                
                FALL: begin

                    if (tick) begin

                        v_before = v_fp;

                        v_next = v_fp + GRAVITY;
                        y_next = y_fp + v_next;

                        if ((y_next >> 8) >= (SCREEN_H - RECT_H)) begin
                            y_next = (SCREEN_H - RECT_H) << 8;

                            v_next = -(v_before * RESTIT) >>> 8;

                            if ((v_next < V_MIN) && (v_next > -V_MIN)) begin
                                v_next = 0;
                                state <= STOP;
                            end
                        end

                        v_fp <= v_next;
                        y_fp <= y_next;
                    end
                end

                
                STOP: begin
                    v_fp <= 0;

                    if (mouse_left_click)
                        state <= FOLLOW;
                end

            endcase
        end
    end

   
    assign rect_x = rect_x_reg;
    assign rect_y = y_fp[19:8];

endmodule