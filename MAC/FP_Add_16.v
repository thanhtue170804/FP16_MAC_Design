`timescale 1ns / 1ps

module FP_Add_16 (
    input [15:0] A,
    input [15:0] B,
    output reg [15:0] Sum_Out
);
    // ==========================================
    // 1. PHÁT HIỆN SỐ 0 (ZERO CHECK)
    // ==========================================
    wire A_is_Zero = ~(|A[14:0]); 
    wire B_is_Zero = ~(|B[14:0]);

    // ==========================================
    // 2. LOGIC TÍNH TOÁN
    // ==========================================
    wire sA = A[15]; wire [4:0] eA = A[14:10]; wire [10:0] mA = {1'b1, A[9:0]};
    wire sB = B[15]; wire [4:0] eB = B[14:10]; wire [10:0] mB = {1'b1, B[9:0]};

    // --- So sánh Mũ ---
    wire [7:0] diff_raw;
    wire cout_cmp;
    ei_adder8 u_cmp_exp (
        .a({3'b0, eA}), 
        .b(~{3'b0, eB}), 
        .cin(1'b1),      
        .sum(diff_raw), 
        .cout(cout_cmp)  
    );
    wire A_is_Big = cout_cmp;

    // --- Swap ---
    wire [10:0] mant_big   = A_is_Big ? mA : mB;
    wire [10:0] mant_small = A_is_Big ? mB : mA;
    wire [4:0]  exp_common = A_is_Big ? eA : eB;
    wire        sign_big   = A_is_Big ? sA : sB;
    wire        sign_small = A_is_Big ? sB : sA;

    // --- Shift ---
    wire [7:0] diff_inv;
    ei_adder8 u_abs_diff (.a(~diff_raw), .b(8'd0), .cin(1'b1), .sum(diff_inv), .cout());
    wire [7:0] shift_amt = A_is_Big ? diff_raw : diff_inv;

    wire [31:0] m_big_32   = {mant_big, 21'b0}; 
    wire [31:0] m_small_32 = {mant_small, 21'b0} >> shift_amt; 

    // --- Add/Sub Mantissa ---
    wire do_sub = sign_big ^ sign_small; 
    wire [31:0] operand2 = do_sub ? ~m_small_32 : m_small_32;
    wire [31:0] sum_result;
    wire adder_cout; // <--- MỚI: Lấy carry out để check tràn

    ei_adder32 u_mant_add (
        .a(m_big_32),
        .b(operand2),
        .cin(do_sub),
        .sum(sum_result),
        .cout(adder_cout) // <--- Lấy tín hiệu này
    );

    // --- Normalize (Sửa Logic) ---
    // Tràn số xảy ra khi phép cộng (không phải trừ) tạo ra carry
    wire real_overflow = adder_cout & (~do_sub);
    
    // Nếu tràn (1x.xxx): Lấy từ bit 31 xuống. Exp + 1
    // Nếu không (1.xxx): Lấy từ bit 30 xuống. Exp giữ nguyên
    wire [9:0] final_mant = real_overflow ? sum_result[31:22] : sum_result[30:21];

    // Tăng mũ nếu tràn
    wire [7:0] final_exp_8;
    ei_adder8 u_norm_exp (
        .a({3'b0, exp_common}),
        .b({7'b0, real_overflow}),
        .cin(1'b0),
        .sum(final_exp_8),
        .cout()
    );

    wire [15:0] Calculated_Sum = {sign_big, final_exp_8[4:0], final_mant};

    // ==========================================
    // 3. BYPASS LOGIC (Ưu tiên số 0)
    // ==========================================
    always @(*) begin
        if (A_is_Zero & B_is_Zero)      Sum_Out = 16'h0000;
        else if (A_is_Zero)             Sum_Out = B;
        else if (B_is_Zero)             Sum_Out = A;
        else                            Sum_Out = Calculated_Sum;
    end

endmodule