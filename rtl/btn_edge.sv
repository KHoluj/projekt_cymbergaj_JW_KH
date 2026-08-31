/**
 * Autor: JW
 *
 * Opis:
 * Synchronizuje surowy sygnal przycisku z plytki i produkuje 
 * 1 cyklowy sygnal na narastajacej krawedzi
 */

module btn_edge (
    input  logic clk,
    input  logic rst,
    input  logic btn_raw,   
    output logic pulse      
);

    timeunit 1ns;
    timeprecision 1ps;

    logic [2:0] sync_ff;

    always_ff @(posedge clk) begin
        if (rst)
            sync_ff <= 3'b000;
        else
            sync_ff <= {sync_ff[1:0], btn_raw};
    end

    assign pulse = sync_ff[1] & ~sync_ff[2];

endmodule
