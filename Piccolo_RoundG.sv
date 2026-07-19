module Piccolo_RoundG (iData, whi_Key0,  whi_Key1, rou_Key0, rou_Key1, rlast, oRound);
 input wire [63:0] iData;

 input wire [15:0] whi_Key0;
 input wire [15:0] whi_Key1;

 input wire [15:0] rou_Key0; 
 input wire [15:0] rou_Key1;

 input  wire         rlast;
 output wire [63:0] oRound;

 wire [15:0] X0 = iData[63:48];
 wire [15:0] X1 = iData[47:32];
 wire [15:0] X2 = iData[31:16];
 wire [15:0] X3 = iData[15:0];
 
 wire [15:0] X0_diff = X0 ^ whi_Key0;
 wire [15:0] X2_diff = X2 ^ whi_Key1;
 
wire [15:0] X0_F, X2_F;
Piccolo_F_Function F0 (.idata(X0), .odata(X0_F));
Piccolo_F_Function F1 (.idata(X2), .odata(X2_F));

wire [15:0] X1_diff = X1 ^ X0_F ^ rou_Key0;
wire [15:0] X3_diff = X3 ^ X2_F ^ rou_Key1;

wire [63:0] oData_Reg;
Piccolo_RP RP_insta (.iData({X0_diff, X1_diff, X2_diff, X3_diff}), .oData(oData_Reg));

assign oRound = rlast ? {X0_diff, X1_diff, X2_diff, X3_diff} : oData_Reg;
endmodule 