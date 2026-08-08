`timescale 1ns/1ps
module tb_aes_shiftrows;
    reg [127:0] in_state;
    wire [127:0] out_state;
    integer fails;

    aes_shiftrows dut (.in_state(in_state), .out_state(out_state));

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
        check(128'h00112233445566778899AABBCCDDEEFF,
              128'h0055AAFF4499EE3388DD2277CC1166BB);
        check(128'h63CAB7040953D051CD60E0E7BA70E18C,
              128'h6353E08C0960E104CD70B751BACAD0E7);
        check(128'h00000000000000000000000000000000,
              128'h00000000000000000000000000000000);
        check(128'h000102030405060708090A0B0C0D0E0F,
              128'h00050A0F04090E03080D02070C01060B);
        if (fails == 0) $display("AES_SHIFTROWS_TEST: PASS");
        else $fatal(1, "AES_SHIFTROWS_TEST: %0d failures", fails);
        $finish;
    end
endmodule
