module aes_final_round (
    input  wire [127:0] state_in,
    input  wire [127:0] round_key,
    output wire [127:0] state_out
);

    wire [127:0] sub_state;
    wire [127:0] shift_state;

    aes_subbytes u_sub (
        .in_state(state_in),
        .out_state(sub_state)
    );

    aes_shiftrows u_shift (
        .in_state(sub_state),
        .out_state(shift_state)
    );

    aes_addroundkey u_add (
        .state_in(shift_state),
        .round_key(round_key),
        .out_state(state_out)
    );
endmodule
