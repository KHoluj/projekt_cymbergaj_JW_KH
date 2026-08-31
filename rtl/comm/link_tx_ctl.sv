/**
 * Autor: KH
 *
 * Opis:
 * Buduje i wysyla pakiet przez uart_tx.
 */

module link_tx_ctl
    import game_pkg::*;
#(
    parameter int CLK_FREQ = 65_000_000,
    parameter int BAUD     = 500_000
)(
    input  logic clk,
    input  logic rst,
    input  logic frame_tick,
    input  logic is_host,

    
    input  game_state_t game_state,
    input  logic winner_p2,
    input  logic puck_served,
    input  logic server_is_p2,
    input  logic [11:0] puck_x, puck_y,
    input  logic [11:0] p1_x, p1_y,
    input  logic [3:0]  score_p1_tens, score_p1_ones,
    input  logic [3:0]  score_p2_tens, score_p2_ones,

    
    input  logic [11:0] p2_x, p2_y,

    output logic tx
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam logic [7:0] SYNC_STATE  = 8'h55;
    localparam logic [7:0] SYNC_PADDLE = 8'hAA;
    localparam int STATE_LEN  = 11;
    localparam int PADDLE_LEN = 5;

    logic [7:0] state_chk, paddle_chk;
    logic [7:0] flags_byte;

    assign flags_byte = {3'b0, puck_served, server_is_p2, game_state, winner_p2};

    assign state_chk = flags_byte
                        ^ puck_x[11:4] ^ {puck_x[3:0], puck_y[11:8]} ^ puck_y[7:0]
                        ^ p1_x[11:4]   ^ {p1_x[3:0],   p1_y[11:8]}   ^ p1_y[7:0]
                        ^ {score_p1_tens, score_p1_ones}
                        ^ {score_p2_tens, score_p2_ones};

    assign paddle_chk = p2_x[11:4] ^ {p2_x[3:0], p2_y[11:8]} ^ p2_y[7:0];

    logic [7:0] tx_data;
    logic tx_send, tx_busy;

    uart_tx #(
        .CLK_FREQ(CLK_FREQ),
        .BAUD(BAUD)
    ) u_uart_tx (
        .clk(clk), .rst(rst),
        .data(tx_data), .send(tx_send), .busy(tx_busy),
        .tx(tx)
    );

    logic tx_busy_d;
    always_ff @(posedge clk) begin
        if (rst) tx_busy_d <= 1'b0;
        else     tx_busy_d <= tx_busy;
    end
    logic tx_done_pulse;
    assign tx_done_pulse = tx_busy_d & ~tx_busy;   

    logic [7:0] packet [0:10];
    logic [3:0] pkt_len;
    logic [3:0] byte_idx;

    typedef enum logic [1:0] {TX_IDLE, TX_LOAD, TX_SENDING} tx_state_t;
    tx_state_t tx_state;

    always_ff @(posedge clk) begin
        if (rst) begin
            tx_state <= TX_IDLE;
            tx_send  <= 1'b0;
            byte_idx <= 4'd0;
            pkt_len  <= 4'd0;
        end else begin
            tx_send <= 1'b0;

            case (tx_state)
                TX_IDLE: begin
                    if (frame_tick) begin
                        if (is_host) begin
                            packet[0]  <= SYNC_STATE;
                            packet[1]  <= flags_byte;
                            packet[2]  <= puck_x[11:4];
                            packet[3]  <= {puck_x[3:0], puck_y[11:8]};
                            packet[4]  <= puck_y[7:0];
                            packet[5]  <= p1_x[11:4];
                            packet[6]  <= {p1_x[3:0], p1_y[11:8]};
                            packet[7]  <= p1_y[7:0];
                            packet[8]  <= {score_p1_tens, score_p1_ones};
                            packet[9]  <= {score_p2_tens, score_p2_ones};
                            packet[10] <= state_chk;
                            pkt_len    <= STATE_LEN[3:0];
                        end else begin
                            packet[0] <= SYNC_PADDLE;
                            packet[1] <= p2_x[11:4];
                            packet[2] <= {p2_x[3:0], p2_y[11:8]};
                            packet[3] <= p2_y[7:0];
                            packet[4] <= paddle_chk;
                            pkt_len   <= PADDLE_LEN[3:0];
                        end
                        byte_idx <= 4'd0;
                        tx_state <= TX_LOAD;
                    end
                end

                TX_LOAD: begin
                    tx_data  <= packet[0];
                    tx_send  <= 1'b1;
                    tx_state <= TX_SENDING;
                end

                TX_SENDING: begin
                    if (tx_done_pulse) begin
                        if (byte_idx == pkt_len - 1'b1) begin
                            tx_state <= TX_IDLE;
                        end else begin
                            byte_idx <= byte_idx + 1'b1;
                            tx_data  <= packet[byte_idx + 1'b1];
                            tx_send  <= 1'b1;
                        end
                    end
                end

                default: tx_state <= TX_IDLE;
            endcase
        end
    end

endmodule
