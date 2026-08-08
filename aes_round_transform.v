module aes_round_transform (
    input  wire [127:0] in_state,
    output wire [127:0] out_state
);
    wire [127:0] sub_state;
    wire [127:0] shift_state;

    aes_subbytes u_subbytes (
        .in_state(in_state),
        .out_state(sub_state)
    );

    aes_shiftrows u_shiftrows (
        .in_state(sub_state),
        .out_state(shift_state)
    );

    wire [31:0] col0_in = shift_state[127:96];
    wire [31:0] col1_in = shift_state[95:64];
    wire [31:0] col2_in = shift_state[63:32];
    wire [31:0] col3_in = shift_state[31:0];

    wire [31:0] col0_out;
    wire [31:0] col1_out;
    wire [31:0] col2_out;
    wire [31:0] col3_out;

    aes_mixcolumn u_mix0 (
        .in_col(col0_in),
        .out_col(col0_out)
    );
    aes_mixcolumn u_mix1 (
        .in_col(col1_in),
        .out_col(col1_out)
    );
    aes_mixcolumn u_mix2 (
        .in_col(col2_in),
        .out_col(col2_out)
    );
    aes_mixcolumn u_mix3 (
        .in_col(col3_in),
        .out_col(col3_out)
    );

    assign out_state = {col0_out, col1_out, col2_out, col3_out};
endmodule
