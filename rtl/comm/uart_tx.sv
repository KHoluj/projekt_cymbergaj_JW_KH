/**
 * Autor: JW
 *
 * Opis:
 * UART transmitter, 8 bitow danych 1 bit stop.
 */

module uart_tx #(
    parameter int CLK_FREQ = 65_000_000,
    parameter int BAUD     = 500_000
)(
    input  logic clk,
    input  logic rst,

    input  logic [7:0] data,
    input  logic send,     
    output logic busy,     

    output logic tx
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int DIVISOR  = CLK_FREQ / BAUD;
    localparam int DIV_BITS = $clog2(DIVISOR);

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    logic [DIV_BITS-1:0] baud_cnt;
    logic [2:0] bit_idx;
    logic [7:0] shift_reg;

    assign busy = (state != IDLE);

    always_ff @(posedge clk) begin
        if (rst) begin
            state    <= IDLE;
            tx       <= 1'b1;
            baud_cnt <= '0;
            bit_idx  <= 3'd0;
        end else begin
            case (state)
                IDLE: begin
                    tx <= 1'b1;
                    if (send) begin
                        shift_reg <= data;
                        baud_cnt  <= '0;
                        state     <= START;
                    end
                end

                START: begin
                    tx <= 1'b0;
                    if (baud_cnt == DIVISOR[DIV_BITS-1:0] - 1'b1) begin
                        baud_cnt <= '0;
                        bit_idx  <= 3'd0;
                        state    <= DATA;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                DATA: begin
                    tx <= shift_reg[bit_idx];
                    if (baud_cnt == DIVISOR[DIV_BITS-1:0] - 1'b1) begin
                        baud_cnt <= '0;
                        if (bit_idx == 3'd7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1'b1;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                STOP: begin
                    tx <= 1'b1;
                    if (baud_cnt == DIVISOR[DIV_BITS-1:0] - 1'b1) begin
                        baud_cnt <= '0;
                        state    <= IDLE;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
