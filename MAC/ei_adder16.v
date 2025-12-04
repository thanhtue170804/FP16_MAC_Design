module ei_adder16 (
    input [15:0] a,
    input [15:0] b,
    input cin,
    output [15:0] sum,
    output cout
);
    wire [16:0] c;
    assign c[0] = cin;

    genvar i;
    generate
        for(i=0; i<16; i=i+1) begin: ADD_16
            full_adder fa (.a(a[i]), .b(b[i]), .cin(c[i]), .sum(sum[i]), .cout(c[i+1]));
        end
    endgenerate
    assign cout = c[16];
endmodule