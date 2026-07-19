// =========================================================================
// 1. MODULE S-BOX & F-FUNCTION (Giữ nguyên)
// =========================================================================
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

module Piccolo_F_Function(idata, odata);
    input  wire [15:0] idata;
    output wire [15:0] odata;

    wire [3:0] X3 = idata[3:0];
    wire [3:0] X2 = idata[7:4];
    wire [3:0] X1 = idata[11:8];
    wire [3:0] X0 = idata[15:12];
    
    wire [3:0] X0_s1, X1_s1, X2_s1, X3_s1;
    Piccolo_Sbox Sbox0_1 (.data_in(X0), .Sbox_out(X0_s1));
    Piccolo_Sbox Sbox1_1 (.data_in(X1), .Sbox_out(X1_s1));
    Piccolo_Sbox Sbox2_1 (.data_in(X2), .Sbox_out(X2_s1));
    Piccolo_Sbox Sbox3_1 (.data_in(X3), .Sbox_out(X3_s1));
    
    function [3:0] gm2(input [3:0] op); 
        gm2 = {op[2:1], op[0] ^ op[3], op[3]}; 
    endfunction 
    function [3:0] gm3(input [3:0] op); 
        gm3 = {op[2] ^ op[3], op[1] ^ op[2], op[0] ^ op[3] ^ op[1], op[3] ^ op[0]}; 
    endfunction 

    wire [3:0] X0_diff = gm2(X0_s1) ^ gm3(X1_s1) ^     X2_s1  ^     X3_s1;
    wire [3:0] X1_diff =     X0_s1  ^ gm2(X1_s1) ^ gm3(X2_s1) ^     X3_s1;
    wire [3:0] X2_diff =     X0_s1  ^     X1_s1  ^ gm2(X2_s1) ^ gm3(X3_s1);
    wire [3:0] X3_diff = gm3(X0_s1) ^     X1_s1  ^     X2_s1  ^ gm2(X3_s1);

    Piccolo_Sbox Sbox0_2 (.data_in(X0_diff), .Sbox_out(odata[15:12]));
    Piccolo_Sbox Sbox1_2 (.data_in(X1_diff), .Sbox_out(odata[11:8]));
    Piccolo_Sbox Sbox2_2 (.data_in(X2_diff), .Sbox_out(odata[7:4]));
    Piccolo_Sbox Sbox3_2 (.data_in(X3_diff), .Sbox_out(odata[3:0]));
endmodule

// =========================================================================
// 2. MODULE KEY SCHEDULE (Mã gốc của bạn - Đã sửa lỗi iround [5:0])
// =========================================================================
module Piccolo_KeySchedule(KS, iround, imode, wk0, wk1, wk2, wk3, wr);
    input  wire [127:0] KS;
    input  wire [5:0]   iround; // Đã sửa từ [3:0] thành [5:0] để đếm tới 61
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

