/**
 * Autor: KH
 *
 * Opis:
 * Otrzymuje bajty z uart_rx i laczy je w pakiety
 */

module link_rx_ctl
    import game_pkg::*;
#(
    parameter int CLK_FREQ = 65_000_000,
    parameter int BAUD     = 500_000
)(
    input  logic clk,
    input  logic rst,
    input  logic is_host,

    input  logic rx,

    
    output game_state_t rx_game_state,
    output logic rx_winner_p2,
    output logic rx_puck_served,
    output logic rx_server_is_p2,
    output logic [11:0] rx_puck_x, rx_puck_y,
    output logic [11:0] rx_p1_x, rx_p1_y,
    output logic [3:0]  rx_score_p1_tens, rx_score_p1_ones,
    output logic [3:0]  rx_score_p2_tens, rx_score_p2_ones,

    
    output logic [11:0] rx_p2_x, rx_p2_y,

    output logic link_ok   
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam logic [7:0] SYNC_STATE  = 8'h55;
    localparam logic [7:0] SYNC_PADDLE = 8'hAA;
    localparam int STATE_PAYLOAD_LEN  = 9;
    localparam int PADDLE_PAYLOAD_LEN = 3;

    logic [7:0] rx_byte;
    logic rx_byte_valid;

    uart_rx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(BAUD)
    ) u_uart_rx (
        .clk(clk), .rst(rst),
        .rx(rx), .data(rx_byte), .data_valid(rx_byte_valid)
    );

    logic [7:0] expected_sync;
    logic [3:0] payload_len;
    assign expected_sync = is_host ? SYNC_PADDLE : SYNC_STATE;
    assign payload_len   = is_host ? PADDLE_PAYLOAD_LEN[3:0] : STATE_PAYLOAD_LEN[3:0];

    logic [7:0] buf_bytes [0:8];
    logic [3:0] payload_idx;
    logic [7:0] running_chk;

    typedef enum logic [0:0] {WAIT_SYNC, COLLECT} rx_pkt_state_t;
    rx_pkt_state_t rx_pkt_state;

    always_ff @(posedge clk) begin
        if (rst) begin
            rx_pkt_state <= WAIT_SYNC;
            payload_idx  <= 4'd0;
            running_chk  <= 8'd0;
            link_ok      <= 1'b0;

            rx_p2_x <= 12'd0; rx_p2_y <= 12'd0;
            rx_game_state <= ST_MENU;
            rx_winner_p2  <= 1'b0;
            rx_puck_served  <= 1'b0;
            rx_server_is_p2 <= 1'b0;
            rx_puck_x <= 12'd0; rx_puck_y <= 12'd0;
            rx_p1_x   <= 12'd0; rx_p1_y   <= 12'd0;
            rx_score_p1_tens <= 4'd0; rx_score_p1_ones <= 4'd0;
            rx_score_p2_tens <= 4'd0; rx_score_p2_ones <= 4'd0;
        end else begin
            link_ok <= 1'b0;

            if (rx_byte_valid) begin
                case (rx_pkt_state)
                    WAIT_SYNC: begin
                        if (rx_byte == expected_sync) begin
                            payload_idx  <= 4'd0;
                            running_chk  <= 8'd0;
                            rx_pkt_state <= COLLECT;
                        end
                        
                    end

                    COLLECT: begin
                        if (payload_idx < payload_len) begin
                            buf_bytes[payload_idx] <= rx_byte;
                            running_chk             <= running_chk ^ rx_byte;
                            payload_idx             <= payload_idx + 4'd1;
                        end else begin
                            
                            if (rx_byte == running_chk) begin
                                link_ok <= 1'b1;
                                if (is_host) begin
                                    rx_p2_x <= {buf_bytes[0], buf_bytes[1][7:4]};
                                    rx_p2_y <= {buf_bytes[1][3:0], buf_bytes[2]};
                                end else begin
                                    rx_game_state    <= game_state_t'(buf_bytes[0][2:1]);
                                    rx_winner_p2     <= buf_bytes[0][0];
                                    rx_server_is_p2  <= buf_bytes[0][3];
                                    rx_puck_served   <= buf_bytes[0][4];
                                    rx_puck_x        <= {buf_bytes[1], buf_bytes[2][7:4]};
                                    rx_puck_y        <= {buf_bytes[2][3:0], buf_bytes[3]};
                                    rx_p1_x          <= {buf_bytes[4], buf_bytes[5][7:4]};
                                    rx_p1_y          <= {buf_bytes[5][3:0], buf_bytes[6]};
                                    rx_score_p1_tens <= buf_bytes[7][7:4];
                                    rx_score_p1_ones <= buf_bytes[7][3:0];
                                    rx_score_p2_tens <= buf_bytes[8][7:4];
                                    rx_score_p2_ones <= buf_bytes[8][3:0];
                                end
                            end
                            rx_pkt_state <= WAIT_SYNC;
                        end
                    end

                    default: rx_pkt_state <= WAIT_SYNC;
                endcase
            end
        end
    end

endmodule
