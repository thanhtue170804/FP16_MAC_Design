`timescale 1ns / 1ps

module MAC_FP_16 (
    input wire clk,
    input wire rst,
    input wire [15:0] A,
    input wire [15:0] B,
    output wire [15:0] Acc_Out // Đầu ra của bộ tích lũy
);

    // --- Dây kết nối nội bộ ---
    wire [15:0] product_res;   // Kết quả nhân (Sau 5 chu kỳ)
    wire [15:0] sum_res;       // Kết quả cộng (Combinational)
    wire [15:0] acc_feedback;  // Dây hồi tiếp từ thanh ghi Acc quay lại bộ cộng

    // 1. Bộ Nhân (Strict Multiplier)
    // Latency: 5 chu kỳ clock
    FP_Mul_16 u_multiplier (
        .clk(clk), 
        .rst(rst),
        .A(A), 
        .B(B),
        .Mul_Out(product_res)
    );

    // 2. Bộ Cộng (Strict Adder)
    // Thực hiện: Product + Accumulator_Cũ
    FP_Add_16 u_adder (
        .A(product_res),   // Số hạng 1: Kết quả nhân
        .B(acc_feedback),  // Số hạng 2: Giá trị tích lũy hiện tại
        .Sum_Out(sum_res)
    );

    // 3. Thanh ghi Tích lũy (Accumulator Register)
    // Lưu trữ kết quả cộng tại sườn lên xung clock
    // Dùng module regN (đã có trong Basic_Structural.v)
    regN #(.WIDTH(16)) u_acc_reg (
        .clk(clk),
        .rst(rst),
        .en(1'b1),         // Luôn cho phép ghi (hoặc thêm logic enable nếu muốn)
        .d(sum_res),       // Input: Kết quả từ bộ cộng
        .q(acc_feedback)   // Output: Hồi tiếp về bộ cộng và ra ngoài
    );

    // Gán đầu ra
    assign Acc_Out = acc_feedback;

endmodule