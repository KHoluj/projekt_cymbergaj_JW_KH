module char_rom #(
    parameter string TEXT = {
        "  Laboratorium UEC - Krok 2     ",
        "                                ",
        "   Projekt: Prostokat 32x8      ",
        "AlaMaKotaAKotMaAle11223344556677",
        "12345678901234567890123456789012",
        "abcdefghijklmnopqrstuvwxyz123456",                                
        "        Wersja robocza...       ",
        "!@#$^&*1234567890ABCDEFGHIJKLMNO"
    }
)(
    input  logic clk,
    input  logic [7:0] char_xy,  
    output logic [6:0] char_code
);

    logic [7:0] rom [0:255];

    initial begin
        for (int i = 0; i < 256; i++) begin
            rom[i] = TEXT[i];
        end
    end

    always_ff @(posedge clk) begin
        char_code <= rom[char_xy][6:0];
    end

endmodule