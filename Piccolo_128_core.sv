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

    wire [4:0] iround = imode ? round_cnt : (5'd30 - round_cnt);

    wire [15:0] wk0, wk1, wk2, wk3;
    wire [15:0] rk_even, rk_odd;

    Piccolo_KeySchedule KS_inst(
        .KS(key_in), 
        .iround(iround), 
        .imode(imode),
        .wk0(wk0), .wk1(wk1), .wk2(wk2), .wk3(wk3), 
        .rk_even(rk_even), .rk_odd(rk_odd)
    );

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
            current_data <= 0;
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
                    if (!start) state <= IDLE;
                end
                
                default: state <= IDLE;
            endcase
        end
    end
endmodule