`timescale 1ns/1ps
// Vector-driven verification for aes32_ks1i_fu.
// Generated vectors cover rnum=0..10, FIPS round inputs, and random words.
module tb_aes32_ks1i_fu;
    reg [31:0] rs1;
    reg [4:0]  rnum;
    wire [31:0] result;
    reg [31:0] expected;
    integer fd, rc, cases, errors;

    aes32_ks1i_fu dut (.rs1(rs1), .rnum(rnum), .result(result));

    initial begin
        cases = 0; errors = 0;
        fd = $fopen("build/aes32_ks1i_vectors.txt", "r");
        if (fd == 0) begin
            $display("AES32_KS1I_TB_FATAL: vector file missing");
            $finish_and_return(1);
        end
        while (!$feof(fd)) begin
            rc = $fscanf(fd, "%h %d %h\n", rs1, rnum, expected);
            if (rc == 3) begin
                #1;
                cases = cases + 1;
                if (result !== expected) begin
                    if (errors < 12)
                        $display("AES32_KS1I_FAIL n=%0d rs1=%08h rnum=%0d got=%08h want=%08h", cases, rs1, rnum, result, expected);
                    errors = errors + 1;
                end
            end else begin
                rc = $fgetc(fd);
            end
        end
        $fclose(fd);
        if (errors == 0) $display("AES32_KS1I_TB_PASS cases=%0d", cases);
        else $display("AES32_KS1I_TB_FAIL cases=%0d errors=%0d", cases, errors);
        $finish;
    end
endmodule
