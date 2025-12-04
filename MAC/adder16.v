module adder16 (
    input  [15:0] a,
    input  [15:0] b,
    output [15:0] sum,
    output        cout    // carry ra cuối cùng
);
    wire [16:0] c;        // dây carry nối chuỗi các full_adder

    assign c[0] = 1'b0;   // không cộng thêm carry vào ban đầu (cin = 0)

    genvar i;
    generate
        for (i = 0; i < 16; i = i + 1) begin : ADD_CHAIN
            full_adder fa_inst (
                .a   (a[i]),
                .b   (b[i]),
                .cin (c[i]),
                .sum (sum[i]),
                .cout(c[i+1])
            );
        end
    endgenerate

    assign cout = c[16];  // carry ra của bit
endmodule