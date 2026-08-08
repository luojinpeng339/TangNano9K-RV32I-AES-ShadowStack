`timescale 1ns/1ps
module tb_aes_mixcolumn;
    reg [31:0] in_col;
    wire [31:0] out_col;
    integer fails;

    aes_mixcolumn dut (.in_col(in_col), .out_col(out_col));

    task check;
        input [31:0] vin;
        input [31:0] vexp;
        begin
            in_col = vin; #1;
            $display("%08h -> %08h (expected %08h)", vin, out_col, vexp);
            if (out_col !== vexp) begin
                $display("FAIL");
                fails = fails + 1;
            end
        end
    endtask

    initial begin
        fails = 0;
        check(32'h6353E08C, 32'h5F726415);
        check(32'h0960E104, 32'h57F5BC92);
        check(32'hCD70B751, 32'hF7BE3B29);
        check(32'hBACAD0E7, 32'h1DB9F91A);
        check(32'hDB135345, 32'h8E4DA1BC);
        check(32'h00000000, 32'h00000000);
        check(32'hFFFFFFFF, 32'hFFFFFFFF);
        if (fails == 0) $display("AES_MIXCOLUMN_TEST: PASS");
        else $fatal(1, "AES_MIXCOLUMN_TEST: %0d failures", fails);
        $finish;
    end
endmodule
