`timescale 1ns/1ps
// End-to-end CPU regression for the custom kexp1i-assisted AES-128 schedule.
// Each AES-128 key-expansion round is exactly:
//   t=kexp1i(w3,rnum); w0^=t; w1^=w0; w2^=w1; w3^=w2.
// The four writes are immediately dependent, therefore every round tests
// EX/MEM forwarding through the normal five-stage datapath.
module tb_top_pipeline_kexp1i_k0_to_k10;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire uart_tx, rgb_pclk, rgb_hsync, rgb_vsync, rgb_de, lcd_reset_n, lcd_disp;
    wire [4:0] rgb_r, rgb_b;
    wire [5:0] rgb_g;
    integer errors, i;

    top_pipeline dut (
        .clk(clk), .rst_n(rst_n), .uart_tx(uart_tx), .rgb_pclk(rgb_pclk),
        .rgb_hsync(rgb_hsync), .rgb_vsync(rgb_vsync), .rgb_de(rgb_de),
        .lcd_reset_n(lcd_reset_n), .lcd_disp(lcd_disp), .rgb_r(rgb_r),
        .rgb_g(rgb_g), .rgb_b(rgb_b)
    );
    always #5 clk = ~clk;

    function [31:0] enc_kexp1i;
        input [4:0] rd, rs1, rnum;
        begin
            enc_kexp1i = {7'b0000000, rnum, rs1, 3'b000, rd, 7'b0001011};
        end
    endfunction
    function [31:0] enc_xor;
        input [4:0] rd, rs1, rs2;
        begin
            enc_xor = {7'b0000000, rs2, rs1, 3'b100, rd, 7'b0110011};
        end
    endfunction

    task expect_word;
        input [4:0] reg_index;
        input [31:0] want;
        begin
            if (dut.u_id_stage.u_register_file.regs[reg_index] !== want) begin
                $display("KEXP1I_K10_FAIL x%0d got=%08h want=%08h", reg_index,
                    dut.u_id_stage.u_register_file.regs[reg_index], want);
                errors = errors + 1;
            end
        end
    endtask

    task emit_round;
        input integer base;
        input [4:0] rnum;
        begin
            // x10..x13 always hold current w0..w3. x19 holds g(w3).
            dut.u_if_stage.u_icache.u_mem.mem[base+0] = enc_kexp1i(5'd19, 5'd13, rnum);
            dut.u_if_stage.u_icache.u_mem.mem[base+1] = enc_xor(5'd10, 5'd10, 5'd19);
            dut.u_if_stage.u_icache.u_mem.mem[base+2] = enc_xor(5'd11, 5'd11, 5'd10);
            dut.u_if_stage.u_icache.u_mem.mem[base+3] = enc_xor(5'd12, 5'd12, 5'd11);
            dut.u_if_stage.u_icache.u_mem.mem[base+4] = enc_xor(5'd13, 5'd13, 5'd12);
        end
    endtask

    initial begin
        errors = 0;
        for (i=0; i<10; i=i+1)
            emit_round(i*5, i+1);
        dut.u_if_stage.u_icache.u_mem.mem[50] = 32'h0000006f; // jal x0,0

        // FIPS-197 AES-128 key K0, split into word registers.
        dut.u_id_stage.u_register_file.regs[10] = 32'h00010203;
        dut.u_id_stage.u_register_file.regs[11] = 32'h04050607;
        dut.u_id_stage.u_register_file.regs[12] = 32'h08090A0B;
        dut.u_id_stage.u_register_file.regs[13] = 32'h0C0D0E0F;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        // 50 instructions plus pipeline fill, cache warm-up, and final loop.
        repeat (250) @(posedge clk);

        // FIPS-197 K10 = 13111D7F E3944A17 F307A78B 4D2B30C5.
        expect_word(5'd10, 32'h13111D7F);
        expect_word(5'd11, 32'hE3944A17);
        expect_word(5'd12, 32'hF307A78B);
        expect_word(5'd13, 32'h4D2B30C5);
        if (errors == 0)
            $display("TOP_PIPELINE_KEXP1I_K0_TO_K10_PASS K10=%08h%08h%08h%08h",
                dut.u_id_stage.u_register_file.regs[10], dut.u_id_stage.u_register_file.regs[11],
                dut.u_id_stage.u_register_file.regs[12], dut.u_id_stage.u_register_file.regs[13]);
        else
            $display("TOP_PIPELINE_KEXP1I_K0_TO_K10_FAIL errors=%0d", errors);
        $finish;
    end
endmodule
