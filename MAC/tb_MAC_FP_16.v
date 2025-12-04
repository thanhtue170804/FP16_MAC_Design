`timescale 1ns / 1ps

module tb_MAC_FP_16;

    reg clk, rst;
    reg [15:0] A, B;
    wire [15:0] Acc_Out;
    integer errors;

    MAC_FP_16 uut (
        .clk(clk), .rst(rst), .A(A), .B(B), .Acc_Out(Acc_Out)
    );

    initial begin clk = 0; forever #5 clk = ~clk; end

    // Task nạp dữ liệu
    task feed_input;
        input [15:0] in_a; input [15:0] in_b;
        begin
            @(posedge clk); #1; 
            A = in_a; B = in_b;
        end
    endtask

    // Task Reset "Siêu sạch" (Super Clean Reset)
    // Đẩy 0 vào pipeline trước và sau khi reset để xóa sạch bộ nhớ đệm
    task deep_reset;
        begin
            // 1. Đẩy input 0 vào để ngừng nạp dữ liệu mới
            A = 0; B = 0;
            repeat(2) @(posedge clk); 
            
            // 2. Giữ Reset trong 5 chu kỳ (đủ để xóa pipeline multiplier)
            rst = 1;
            repeat(5) @(posedge clk);
            
            // 3. Thả reset tại sườn xuống
            @(negedge clk) rst = 0;
            
            // 4. Đợi thêm 2 chu kỳ để hệ thống ổn định trạng thái 0
            repeat(2) @(posedge clk);
        end
    endtask

    initial begin
        $display("=== TESTBENCH MAC FP 16 - DEEP CLEAN VERSION ===");
        clk = 0; A = 0; B = 0; rst = 1; errors = 0;
        
        // Reset ban đầu
        deep_reset();

        // ==========================================================
        // TEST 1: 1.0^2 + 2.0^2 -> Expect 1.0 then 5.0
        // ==========================================================
        $display("\n--- TEST 1: Basic Accumulation ---");
        feed_input(16'h3C00, 16'h3C00); // T1: 1.0*1.0
        feed_input(16'h4000, 16'h4000); // T2: 2.0*2.0
        feed_input(0, 0);               // STOP

        // Chờ Latency (4 chu kỳ sau khi stop)
        repeat(4) @(posedge clk); 
        
        // Kiểm tra T1 (Acc = 1.0)
        @(posedge clk); #1;
        if (Acc_Out === 16'h3C00) $display("[PASS] Step 1: Acc = 1.0");
        else begin $display("[FAIL] Step 1: Exp 1.0, Got %h", Acc_Out); errors = errors + 1; end

        // Kiểm tra T2 (Acc = 5.0)
        @(posedge clk); #1;
        if (Acc_Out === 16'h4500) $display("[PASS] Step 2: Acc = 5.0");
        else begin $display("[FAIL] Step 2: Exp 5.0, Got %h", Acc_Out); errors = errors + 1; end

        // ==========================================================
        // TEST 2: Tính riêng số âm (-1.5 * 2.0 = -3.0)
        // ==========================================================
        $display("\n--- TEST 2: Negative Calc (-1.5 * 2.0) ---");
        
        // QUAN TRỌNG: Gọi Deep Reset để xóa số 5.0 và 1.0 cũ đi
        deep_reset(); 

        // Kiểm tra chắc chắn Acc đã về 0 chưa
        #1; if (Acc_Out !== 0) $display("[WARNING] Reset failed? Acc is %h", Acc_Out);

        // Bắt đầu tính phép mới
        feed_input(16'hBE00, 16'h4000); // -1.5 * 2.0 = -3.0
        feed_input(0, 0);

        // Chờ Latency (5 chu kỳ chờ + 1 chu kỳ check)
        repeat(5) @(posedge clk); 
        @(posedge clk); #1;
        
        // Mong đợi: C200 (-3.0)
        if (Acc_Out === 16'hC200) $display("[PASS] Neg Result: -3.0");
        else begin $display("[FAIL] Neg Result: Exp C200 (-3.0), Got %h", Acc_Out); errors = errors + 1; end

        // ==========================================================
        // TEST 3: Pipeline Stress
        // ==========================================================
        $display("\n--- TEST 3: Pipeline Stress ---");
        deep_reset();
        
        // Nạp 4 lần số 1.0 (Tốn 5 chu kỳ clock cho cả quá trình nạp)
        feed_input(16'h3C00, 16'h3C00); // 1.0
        feed_input(16'h3C00, 16'h3C00); // 1.0
        feed_input(16'h3C00, 16'h3C00); // 1.0
        feed_input(16'h3C00, 16'h3C00); // 1.0
        feed_input(0, 0);               // STOP

        // --- SỬA TẠI ĐÂY ---
        // Tổng thời gian nạp là 5 chu kỳ.
        // Độ trễ hệ thống là 7 chu kỳ.
        // Ta chỉ cần đợi thêm: 7 - 5 = 2 chu kỳ.
        
        repeat(2) @(posedge clk); // <--- SỬA TỪ 4 THÀNH 2
        
        // Kiểm tra Seq 1 (Acc = 1.0)
        @(posedge clk); #1; 
        if(Acc_Out === 16'h3C00) $display("[PASS] Seq 1: 1.0"); 
        else begin 
             $display("[FAIL] Seq 1: Exp 1.0, Got %h", Acc_Out); 
             errors = errors + 1; 
        end

        // Kiểm tra Seq 2 (Acc = 2.0)
        @(posedge clk); #1; 
        if(Acc_Out === 16'h4000) $display("[PASS] Seq 2: 2.0"); 
        else begin 
             $display("[FAIL] Seq 2: Exp 2.0, Got %h", Acc_Out); 
             errors = errors + 1; 
        end

        // Kiểm tra Seq 3 (Acc = 3.0)
        @(posedge clk); #1; 
        if(Acc_Out === 16'h4200) $display("[PASS] Seq 3: 3.0"); 
        else begin 
             $display("[FAIL] Seq 3: Exp 3.0, Got %h", Acc_Out); 
             errors = errors + 1; 
        end

        // Kiểm tra Seq 4 (Acc = 4.0)
        @(posedge clk); #1; 
        if(Acc_Out === 16'h4400) $display("[PASS] Seq 4: 4.0"); 
        else begin 
             $display("[FAIL] Seq 4: Exp 4.0, Got %h", Acc_Out); 
             errors = errors + 1; 
        end

        // ==========================================================
        // TEST 4: Nhân với 0
        // ==========================================================
        $display("\n--- TEST 4: Zero Multiplication ---");
        // Acc đang là 4.0. Cộng thêm 0.
        feed_input(16'h4500, 16'h0000); // 5.0 * 0.0 -> 0
        feed_input(0, 0);

        repeat(5) @(posedge clk);
        @(posedge clk); #1;
        
        if (Acc_Out === 16'h4400) $display("[PASS] Acc stable at 4.0");
        else begin $display("[FAIL] Zero Add: Changed to %h", Acc_Out); errors = errors + 1; end

        #50;
        if (errors == 0) $display("\n=== ALL TESTS PASSED ===");
        else $display("\n=== FOUND %0d ERRORS ===", errors);
        $stop;
    end
endmodule