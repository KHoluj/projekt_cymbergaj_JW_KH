/**
 * 
 * Autor: KH
 *
 * Opis:
 * Reset kontrolera
 */

module rst_ctl (
        input  logic clk,
        input  logic btn_rst,   
        output logic rst        
    );

    timeunit 1ns;
    timeprecision 1ps;

    (* KEEP = "TRUE" *)
    (* ASYNC_REG = "TRUE" *)
    logic [1:0] sync_ff;
    
    always_ff @(posedge clk or posedge btn_rst) begin
        if (btn_rst)
            sync_ff <= 2'b11;
        else
            sync_ff <= {sync_ff[0], 1'b0};
    end

    assign rst = sync_ff[1];

endmodule
