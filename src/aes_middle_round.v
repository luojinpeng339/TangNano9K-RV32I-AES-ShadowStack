module aes_middle_round (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);

    wire [127:0] transform_state;
    wire [127:0] key_added_state;

aes_round_transform u_transform (
    .in_state(state_in),
    .out_state(transform_state)
);

aes_addroundkey u_addkey (
    .state_in(transform_state),
    .round_key(round_key),
    .out_state(state_out)
);


endmodule