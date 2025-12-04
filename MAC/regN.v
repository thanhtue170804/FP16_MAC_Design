module regN #(parameter WIDTH = 8) (
    input              clk,
    input              rst,
    input              en,
    input  [WIDTH-1:0] d,
    output reg [WIDTH-1:0] q
);
    always @(posedge clk) begin
        if (rst) begin
            q <= {WIDTH{1'b0}};
        end else if (en) begin
            q <= d;
        end
    end
endmodule