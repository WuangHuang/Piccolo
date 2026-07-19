module Piccolo_KeySchedule(KS, iround, imode, wk0, wk1, wk2, wk3, wr);
    input  wire [127:0] KS;
    input  wire [5:0]   iround; 
    input  wire         imode;
    output wire [15:0] wk0, wk1, wk2, wk3, wr;
 
    wire [15:0] K7 = KS[15:0];   wire [15:0] K6 = KS[31:16];
    wire [15:0] K5 = KS[47:32];  wire [15:0] K4 = KS[63:48];
    wire [15:0] K3 = KS[79:64];  wire [15:0] K2 = KS[95:80];
    wire [15:0] K1 = KS[111:96]; wire [15:0] K0 = KS[127:112];
 
    assign wk0 = imode ? {K0[15:8], K1[7:0]} : {K4[15:8], K7[7:0]};
    assign wk1 = imode ? {K1[15:8], K0[7:0]} : {K7[15:8], K4[7:0]};
    assign wk2 = imode ? {K4[15:8], K7[7:0]} : {K0[15:8], K1[7:0]};
    assign wk3 = imode ? {K7[15:8], K4[7:0]} : {K1[15:8], K0[7:0]};
 
    wire [2:0] Mux_KeyRound = {iround[2] ^ iround[1], ~iround[1], iround[0]};   
    reg  [15:0] Sel_K;
    always @(*) begin 
        case (Mux_KeyRound) 
            3'h0: Sel_K = K0; 3'h1: Sel_K = K1; 3'h2: Sel_K = K2; 3'h3: Sel_K = K3; 
            3'h4: Sel_K = K4; 3'h5: Sel_K = K5; 3'h6: Sel_K = K6; 3'h7: Sel_K = K7;
            default: Sel_K = K0; 
        endcase 
    end
   
    wire [4:0] r_idx = iround[5:1]; 
    wire [4:0] c     = r_idx + 1'b1;
    
    wire [31:0] con_base = { c, 5'b00000, c, 2'b00, c, 5'b00000, c };
    wire [31:0] con_pair = con_base ^ 32'h6547a98b;
    wire [15:0] con_val  = iround[0] ? con_pair[15:0] : con_pair[31:16];
    assign wr = Sel_K ^ con_val;
endmodule 