module Piccolo_Sbox (
    input   wire [3:0] data_in,
    output  reg  [3:0] Sbox_out
);
    always @(*) begin
            case (data_in)
                4'h0: Sbox_out = 4'he; 4'h1: Sbox_out = 4'h4; 4'h2: Sbox_out = 4'hb; 4'h3: Sbox_out = 4'h2;
                4'h4: Sbox_out = 4'h3; 4'h5: Sbox_out = 4'h8; 4'h6: Sbox_out = 4'h0; 4'h7: Sbox_out = 4'h9;
                4'h8: Sbox_out = 4'h1; 4'h9: Sbox_out = 4'ha; 4'ha: Sbox_out = 4'h7; 4'hb: Sbox_out = 4'hf;
                4'hc: Sbox_out = 4'h6; 4'hd: Sbox_out = 4'hc; 4'he: Sbox_out = 4'h5; 4'hf: Sbox_out = 4'hd;
                default: Sbox_out = 4'he;
            endcase
    end
endmodule