module aes_addroundkey (
    input wire [127:0] state_in,
    input [127:0] round_key,
    output [127: 0] out_state
);

   assign out_state = state_in ^ round_key;
endmodule