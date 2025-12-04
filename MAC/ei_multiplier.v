`timescale 1ns / 1ps
module ei_multiplier (
    input sys_clk, rst, en,
    input [7:0] a_in, b_in,
    output [15:0] c_out
);
    // STAGE 0
    wire [7:0] a, b;
    regN #(.WIDTH(8)) ra(sys_clk, rst, en, a_in, a);
    regN #(.WIDTH(8)) rb(sys_clk, rst, en, b_in, b);

    // STAGE 1: Partial Products 
    wire [15:0] pp[0:7];
    assign pp[0] = b[0]?{8'b0,a}:0;       assign pp[1] = b[1]?{7'b0,a,1'b0}:0;
    assign pp[2] = b[2]?{6'b0,a,2'b0}:0;  assign pp[3] = b[3]?{5'b0,a,3'b0}:0;
    assign pp[4] = b[4]?{4'b0,a,4'b0}:0;  assign pp[5] = b[5]?{3'b0,a,5'b0}:0;
    assign pp[6] = b[6]?{2'b0,a,6'b0}:0;  assign pp[7] = b[7]?{1'b0,a,7'b0}:0;

    // Adder Tree
    wire [15:0] s1[0:3];
    assign s1[0] = pp[0] + pp[1]; assign s1[1] = pp[2] + pp[3];
    assign s1[2] = pp[4] + pp[5]; assign s1[3] = pp[6] + pp[7];

    wire [15:0] r1[0:3];
    regN #(.WIDTH(16)) rr10(sys_clk, rst, en, s1[0], r1[0]);
    regN #(.WIDTH(16)) rr11(sys_clk, rst, en, s1[1], r1[1]);
    regN #(.WIDTH(16)) rr12(sys_clk, rst, en, s1[2], r1[2]);
    regN #(.WIDTH(16)) rr13(sys_clk, rst, en, s1[3], r1[3]);

    // STAGE 2
    wire [15:0] s2[0:1];
    assign s2[0] = r1[0] + r1[1]; assign s2[1] = r1[2] + r1[3];
    
    wire [15:0] r2[0:1];
    regN #(.WIDTH(16)) rr20(sys_clk, rst, en, s2[0], r2[0]);
    regN #(.WIDTH(16)) rr21(sys_clk, rst, en, s2[1], r2[1]);

    // STAGE 3
    wire [15:0] s3 = r2[0] + r2[1];
    regN #(.WIDTH(16)) rout(sys_clk, rst, en, s3, c_out);
endmodule