// =========================================================================
// 3. TOP MODULE: PICCOLO-128 CORE
// =========================================================================
module Piccolo_128_Core(
    input  wire         clk,
    input  wire         rst,
    input  wire         start,
    input  wire         imode, // 1: Encrypt, 0: Decrypt
    input  wire [127:0] key_in,
    input  wire [63:0]  data_in,
    output reg  [63:0]  data_out,
    output reg          valid
);
    localparam IDLE = 2'd0, RUN = 2'd1, DONE = 2'd2;
    reg [1:0] state;
    reg [4:0] round_cnt;
    reg [63:0] current_data;

    // Tính toán vòng thực tế cho Encrypt/Decrypt
    wire [4:0] mapped_round = imode ? round_cnt : (5'd30 - round_cnt);

    // Kỹ thuật xoay khóa tổ hợp (Thay vì dùng thanh ghi dịch)
    // Giúp module KS của bạn nhận đúng chuỗi KS đã được hoán vị sau mỗi 4 vòng.
    wire [1:0] perm_sel = mapped_round[3:2]; 
    reg [127:0] permuted_KS;
    always @(*) begin
        case (perm_sel)
            2'd0: permuted_KS = key_in;
            // Xoay 1 lần (chu kỳ 4)
            2'd1: permuted_KS = {key_in[95:80], key_in[111:96], key_in[31:16], key_in[15:0], key_in[127:112], key_in[79:64], key_in[63:48], key_in[47:32]};
            // Xoay 2 lần (chu kỳ 4)
            2'd2: permuted_KS = {key_in[31:16], key_in[111:96], key_in[63:48], key_in[47:32], key_in[95:80], key_in[79:64], key_in[127:112], key_in[15:0]};
            // Xoay 3 lần (chu kỳ 4)
            2'd3: permuted_KS = {key_in[63:48], key_in[111:96], key_in[127:112], key_in[15:0], key_in[31:16], key_in[79:64], key_in[95:80], key_in[47:32]};
        endcase
    end

    // Xử lý đảo vị trí khóa chẵn/lẻ khi giải mã tại các vòng có mapped_round là số lẻ
    wire [5:0] iround_even = (!imode && (mapped_round % 2 != 0)) ? {mapped_round, 1'b1} : {mapped_round, 1'b0};
    wire [5:0] iround_odd  = (!imode && (mapped_round % 2 != 0)) ? {mapped_round, 1'b0} : {mapped_round, 1'b1};

    // Khởi tạo 2 module KS của bạn để trích xuất đồng thời rk_even và rk_odd
    wire [15:0] wk0, wk1, wk2, wk3, rk_even, rk_odd;
    wire [15:0] dummy_wk0, dummy_wk1, dummy_wk2, dummy_wk3;

    Piccolo_KeySchedule KS_even_inst(
        .KS(permuted_KS), .iround(iround_even), .imode(imode),
        .wk0(wk0), .wk1(wk1), .wk2(wk2), .wk3(wk3), .wr(rk_even)
    );

    Piccolo_KeySchedule KS_odd_inst(
        .KS(permuted_KS), .iround(iround_odd), .imode(imode),
        .wk0(dummy_wk0), .wk1(dummy_wk1), .wk2(dummy_wk2), .wk3(dummy_wk3), .wr(rk_odd)
    );

    // Tách Datapath
    wire [15:0] X0 = current_data[63:48];
    wire [15:0] X1 = current_data[47:32];
    wire [15:0] X2 = current_data[31:16];
    wire [15:0] X3 = current_data[15:0];

    wire [15:0] f_out_0, f_out_2;
    Piccolo_F_Function F0 (.idata(X0), .odata(f_out_0));
    Piccolo_F_Function F2 (.idata(X2), .odata(f_out_2));

    wire [15:0] next_X1 = X1 ^ f_out_0 ^ rk_even;
    wire [15:0] next_X3 = X3 ^ f_out_2 ^ rk_odd;

    wire [15:0] rp_X0 = {X0[7:0], next_X1[15:8]};
    wire [15:0] rp_X1 = {next_X1[7:0], X2[15:8]};
    wire [15:0] rp_X2 = {X2[7:0], next_X3[15:8]};
    wire [15:0] rp_X3 = {next_X3[7:0], X0[15:8]};

    // FSM Điều Khiển
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            state <= IDLE;
            round_cnt <= 0;
            valid <= 0;
            data_out <= 0;
        end else begin
            case(state)
                IDLE: begin
                    valid <= 0;
                    if (start) begin
                        state <= RUN;
                        round_cnt <= 0;
                        current_data <= { data_in[63:48] ^ wk0, data_in[47:32], data_in[31:16] ^ wk1, data_in[15:0] };
                    end
                end
                
                RUN: begin
                    if (round_cnt < 30) begin
                        current_data <= {rp_X0, rp_X1, rp_X2, rp_X3};
                        round_cnt <= round_cnt + 1;
                    end else begin
                        current_data <= {X0 ^ wk2, next_X1, X2 ^ wk3, next_X3};
                        state <= DONE;
                    end
                end
                
                DONE: begin
                    valid <= 1;
                    data_out <= current_data;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule

// =========================================================================
// 4. TESTBENCH: Kiểm Chứng Encrypt & Decrypt
// =========================================================================
module tb_piccolo128;
    reg clk;
    reg rst;
    reg start;
    reg imode;
    reg  [127:0] key_in;
    reg  [63:0]  data_in;
    wire [63:0]  data_out;
    wire valid;

    Piccolo_128_Core uut (
        .clk(clk), .rst(rst), .start(start), .imode(imode),
        .key_in(key_in), .data_in(data_in),
        .data_out(data_out), .valid(valid)
    );

    always #5 clk = ~clk;

    initial begin
        clk = 0; rst = 1; start = 0;
        key_in  = 128'h00112233_44556677_8899aabb_ccddeeff;
        data_in = 64'h01234567_89abcdef;
        
        #15 rst = 0;
        
        // --- PHA MÃ HÓA (imode = 1) ---
        $display("--- BAT DAU MA HOA ---");
        imode = 1'b1;
        start = 1;
        #10 start = 0;
        
        wait(valid);
        $display("Plaintext  Input : %h", data_in);
        $display("Ciphertext Output: %h", data_out);
        $display("Expected Output  : 5ec42cea657b89ff");
        
        // --- PHA GIẢI MÃ (imode = 0) ---
        $display("\n--- BAT DAU GIAI MA ---");
        data_in = data_out; // Lấy bản mã làm đầu vào
        imode = 1'b0;
        start = 1;
        #10 start = 0;
        
        wait(valid);
        $display("Ciphertext Input : %h", data_in);
        $display("Plaintext  Output: %h", data_out);
        $display("Expected Output  : 0123456789abcdef");
        
        #20 $finish;
    end
endmodule