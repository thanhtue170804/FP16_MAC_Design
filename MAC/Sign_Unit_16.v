module Sign_Unit_16 (input A_s, B_s, output Sign);
    assign Sign = A_s ^ B_s;
endmodule