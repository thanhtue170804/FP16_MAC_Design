`timescale 1ns / 1ps

module FP_Mul_16 (
    input wire clk,
    input wire rst,
    input wire [15:0] A,
    input wire [15:0] B,
    output reg [15:0] Mul_Out
);

    // ==========================================
    // 1. TÁCH TÍN HIỆU (UNPACK)
    // ==========================================
    wire sA = A[15]; 
    wire [4:0] eA = A[14:10]; 
    wire [10:0] mA = {1'b1, A[9:0]}; // Bit ẩn 1

    wire sB = B[15]; 
    wire [4:0] eB = B[14:10]; 
    wire [10:0] mB = {1'b1, B[9:0]}; // Bit ẩn 1

    // ==========================================
    // 2. PHÁT HIỆN SỐ 0 (ZERO DETECTION LOGIC)
    // ==========================================
    // --- MỚI THÊM ---
    // Kiểm tra xem 15 bit (Exp + Mantissa) có bằng 0 hết không.
    // Dùng toán tử reduction NOR (~|) (Tương đương cổng logic NOR nhiều ngõ vào)
    wire A_is_Zero = ~(|A[14:0]); 
    wire B_is_Zero = ~(|B[14:0]);

    // Nếu A=0 HOẶC B=0 thì kết quả cuối cùng phải là 0
    wire Result_is_Zero = A_is_Zero | B_is_Zero;

    // ==========================================
    // 3. TÍNH DẤU (SIGN)
    // ==========================================
    wire s_calc = sA ^ sB;

    // ==========================================
    // 4. TÍNH MŨ (EXPONENT) - Dùng Adder Cấu Trúc
    // ==========================================
    // Công thức: E_out = Ea + Eb - Bias(15)
    
    // Bước 4.1: Ea + Eb
    wire [7:0] e_sum;
    ei_adder8 u_add_exp1 (
        .a({3'b0, eA}), 
        .b({3'b0, eB}), 
        .cin(1'b0), 
        .sum(e_sum), 
        .cout()
    );

    // Bước 4.2: Trừ 15 (Tức là cộng với bù 2 của 15: 11110001 = 0xF1)
    wire [7:0] e_calc_raw;
    ei_adder8 u_sub_bias (
        .a(e_sum), 
        .b(8'hF1),   
        .cin(1'b0), 
        .sum(e_calc_raw), 
        .cout()
    );

    // Logic kiểm tra tràn mũ (Clamping)
    // Nếu bit dấu (bit 7) hoặc bit tràn (bit 6) = 1 -> Underflow/Error -> Về 0
    wire [4:0] e_calc = (e_calc_raw[7] | e_calc_raw[6]) ? 5'b00000 : e_calc_raw[4:0];

    // ==========================================
    // 5. NHÂN MANTISSA (PIPELINE 5 CHU KỲ)
    // ==========================================
    wire [21:0] mant_mul_res;
    
    Mantissa_Multiplier_16 u_mant_mult (
        .clk(clk), 
        .rst(rst),
        .A_m(mA), 
        .B_m(mB),
        .Out_m(mant_mul_res)
    );

    // ==========================================
    // 6. PIPELINE DELAY (ĐỒNG BỘ TÍN HIỆU)
    // ==========================================
    // Ta cần truyền: Exponent, Sign VÀ Cờ Zero đi qua 5 chu kỳ
    // để đến đích cùng lúc với kết quả Mantissa.
    
    reg [4:0] pipe_e [0:4]; // Lưu Exponent
    reg       pipe_s [0:4]; // Lưu Sign
    reg       pipe_z [0:4]; // Lưu cờ Zero (--- MỚI THÊM ---)
    integer i;

    always @(posedge clk) begin
        if (rst) begin
            for(i=0; i<5; i=i+1) begin 
                pipe_e[i]<=0; pipe_s[i]<=0; pipe_z[i]<=0; 
            end
        end else begin
            // Nạp dữ liệu vào đầu ống (Stage 0)
            pipe_e[0] <= e_calc;
            pipe_s[0] <= s_calc;
            pipe_z[0] <= Result_is_Zero; // <--- Nạp cờ Zero

            // Dịch chuyển dữ liệu (Shift Register)
            pipe_e[1] <= pipe_e[0]; pipe_s[1] <= pipe_s[0]; pipe_z[1] <= pipe_z[0];
            pipe_e[2] <= pipe_e[1]; pipe_s[2] <= pipe_s[1]; pipe_z[2] <= pipe_z[1];
            pipe_e[3] <= pipe_e[2]; pipe_s[3] <= pipe_s[2]; pipe_z[3] <= pipe_z[2];
            pipe_e[4] <= pipe_e[3]; pipe_s[4] <= pipe_s[3]; pipe_z[4] <= pipe_z[3];
        end
    end

    // ==========================================
    // 7. CHUẨN HÓA & OUTPUT
    // ==========================================
    
    // Lấy dữ liệu đã trễ 5 nhịp
    wire [4:0] e_delayed = pipe_e[4];
    wire       s_delayed = pipe_s[4];
    wire       z_delayed = pipe_z[4]; // <--- Cờ Zero đã đến nơi
    wire [21:0] m_delayed = mant_mul_res;

    // Normalizer: Kiểm tra bit tràn của phép nhân (bit 21)
    wire norm_flag = m_delayed[21]; // 1.x * 1.x có thể ra >= 2.0
    
    // Tăng mũ nếu cần (Dùng adder 8 bit)
    wire [7:0] e_final_8bit;
    ei_adder8 u_inc_exp (
        .a({3'b0, e_delayed}), 
        .b({7'b0, norm_flag}), // +1 nếu norm_flag=1
        .cin(1'b0), 
        .sum(e_final_8bit), 
        .cout()
    );
    
    // Chọn Mantissa (Shift nếu cần)
    reg [9:0] m_final;
    always @(*) begin
        if (norm_flag) m_final = m_delayed[20:11]; // Dịch phải 1
        else           m_final = m_delayed[19:10]; // Giữ nguyên
    end

    // ĐÓNG GÓI OUTPUT (OUTPUT REGISTER)
    always @(posedge clk) begin
        if (rst) begin
            Mul_Out <= 0;
        end else begin
            // --- LOGIC QUAN TRỌNG: Ưu tiên số 0 ---
            // Nếu cờ Zero (đã trễ 5 nhịp) bật lên -> Ép kết quả về 0
            if (z_delayed) begin
                Mul_Out <= 16'h0000;
            end else begin
                // Ngược lại thì lấy kết quả tính toán
                Mul_Out <= {s_delayed, e_final_8bit[4:0], m_final};
            end
        end
    end

endmodule