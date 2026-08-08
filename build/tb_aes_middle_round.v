`timescale 1ns/1ps
module tb_aes_middle_round;
    reg [127:0] state_in, round_key;
    wire [127:0] state_out;
    integer fails;
    aes_middle_round dut (.state_in(state_in), .round_key(round_key), .state_out(state_out));
    task check;
        input [127:0] s, k, e;
        begin state_in=s; round_key=k; #1;
            $display("state=%032h key=%032h -> %032h (exp %032h)",s,k,state_out,e);
            if (state_out !== e) fails=fails+1;
        end
    endtask
    initial begin
        fails=0;
        check(128'h00102030405060708090A0B0C0D0E0F0,
              128'hD6AA74FDD2AF72FADAA678F1D6AB76FE,
              128'h89D810E8855ACE682D1843D8CB128FE4);
        check(128'h00000000000000000000000000000000,
              128'h00000000000000000000000000000000,
              128'h63636363636363636363636363636363);
        check(128'h00000000000000000000000000000000,
              128'hFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFFF,
              128'h9C9C9C9C9C9C9C9C9C9C9C9C9C9C9C9C);
        if(fails==0) $display("AES_MIDDLE_ROUND_TEST: PASS");
        else $fatal(1,"AES_MIDDLE_ROUND_TEST: %0d failures",fails);
        $finish;
    end
endmodule
