module Mantissa_Normalisation_16 (
    input [9:0] A_In, 
    input [9:0] B_In,
    output [10:0] A_Out, 
    output [10:0] B_Out
);
   
    assign A_Out = {1'b1, A_In};
    assign B_Out = {1'b1, B_In};
endmodule