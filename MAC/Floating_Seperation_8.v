module Floating_Seperation_8 (
    input [7:0] A, B,
    output Sign_A, Sign_B,
    output [2:0] Mantissa_A, Mantissa_B, // 3 bit mantissa
    output [3:0] Exponent_A, Exponent_B  // 4 bit exponent
);
    assign Sign_A = A[7];
    assign Sign_B = B[7];
    assign Exponent_A = A[6:3];
    assign Exponent_B = B[6:3];
    assign Mantissa_A = A[2:0];
    assign Mantissa_B = B[2:0];
endmodule