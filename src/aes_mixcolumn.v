module aes_mixcolumn (
    input wire [31:0] in_col,
    output wire [31:0] out_col
);

    wire [7:0] a0 = in_col[31:24];
    wire [7:0] a1 = in_col[23:16];
    wire [7:0] a2 = in_col[15:8];
    wire [7:0] a3 = in_col[7:0];

    function [7:0] xtime;
        input [7:0] value;
        begin
            if (value[7] == 1'b1)
                xtime = (value << 1) ^ 8'h1B;
            else
                xtime = value << 1;
        end
    endfunction


    wire [7:0] b0 = xtime(a0) ^ (xtime(a1) ^ a1) ^ a2 ^ a3;
    wire [7:0] b1 = a0 ^ xtime(a1) ^ (xtime(a2) ^ a2) ^ a3;
    wire [7:0] b2 = a0 ^ a1 ^ xtime(a2) ^ (xtime(a3) ^ a3);
    wire [7:0] b3 = (xtime(a0) ^ a0) ^ a1 ^ a2 ^ xtime(a3);

    assign out_col = {b0, b1, b2, b3};
endmodule