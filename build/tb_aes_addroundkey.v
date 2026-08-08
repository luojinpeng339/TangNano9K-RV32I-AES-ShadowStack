`timescale 1ns/1ps
module tb_aes_addroundkey;
    reg [127:0] state_in;
    reg [127:0] round_key;
    wire [127:0] out_state;
    integer fails;

    aes_addroundkey dut (
        .state_in(state_in),
        .round_key(round_key),
        .out_state(out_state)
    );

    task check;
        input [127:0] s;
        input [127:0] k;
        input [127:0] expected;
        begin
            state_in = s;
            round_key = k;
            #1;
            $display("%032h XOR %032h -> %032h (expected %032h)", s, k, out_state, expected);
            if (out_state !== expected) fails = fails + 1;
        end
    endtask

    initial begin
        fails = 0;
        check(128'h00112233445566778899AABBCCDDEEFF,
              128'h000102030405060708090A0B0C0D0E0F,
              128'h00102030405060708090A0B0C0D0E0F0);
        check(128'h5F72641557F5BC92F7BE3B291DB9F91A,
              128'hD6AA74FDD2AF72FADAA678F1D6AB76FE,
              128'h89D810E8855ACE682D1843D8CB128FE4);
        check(128'h00000000000000000000000000000000,
              128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
              128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF);
        check(128'h1234567890ABCDEF0011223344556677,
              128'h1234567890ABCDEF0011223344556677,
              128'h00000000000000000000000000000000);
        if (fails == 0) $display("AES_ADDROUNDKEY_TEST: PASS");
        else $fatal(1, "AES_ADDROUNDKEY_TEST: %0d failures", fails);
        $finish;
    end
endmodule
