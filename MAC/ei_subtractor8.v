module ei_subtractor8 (
    input [7:0] a, b,
    output [7:0] diff,
    output cout // cout=1 nghĩa là kết quả dương, cout=0 là âm (mượn)
);
    wire [7:0] b_inv = ~b; // Đảo bit
    // A - B = A + (~B) + 1. 
    // Ta dùng cin=1 của bộ cộng để cộng thêm 1
    wire [8:0] c;
    assign c[0] = 1; // Cộng 1 ở đây để tạo bù 2
    
    genvar i;
    generate
        for(i=0; i<8; i=i+1) begin: SUB_LOOP
            full_adder fa (.a(a[i]), .b(b_inv[i]), .cin(c[i]), .sum(diff[i]), .cout(c[i+1]));
        end
    endgenerate
    assign cout = c[8]; 
endmodule