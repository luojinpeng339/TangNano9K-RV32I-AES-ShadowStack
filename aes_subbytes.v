module aes_subbytes (
    input wire [127:0] in_state,
    output wire [127:0] out_state
);
    
    wire [7:0] byte0  = in_state[127:120];
    wire [7:0] byte1  = in_state[119:112];
    wire [7:0] byte2  = in_state[111:104];
    wire [7:0] byte3  = in_state[103:96];
    wire [7:0] byte4  = in_state[95:88];
    wire [7:0] byte5  = in_state[87:80];
    wire [7:0] byte6  = in_state[79:72];
    wire [7:0] byte7  = in_state[71:64];
    wire [7:0] byte8  = in_state[63:56];
    wire [7:0] byte9  = in_state[55:48];
    wire [7:0] byte10 = in_state[47:40];
    wire [7:0] byte11 = in_state[39:32];
    wire [7:0] byte12 = in_state[31:24];
    wire [7:0] byte13 = in_state[23:16];
    wire [7:0] byte14 = in_state[15:8];
    wire [7:0] byte15 = in_state[7:0];

    // ------------------------------------------------------------
    // 2. 16 个 S 盒并行实例化（复用你已验证的 aes_sbox.v）
    // ------------------------------------------------------------

    wire [7:0] out0,  out1,  out2,  out3;
    wire [7:0] out4,  out5,  out6,  out7;
    wire [7:0] out8,  out9,  out10, out11;
    wire [7:0] out12, out13, out14, out15;

    aes_sbox u0  (.sbox_in(byte0),  .sbox_out(out0));
    aes_sbox u1  (.sbox_in(byte1),  .sbox_out(out1));
    aes_sbox u2  (.sbox_in(byte2),  .sbox_out(out2));
    aes_sbox u3  (.sbox_in(byte3),  .sbox_out(out3));
    aes_sbox u4  (.sbox_in(byte4),  .sbox_out(out4));
    aes_sbox u5  (.sbox_in(byte5),  .sbox_out(out5));
    aes_sbox u6  (.sbox_in(byte6),  .sbox_out(out6));
    aes_sbox u7  (.sbox_in(byte7),  .sbox_out(out7));
    aes_sbox u8  (.sbox_in(byte8),  .sbox_out(out8));
    aes_sbox u9  (.sbox_in(byte9),  .sbox_out(out9));
    aes_sbox u10 (.sbox_in(byte10), .sbox_out(out10));
    aes_sbox u11 (.sbox_in(byte11), .sbox_out(out11));
    aes_sbox u12 (.sbox_in(byte12), .sbox_out(out12));
    aes_sbox u13 (.sbox_in(byte13), .sbox_out(out13));
    aes_sbox u14 (.sbox_in(byte14), .sbox_out(out14));
    aes_sbox u15 (.sbox_in(byte15), .sbox_out(out15));

    // ------------------------------------------------------------
    // 3. 拼包：16 个字节 → 128 位（保持高到低顺序）
    // ------------------------------------------------------------
    assign out_state = {
        out0,  out1,  out2,  out3,
        out4,  out5,  out6,  out7,
        out8,  out9,  out10, out11,
        out12, out13, out14, out15
    };

endmodule
