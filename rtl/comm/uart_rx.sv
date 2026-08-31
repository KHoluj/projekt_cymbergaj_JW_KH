/**
 * Autor: JW
 *
 * Opis:
 * UART receiver, 8 bitow danych 1 stop bit.
 */

module uart_rx #(
    parameter int CLK_FREQ = 65_000_000,
    parameter int BAUD     = 500_000
)(
    input  logic clk,
    input  logic rst,

    input  logic rx,             

    output logic [7:0] data,
    output logic data_valid      
);

    timeunit 1ns;
    timeprecision 1ps;

    localparam int DIVISOR      = CLK_FREQ / BAUD;
    localparam int HALF_DIVISOR = DIVISOR / 2;
    localparam int DIV_BITS     = $clog2(DIVISOR);

    (* ASYNC_REG = "TRUE" *) logic rx_sync1, rx_sync2;
    logic rx_sync2_d;

    always_ff @(posedge clk) begin
        if (rst) begin
            rx_sync1   <= 1'b1;
            rx_sync2   <= 1'b1;
            rx_sync2_d <= 1'b1;
        end else begin
            rx_sync1   <= rx;
            rx_sync2   <= rx_sync1;
            rx_sync2_d <= rx_sync2;
        end
    end

    logic start_edge;
    assign start_edge = rx_sync2_d & ~rx_sync2;   

    typedef enum logic [1:0] {IDLE, START, DATA, STOP} state_t;
    state_t state;

    logic [DIV_BITS-1:0] baud_cnt;
    logic [2:0] bit_idx;
    logic [7:0] shift_reg;

    always_ff @(posedge clk) begin
        if (rst) begin
            state      <= IDLE;
            data_valid <= 1'b0;
            baud_cnt   <= '0;
            bit_idx    <= 3'd0;
        end else begin
            data_valid <= 1'b0;

            case (state)
                IDLE: begin
                    if (start_edge) begin
                        baud_cnt <= '0;
                        state    <= START;
                    end
                end

                START: begin
                    
                    if (baud_cnt == HALF_DIVISOR[DIV_BITS-1:0]) begin
                        baud_cnt <= '0;
                        bit_idx  <= 3'd0;
                        if (rx_sync2 == 1'b0)
                            state <= DATA;
                        else
                            state <= IDLE;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                DATA: begin
                    if (baud_cnt == DIVISOR[DIV_BITS-1:0] - 1'b1) begin
                        baud_cnt            <= '0;
                        shift_reg[bit_idx]  <= rx_sync2;
                        if (bit_idx == 3'd7)
                            state <= STOP;
                        else
                            bit_idx <= bit_idx + 1'b1;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                STOP: begin
                    if (baud_cnt == DIVISOR[DIV_BITS-1:0] - 1'b1) begin
                        data       <= shift_reg;
                        data_valid <= 1'b1;
                        state      <= IDLE;
                    end else begin
                        baud_cnt <= baud_cnt + 1'b1;
                    end
                end

                default: state <= IDLE;
            endcase
        end
    end

endmodule
