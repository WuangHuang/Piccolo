module Piccolo_RP(iData, oData);
 input  wire [63:0] iData;
 output wire [63:0] oData;
 
 wire X7 =  iData[7:0];
 wire X6 =  iData[15:8];
 wire X5 =  iData[23:16];
 wire X4 =  iData[31:24];
 wire X3 =  iData[39:32];
 wire X2 =  iData[47:40];
 wire X1 =  iData[55:48];
 wire X0 =  iData[63:56];

 assign oData = {X2, X7, X4, X1, X6, X3, X0, X5};
endmodule 