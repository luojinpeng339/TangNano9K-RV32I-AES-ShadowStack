module aes_shiftrows (
    input wire [127:0] in_state,
    output wire [127:0] out_state
);
// ============================================================
// AES拆包
// ============================================================
wire [7:0] s00 = in_state[127:120];    //第0列
wire [7:0] s10 = in_state[119:112];   
wire [7:0] s20 = in_state[111:104];   
wire [7:0] s30 = in_state[103:96];    

wire [7:0] s01 = in_state[95:88];     // 第1列
wire [7:0] s11 = in_state[87:80];     
wire [7:0] s21 = in_state[79:72];     
wire [7:0] s31 = in_state[71:64];     

wire [7:0] s02 = in_state[63:56];     // 第2列
wire [7:0] s12 = in_state[55:48];     
wire [7:0] s22 = in_state[47:40];    
wire [7:0] s32 = in_state[39:32];     

wire [7:0] s03 = in_state[31:24];     // 第3列
wire [7:0] s13 = in_state[23:16];     
wire [7:0] s23 = in_state[15:8];      
wire [7:0] s33 = in_state[7:0];       


assign out_state = {
    s00, s11, s22, s33,
    s01, s12, s23, s30,
    s02, s13, s20, s31,
    s03, s10, s21, s32
};
    
endmodule