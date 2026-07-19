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
        
        $display("PICCOLO 128 ENCRYPTION PROCESS 1");
        imode = 1'b1;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(valid);
        $display("Plaintext  Input : %h", data_in);
        $display("Keytext    Input : %h", key_in);
        $display("Expected   Output: %h", 64'h5ec42cea657b89ff);
        $display("Ciphertext Output: %h", data_out);
        if (data_out === 64'h5ec42cea657b89ff) 
            $display("TEST PASSED (ENCRYPT)\n");
        else 
            $display("TEST FAILED (ENCRYPT)\n");
            
        wait(!valid);
        
        $display("PICCOLO 128 DECRYPTION PROCESS 1");
        data_in = data_out;
        imode = 1'b0;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(valid);
        $display("Ciphertext Input : %h", data_in);
        $display("Keytext    Input : %h", key_in);
        $display("Expected   Output: %h", 64'h0123456789abcdef);
        $display("Plaintext  Output: %h", data_out);
        if (data_out === 64'h0123456789abcdef) 
            $display("TEST PASSED (DECRYPT)\n");
        else 
            $display("TEST FAILED (DECRYPT)\n");

        #15 rst = 0;
       

        $display("PICCOLO 128 ENCRYPTION PROCESS 2");
        key_in  = 128'h000000000000000000fa010000000000;
        data_in = 64'h6db3f600d2c1e360;
        imode = 1'b1;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(valid);
        $display("Plaintext  Input : %h", data_in);
        $display("Keytext    Input : %h", key_in);
        $display("Expected   Output: %h", 64'hee2ee4da44483be0); 
        $display("Ciphertext Output: %h", data_out);
        if (data_out === 64'hee2ee4da44483be0) 
            $display("TEST PASSED (ENCRYPT)\n");
        else 
            $display("TEST FAILED (ENCRYPT)\n");
            
        wait(!valid);
        
        $display("PICCOLO 128 DECRYPTION PROCESS 2");
        data_in = data_out;
        imode = 1'b0;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(valid);
        $display("Ciphertext Input : %h", data_in);
        $display("Keytext    Input : %h", key_in);
        $display("Expected   Output: %h", 64'h6db3f600d2c1e360);
        $display("Plaintext  Output: %h", data_out);
        if (data_out === 64'h6db3f600d2c1e360) 
            $display("TEST PASSED (DECRYPT)\n");
        else 
            $display("TEST FAILED (DECRYPT)\n");

        #15 rst = 0;
        $display("PICCOLO 128 ENCRYPTION PROCESS 3");
        key_in  = 128'h000ff0000000000000fa010000000000;
        data_in = 64'hf8b51fb256fcbc4e;

        imode = 1'b1;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(valid);
        $display("Plaintext  Input : %h", data_in);
        $display("Keytext    Input : %h", key_in);
        $display("Expected   Output: %h", 64'h3d6863b076d7b445);
        $display("Ciphertext Output: %h", data_out);
        if (data_out === 64'h3d6863b076d7b445) 
            $display("TEST PASSED (ENCRYPT)\n");
        else 
            $display("TEST FAILED (ENCRYPT)\n");
            
        wait(!valid);
        
        $display("PICCOLO 128 DECRYPTION PROCESS 3");
        data_in = data_out;
        imode = 1'b0;
        
        @(posedge clk);
        start = 1;
        @(posedge clk);
        start = 0;
        
        wait(valid);
        $display("Ciphertext Input : %h", data_in);
        $display("Keytext    Input : %h", key_in);
        $display("Expected   Output: %h", 64'hf8b51fb256fcbc4e);
        $display("Plaintext  Output: %h", data_out);
        if (data_out === 64'hf8b51fb256fcbc4e) 
            $display("TEST PASSED (DECRYPT)\n");
        else 
            $display("TEST FAILED (DECRYPT)\n");
        
        #20 $finish;
    end
endmodule