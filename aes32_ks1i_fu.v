module aes32_ks1i_fu (
    input  wire [31:0] rs1,
    input wire [4:0] rnum,
    output wire [31:0] result
);

    // Step 1: 32-bit word rotate-left by one byte
    wire [31:0] rotword;
    assign rotword = {rs1[23:0], rs1[31:24]};
    // Step 2: four independent AES S-box outputs
    wire [7:0] sb0;
    wire [7:0] sb1;
    wire [7:0] sb2;
    wire [7:0] sb3;

    aes_sbox u0(.sbox_in(rotword[31:24]), .sbox_out(sb3));
    aes_sbox u1(.sbox_in(rotword[23:16]), .sbox_out(sb2));
    aes_sbox u2(.sbox_in(rotword[15:8]), .sbox_out(sb1));
    aes_sbox u3(.sbox_in(rotword[7:0]), .sbox_out(sb0));
    
    wire [31:0] subword = {sb3, sb2, sb1, sb0};
    // Step 3: one AES round constant byte and its 32-bit placement

    reg [7:0] rcon_byte;
    always @(*) begin
        case (rnum)
            5'd1: rcon_byte = 8'h01;
            5'd2: rcon_byte = 8'h02;
            5'd3: rcon_byte = 8'h04;
            5'd4: rcon_byte = 8'h08;
            5'd5: rcon_byte = 8'h10;
            5'd6: rcon_byte = 8'h20;
            5'd7: rcon_byte = 8'h40;
            5'd8: rcon_byte = 8'h80;
            5'd9: rcon_byte = 8'h1b;
            5'd10: rcon_byte = 8'h36;
            default: rcon_byte = 8'h00;
        endcase
    end

    wire [31:0] rcon_word = {rcon_byte, 24'h00};

    assign result = subword ^ rcon_word;

endmodule



