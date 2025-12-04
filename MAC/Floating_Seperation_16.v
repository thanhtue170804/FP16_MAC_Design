module Floating_Seperation_16 (
    input [15:0] A,
    input [15:0] B,
    output Sign_A, 
    output Sign_B,
    output [9:0] Mantissa_A, 
    output [9:0] Mantissa_B,
    output [4:0] Exponent_A, 
    output [4:0] Exponent_B
);
    assign Sign_A = A[15];
    assign Sign_B = B[15];
    
    assign Exponent_A = A[14:10];
    assign Exponent_B = B[14:10];
    
    assign Mantissa_A = A[9:0];
    assign Mantissa_B = B[9:0];

endmodule