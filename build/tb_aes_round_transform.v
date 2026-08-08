`timescale 1ns/1ps
module tb_aes_round_transform;
    reg [127:0] in_state;
    wire [127:0] out_state;
    integer fails;

    aes_round_transform dut (.in_state(in_state), .out_state(out_state));

    task check;
        input [127:0] vin;
        input [127:0] vexp;
        begin
            in_state = vin; #1;
            $display("%032h -> %032h (expected %032h)", vin, out_state, vexp);
            if (out_state !== vexp) begin
                $display("FAIL");
                fails = fails + 1;
            end
        end
    endtask

    initial begin
        fails = 0;
        // FIPS-197: state after initial AddRoundKey -> SubBytes/ShiftRows/MixColumns.
        check(128'h00102030405060708090A0B0C0D0E0F0,
              128'h5F72641557F5BC92F7BE3B291DB9F91A);
        // Zero state: SBox(00)=63, then linear transform.
        check(128'h00000000000000000000000000000000,
              128'h63636363636363636363636363636363);
        // All-FF state: SBox(FF)=16, linear transform preserves a constant column.
        check(128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
              128'h16161616161616161616161616161616);
        if (fails == 0) $display("AES_ROUND_TRANSFORM_TEST: PASS");
        else $fatal(1, "AES_ROUND_TRANSFORM_TEST: %0d failures", fails);
        $finish;
    end
endmodule
