module Piccolo_KeySchedule(
    input  wire [127:0] KS,
    input  wire [4:0]   iround,
    input  wire         imode,
    output wire [15:0]  wk0, wk1, wk2, wk3,
    output wire [15:0]  rk_even, rk_odd
);
    wire [15:0] K7 = KS[15:0];   wire [15:0] K6 = KS[31:16];
    wire [15:0] K5 = KS[47:32];  wire [15:0] K4 = KS[63:48];
    wire [15:0] K3 = KS[79:64];  wire [15:0] K2 = KS[95:80];
    wire [15:0] K1 = KS[111:96]; wire [15:0] K0 = KS[127:112];
 
    assign wk0 = imode ? {K0[15:8], K1[7:0]} : {K4[15:8], K7[7:0]};
    assign wk1 = imode ? {K1[15:8], K0[7:0]} : {K7[15:8], K4[7:0]};
    assign wk2 = imode ? {K4[15:8], K7[7:0]} : {K0[15:8], K1[7:0]};
    assign wk3 = imode ? {K7[15:8], K4[7:0]} : {K1[15:8], K0[7:0]};

    wire [2:0] state_idx = (iround + 5'd1) >> 2; 
    reg [127:0] pKS;
    always @(*) begin
        case (state_idx)
            3'd0: pKS = {K0, K1, K2, K3, K4, K5, K6, K7};
            3'd1: pKS = {K2, K1, K6, K7, K0, K3, K4, K5};
            3'd2: pKS = {K6, K1, K4, K5, K2, K7, K0, K3};
            3'd3: pKS = {K4, K1, K0, K3, K6, K5, K2, K7};
            3'd4: pKS = {K0, K1, K2, K7, K4, K3, K6, K5};
            3'd5: pKS = {K2, K1, K6, K5, K0, K7, K4, K3};
            3'd6: pKS = {K6, K1, K4, K3, K2, K5, K0, K7};
            3'd7: pKS = {K4, K1, K0, K7, K6, K3, K2, K5};
         default: pKS = {K0, K1, K2, K3, K4, K5, K6, K7};
        endcase
    end
    
    wire [15:0] pK7 = pKS[15:0];   wire [15:0] pK6 = pKS[31:16];
    wire [15:0] pK5 = pKS[47:32];  wire [15:0] pK4 = pKS[63:48];
    wire [15:0] pK3 = pKS[79:64];  wire [15:0] pK2 = pKS[95:80];
    wire [15:0] pK1 = pKS[111:96]; wire [15:0] pK0 = pKS[127:112];

    reg [15:0] Sel_K_even, Sel_K_odd;
    always @(*) begin
        case (iround[1:0])
            2'd0: begin Sel_K_even = pK2; Sel_K_odd = pK3; end
            2'd1: begin Sel_K_even = pK4; Sel_K_odd = pK5; end
            2'd2: begin Sel_K_even = pK6; Sel_K_odd = pK7; end
            2'd3: begin Sel_K_even = pK0; Sel_K_odd = pK1; end
        endcase
    end

    wire [4:0] c = iround + 1'b1; 
    wire [15:0] base_even = { c, 5'b00000, c, 1'b0 };
    
    wire [15:0] con_even = base_even ^ 16'h6547;
    wire [15:0] con_odd  = (base_even >> 1) ^ 16'ha98b;
    
    assign rk_even = (!imode && iround[0]) ? Sel_K_odd  ^ con_odd : Sel_K_even ^ con_even;
    assign rk_odd  = (!imode && iround[0]) ? Sel_K_even ^ con_even : Sel_K_odd  ^ con_odd;
endmodule