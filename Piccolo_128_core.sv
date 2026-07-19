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

    wire [4:0] mapped_round = imode ? round_cnt : (5'd30 - round_cnt);

    wire [2:0] perm_sel = ((mapped_round + 1'b1) >> 2); 
    
    reg [127:0] permuted_KS;
    always @(*) begin
        case (perm_sel)
            3'd0: permuted_KS = key_in;
            3'd1: permuted_KS = {key_in[95:80], key_in[111:96], key_in[31:16], key_in[15:0], key_in[127:112], key_in[79:64], key_in[63:48], key_in[47:32]};
            3'd2: permuted_KS = {key_in[31:16], key_in[111:96], key_in[63:48], key_in[47:32], key_in[95:80], key_in[15:0], key_in[127:112], key_in[79:64]};
            3'd3: permuted_KS = {key_in[63:48], key_in[111:96], key_in[127:112], key_in[79:64], key_in[31:16], key_in[47:32], key_in[95:80], key_in[15:0]};
            3'd4: permuted_KS = {key_in[127:112], key_in[111:96], key_in[95:80], key_in[15:0], key_in[63:48], key_in[79:64], key_in[31:16], key_in[47:32]};
            3'd5: permuted_KS = {key_in[95:80], key_in[111:96], key_in[31:16], key_in[47:32], key_in[127:112], key_in[15:0], key_in[63:48], key_in[79:64]};
            3'd6: permuted_KS = {key_in[31:16], key_in[111:96], key_in[63:48], key_in[79:64], key_in[95:80], key_in[47:32], key_in[127:112], key_in[15:0]};
            3'd7: permuted_KS = {key_in[63:48], key_in[111:96], key_in[127:112], key_in[15:0], key_in[31:16], key_in[79:64], key_in[95:80], key_in[47:32]};
            default: permuted_KS = key_in;
        endcase
    end

    wire [5:0] iround_even = (!imode && mapped_round[0]) ? {mapped_round, 1'b1} : {mapped_round, 1'b0};
    wire [5:0] iround_odd  = (!imode && mapped_round[0]) ? {mapped_round, 1'b0} : {mapped_round, 1'b1};

    wire [15:0] rk_even, rk_odd;
    wire [15:0] dummy_wk0, dummy_wk1, dummy_wk2, dummy_wk3;

    Piccolo_KeySchedule KS_even_inst(
        .KS(permuted_KS), .iround(iround_even), .imode(imode),
        .wk0(dummy_wk0), .wk1(dummy_wk1), .wk2(dummy_wk2), .wk3(dummy_wk3), .wr(rk_even)
    );
    Piccolo_KeySchedule KS_odd_inst(
        .KS(permuted_KS), .iround(iround_odd), .imode(imode),
        .wk0(dummy_wk0), .wk1(dummy_wk1), .wk2(dummy_wk2), .wk3(dummy_wk3), .wr(rk_odd)
    );

    wire [15:0] K7_b = key_in[15:0];   wire [15:0] K6_b = key_in[31:16];
    wire [15:0] K5_b = key_in[47:32];  wire [15:0] K4_b = key_in[63:48];
    wire [15:0] K3_b = key_in[79:64];  wire [15:0] K2_b = key_in[95:80];
    wire [15:0] K1_b = key_in[111:96]; wire [15:0] K0_b = key_in[127:112];

    wire [15:0] true_wk0 = imode ? {K0_b[15:8], K1_b[7:0]} : {K4_b[15:8], K7_b[7:0]};
    wire [15:0] true_wk1 = imode ? {K1_b[15:8], K0_b[7:0]} : {K7_b[15:8], K4_b[7:0]};
    wire [15:0] true_wk2 = imode ? {K4_b[15:8], K7_b[7:0]} : {K0_b[15:8], K1_b[7:0]};
    wire [15:0] true_wk3 = imode ? {K7_b[15:8], K4_b[7:0]} : {K1_b[15:8], K0_b[7:0]};

    wire [15:0] X0 = current_data[63:48];
    wire [15:0] X1 = current_data[47:32];
    wire [15:0] X2 = current_data[31:16];
    wire [15:0] X3 = current_data[15:0];

    wire [15:0] f_out_0, f_out_2;
    Piccolo_F_Function F0 (.idata(X0), .odata(f_out_0));
    Piccolo_F_Function F2 (.idata(X2), .odata(f_out_2));

    wire [15:0] next_X1 = X1 ^ f_out_0 ^ rk_even;
    wire [15:0] next_X3 = X3 ^ f_out_2 ^ rk_odd;

    wire [15:0] rp_X0 = {next_X1[15:8], next_X3[7:0]}; 
    wire [15:0] rp_X1 = {X2[15:8],      X0[7:0]};      
    wire [15:0] rp_X2 = {next_X3[15:8], next_X1[7:0]}; 
    wire [15:0] rp_X3 = {X0[15:8],      X2[7:0]};      

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
                        current_data <= {data_in[63:48] ^ true_wk0, data_in[47:32], data_in[31:16] ^ true_wk1, data_in[15:0] };
                    end
                end
                
                RUN: begin
                    if (round_cnt < 30) begin
                        current_data <= {rp_X0, rp_X1, rp_X2, rp_X3};
                        round_cnt <= round_cnt + 1;
                    end else begin
                        current_data <= {X0 ^ true_wk2, next_X1, X2 ^ true_wk3, next_X3};
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