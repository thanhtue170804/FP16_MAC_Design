`timescale 1ns / 1ps

module tb_FP_Mul_16;

    // --- 1. Khai báo tín hiệu ---
    reg clk;
    reg rst;
    reg [15:0] A;
    reg [15:0] B;
    wire [15:0] Mul_Out;

    // Biến thống kê lỗi
    integer errors;

    // --- 2. Kết nối Module (DUT) ---
    FP_Mul_16 uut (
        .clk(clk),
        .rst(rst),
        .A(A),
        .B(B),
        .Mul_Out(Mul_Out)
    );

    // --- 3. Tạo xung Clock (100MHz) ---
    initial begin
        clk = 0;
        forever #5 clk = ~clk;
    end

    // --- 4. Task kiểm tra đơn lẻ ---
    task test_single;
        input [15:0] in_a;
        input [15:0] in_b;
        input [15:0] expect_out;
        input [8*30:1] test_name; 
        begin
            @(posedge clk);
            #1; 
            A = in_a;
            B = in_b;

            // Latency 6 cycles
            repeat(6) @(posedge clk);
            
            #1; 
            
            if (Mul_Out === expect_out) begin
                $display("[PASS] %s | %h * %h = %h", test_name, in_a, in_b, Mul_Out);
            end else begin
                $display("[FAIL] %s | In: %h*%h | Out: %h | Exp: %h", 
                         test_name, in_a, in_b, Mul_Out, expect_out);
                // SỬA LỖI TẠI ĐÂY: Dùng phép cộng tường minh thay vì ++
                errors = errors + 1;
            end

            A = 0; B = 0;
            @(posedge clk);
        end
    endtask

    // --- 5. Chương trình chính ---
    initial begin
        $display("=======================================================");
        $display("   TESTBENCH FP_MUL_16_STRICT (VERILOG 2001 COMPATIBLE) ");
        $display("=======================================================");
        
        clk = 0; A = 0; B = 0; rst = 1; errors = 0;
        
        #20;
        @(negedge clk) rst = 0; 
        $display("--- System Reset Complete ---\n");

        // =============================================
        // PHẦN 1: KIỂM TRA ĐƠN LẺ
        // =============================================
        
        test_single(16'h3C00, 16'h3C00, 16'h3C00, "Basic: 1.0 * 1.0"); 
        test_single(16'h4000, 16'h4000, 16'h4400, "Basic: 2.0 * 2.0"); 
        test_single(16'h3E00, 16'h3C00, 16'h3E00, "Basic: 1.5 * 1.0"); 

        test_single(16'h3800, 16'h3800, 16'h3400, "Frac:  0.5 * 0.5"); 
        test_single(16'h3800, 16'h4400, 16'h4000, "Frac:  0.5 * 4.0"); 

        test_single(16'hBC00, 16'h3C00, 16'hBC00, "Sign: -1.0 * 1.0"); 
        test_single(16'hC000, 16'hC200, 16'h4600, "Sign: -2.0 * -3.0");

        test_single(16'h0000, 16'h4500, 16'h0000, "Zero:  0.0 * 5.0"); 
        test_single(16'hC400, 16'h0000, 16'h0000, "Zero: -4.0 * 0.0");

        test_single(16'h4000, 16'h4400, 16'h4800, "Norm:  2.0 * 4.0"); 


        // =============================================
        // PHẦN 2: KIỂM TRA PIPELINE BURST
        // =============================================
        $display("\n--- Starting Pipeline Burst Test ---");
        
        // Nạp liên tục
        @(posedge clk); A <= 16'h3C00; B <= 16'h3C00; // T1
        @(posedge clk); A <= 16'h4000; B <= 16'h4000; // T2
        @(posedge clk); A <= 16'h4200; B <= 16'h4000; // T3
        @(posedge clk); A <= 16'h3800; B <= 16'h4000; // T4
        @(posedge clk); A <= 16'h3E00; B <= 16'h4000; // T5
        @(posedge clk); A <= 0;        B <= 0;        // STOP

        // Chờ Latency (T1 ra lúc T=6, hiện tại T=5, chờ thêm 1 clk)
        @(posedge clk); 

        // --- SỬA LỖI ++ TẠI ĐÂY ---
        
        // Check T1
        #1; if (Mul_Out === 16'h3C00) $display("[PASS] Burst 1: 1.0"); 
            else begin $display("[FAIL] Burst 1: Exp 3C00, Got %h", Mul_Out); errors = errors + 1; end

        // Check T2
        @(posedge clk); 
        #1; if (Mul_Out === 16'h4400) $display("[PASS] Burst 2: 4.0"); 
            else begin $display("[FAIL] Burst 2: Exp 4400, Got %h", Mul_Out); errors = errors + 1; end

        // Check T3
        @(posedge clk); 
        #1; if (Mul_Out === 16'h4600) $display("[PASS] Burst 3: 6.0"); 
            else begin $display("[FAIL] Burst 3: Exp 4600, Got %h", Mul_Out); errors = errors + 1; end

        // Check T4
        @(posedge clk); 
        #1; if (Mul_Out === 16'h3C00) $display("[PASS] Burst 4: 1.0"); 
            else begin $display("[FAIL] Burst 4: Exp 3C00, Got %h", Mul_Out); errors = errors + 1; end

        // Check T5
        @(posedge clk); 
        #1; if (Mul_Out === 16'h4200) $display("[PASS] Burst 5: 3.0"); 
            else begin $display("[FAIL] Burst 5: Exp 4200, Got %h", Mul_Out); errors = errors + 1; end

        // =============================================
        // KẾT THÚC
        // =============================================
        #50;
        $display("\n=======================================================");
        if (errors == 0) 
            $display("   FINAL RESULT: ALL TESTS PASSED (SUCCESS)            ");
        else 
            $display("   FINAL RESULT: FOUND %0d ERRORS (FAILURE)            ", errors);
        $display("=======================================================");
        $stop;
    end

endmodule