`timescale 1ns / 1ps

module Mantissa_Multiplier_16 (
    input wire clk,
    input wire rst,
    input wire [10:0] A_m, 
    input wire [10:0] B_m, 
    output reg [21:0] Out_m
);

    // --- 1. CHIA CẮT DỮ LIỆU ---
    // A_m có 11 bit: [10] là bit ẩn (1), [9] là bit 0.5, [8] là bit 0.25...
    
    // 8 bit thấp: [7:0]
    wire [7:0] A_Lo = A_m[7:0];
    
    // 3 bit cao: PHẢI LÀ [10:8]. 
    // Nếu bạn để [9:7] hay sai số khác, số 1.5 sẽ bị biến thành 1.0
    wire [7:0] A_Hi = {5'b00000, A_m[10:8]}; 
    
    wire [7:0] B_Lo = B_m[7:0];
    wire [7:0] B_Hi = {5'b00000, B_m[10:8]};

    // --- 2. Khai báo dây ---
    wire [15:0] p0_LL, p1_LH, p2_HL, p3_HH;
    wire en = 1'b1; 

    // --- 3. Gọi 4 bộ nhân 8-bit ---
    ei_multiplier u_LL (.sys_clk(clk), .rst(rst), .en(en), .a_in(A_Lo), .b_in(B_Lo), .c_out(p0_LL));
    ei_multiplier u_LH (.sys_clk(clk), .rst(rst), .en(en), .a_in(A_Lo), .b_in(B_Hi), .c_out(p1_LH));
    ei_multiplier u_HL (.sys_clk(clk), .rst(rst), .en(en), .a_in(A_Hi), .b_in(B_Lo), .c_out(p2_HL));
    ei_multiplier u_HH (.sys_clk(clk), .rst(rst), .en(en), .a_in(A_Hi), .b_in(B_Hi), .c_out(p3_HH));

    // --- 4. Cộng tổng hợp ---
    always @(posedge clk) begin
        if (rst) begin
            Out_m <= 22'd0;
        end else begin
            // Shift and Add
            Out_m <= {6'b0, p0_LL} + 
                     (p1_LH << 8) + 
                     (p2_HL << 8) + 
                     (p3_HH << 16);
        end
    end

endmodule