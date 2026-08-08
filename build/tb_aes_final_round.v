`timescale 1ns/1ps
module tb_aes_final_round;
    reg [127:0] state_in;
    reg [127:0] round_key;
    wire [127:0] state_out;
    integer fails;

    aes_final_round dut (
        .state_in(state_in),
        .round_key(round_key),
        .state_out(state_out)
    );

    task check;
        input [127:0] s;
        input [127:0] k;
        input [127:0] expected;
        begin
            state_in = s;
            round_key = k;
            #1;
            $display("state=%032h key=%032h -> %032h (expected %032h)", s, k, state_out, expected);
            if (state_out !== expected) fails = fails + 1;
        end
    endtask

    initial begin
        fails = 0;
        // FIPS-197 AES-128: R9 -> final round with K10.
        check(128'hBD6E7C3DF2B5779E0B61216E8B10B689,
              128'h13111D7FE3944A17F307A78B4D2B30C5,
              128'h69C4E0D86A7B0430D8CDB78070B4C55A);
        // SBox(00)=63; ShiftRows preserves a uniform State; then XOR key.
        check(128'h00000000000000000000000000000000,
              128'h00000000000000000000000000000000,
              128'h63636363636363636363636363636363);
        check(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
              128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
              128'hE9E9E9E9E9E9E9E9E9E9E9E9E9E9E9E9);
        if (fails == 0) $display("AES_FINAL_ROUND_TEST: PASS");
        else $fatal(1, "AES_FINAL_ROUND_TEST: %0d failures", fails);
        $finish;
    end
endmodule
