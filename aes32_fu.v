module aes32_fu (
    input wire [31:0] rs1,
    input [31:0] rs2,
    input [1:0] bs,
    input wire crypto_op,
    output [31:0] aes_result
);

reg [7:0] selected_byte;

always @(*) begin
    case (bs)
        2'b00: selected_byte = rs2[7:0];
        2'b01: selected_byte = rs2[15:8];
        2'b10: selected_byte = rs2[23:16];
        2'b11: selected_byte = rs2[31:24]; 
        default: selected_byte = 8'b0;
    endcase
end

wire [7:0] sbox_out;

aes_sbox u_aes_sbox(
    .sbox_in(selected_byte),
    .sbox_out(sbox_out)
);

function [7:0] xtime;
    input [7:0] value;
    begin
        if(value[7] == 1'b1)
            xtime = (value << 1) ^ 8'h1B;
        else
            xtime = value << 1;    
    end
endfunction

wire [7:0] mul2_sbox;
wire [7:0] mul3_sbox;

assign mul2_sbox = xtime(sbox_out);
assign mul3_sbox = mul2_sbox ^ sbox_out;

wire [31:0] esmi_mixed;
assign esmi_mixed = {
        mul3_sbox,
        sbox_out,
        sbox_out,
        mul2_sbox
};

reg [31:0] esi_rotated;
reg [31:0] esmi_rotated;

always @(*) begin
        case (bs)
            2'b00: begin
                esi_rotated  = {24'b0, sbox_out};
                esmi_rotated = esmi_mixed;
            end

            2'b01: begin
                esi_rotated  = {16'b0, sbox_out, 8'b0};
                esmi_rotated = {esmi_mixed[23:0], esmi_mixed[31:24]};
            end

            2'b10: begin
                esi_rotated  = {8'b0, sbox_out, 16'b0};
                esmi_rotated = {esmi_mixed[15:0], esmi_mixed[31:16]};
            end

            2'b11: begin
                esi_rotated  = {sbox_out, 24'b0};
                esmi_rotated = {esmi_mixed[7:0], esmi_mixed[31:8]};
            end

            default: begin
                esi_rotated  = 32'b0;
                esmi_rotated = 32'b0;
            end
        endcase
    end

    assign aes_result = rs1 ^ (crypto_op ? esmi_rotated : esi_rotated);
    
endmodule