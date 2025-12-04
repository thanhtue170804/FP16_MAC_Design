module Normalizer_16 (
    input [21:0] Out_m,
    input [4:0] E_r,
    output reg [14:0] Normalized_Out
);
    reg [4:0] final_exp;
    reg [9:0] final_mant;

    always @(*) begin
        if (Out_m[21]) begin
          
            final_mant = Out_m[20:11]; // Lấy 10 bit sau bit MSB
            final_exp = E_r + 1;
        end else begin
        
            final_mant = Out_m[19:10]; // Lấy 10 bit sau bit 20
            final_exp = E_r;
        end

        // Kiểm tra tràn số mũ sau khi tăng
        if (final_exp >= 5'h1F) begin
            Normalized_Out = {5'h1F, 10'd0}; // Infinity
        end else begin
            Normalized_Out = {final_exp, final_mant};
        end
    end
endmodule