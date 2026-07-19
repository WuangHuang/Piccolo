module Piccolo_F_Function(idata, odata);
    input  wire [15:0] idata;
    output wire [15:0] odata;

    //SLICE 
    wire [3:0] X3 = idata[3:0];
    wire [3:0] X2 = idata[7:4];
    wire [3:0] X1 = idata[11:8];
    wire [3:0] X0 = idata[15:12];
    
    //Sbox stage 1
    wire [3:0] X0_sbox_Stage1; wire [3:0] X1_sbox_Stage1;
    wire [3:0] X2_sbox_Stage1; wire [3:0] X3_sbox_Stage1;
    Piccolo_Sbox Sbox0_Stage1 (.data_in(X0), .Sbox_out(X0_sbox_Stage1));
    Piccolo_Sbox Sbox1_Stage1 (.data_in(X1), .Sbox_out(X1_sbox_Stage1));
    Piccolo_Sbox Sbox2_Stage1 (.data_in(X2), .Sbox_out(X2_sbox_Stage1));
    Piccolo_Sbox Sbox3_Stage1 (.data_in(X3), .Sbox_out(X3_sbox_Stage1));
    
    //diffusion function
    //GM2
    function [3 : 0] gm2(input [3 : 0] op); 
     begin
        gm2 = {op[2:1], op[0] ^ op[3], op[3]}; 
     end
    endfunction 
    //GM3
    function [3 : 0] gm3(input [3 : 0] op); 
     begin
        gm3 = {op[2] ^ op[3], op[1] ^ op[2], op[0] ^ op[3] ^ op[1], op[3] ^ op[0]}; //gm2(op) ^ op
     end
    endfunction 

    wire [3:0] X0_diff = gm2(X0_sbox_Stage1) ^ gm3(X1_sbox_Stage1) ^     X2_sbox_Stage1  ^     X3_sbox_Stage1; // y0 = 2*x0 ^ 3*x1 ^ 1*x2 ^ 1*x3
    wire [3:0] X1_diff =     X0_sbox_Stage1  ^ gm2(X1_sbox_Stage1) ^ gm3(X2_sbox_Stage1) ^     X3_sbox_Stage1; // y1 = 1*x0 ^ 2*x1 ^ 3*x2 ^ 1*x3
    wire [3:0] X2_diff =     X0_sbox_Stage1  ^     X1_sbox_Stage1  ^ gm2(X2_sbox_Stage1) ^ gm3(X3_sbox_Stage1); // y2 = 1*x0 ^ 1*x1 ^ 2*x2 ^ 3*x3
    wire [3:0] X3_diff = gm3(X0_sbox_Stage1) ^     X1_sbox_Stage1  ^     X2_sbox_Stage1  ^ gm2(X3_sbox_Stage1); // y3 = 3*x0 ^ 1*x1 ^ 1*x2 ^ 2*x3

    //Sbox stage 2
    wire [3:0] X0_sbox_Stage2; wire [3:0] X1_sbox_Stage2;
    wire [3:0] X2_sbox_Stage2; wire [3:0] X3_sbox_Stage2;
    Piccolo_Sbox Sbox0_Stage2 (.data_in(X0_diff), .Sbox_out(odata[15:12]));
    Piccolo_Sbox Sbox1_Stage2 (.data_in(X1_diff), .Sbox_out(odata[11:8]));
    Piccolo_Sbox Sbox2_Stage2 (.data_in(X2_diff), .Sbox_out(odata[7:4]));
    Piccolo_Sbox Sbox3_Stage2 (.data_in(X3_diff), .Sbox_out(odata[3:0]));

endmodule

