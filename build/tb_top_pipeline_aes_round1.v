`timescale 1ns/1ps
// CPU-level FIPS-197 AES-128 Round-1 regression using standard aes32esmi.
// State words T0..T3 are x10..x13 after initial AddRoundKey.
// Round-key K1 is preloaded into x20..x23. Each output column accumulates
// four aes32esmi byte contributions exactly as the official RV32 sequence.
module tb_top_pipeline_aes_round1;
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

    function [31:0] enc_esmi;
        input [4:0] rd, rs1, rs2;
        input [1:0] bs;
        begin
            // Standard RV32 Zkne AES32ESMI: bs[31:30], funct5=10011.
            enc_esmi = {bs, 5'b10011, rs2, rs1, 3'b000, rd, 7'b0110011};
        end
    endfunction

    task emit_column;
        input integer base;
        input [4:0] dst, s0, s1, s2, s3;
        begin
            dut.u_if_stage.u_icache.u_mem.mem[base+0] = enc_esmi(dst, dst, s0, 2'd0);
            dut.u_if_stage.u_icache.u_mem.mem[base+1] = enc_esmi(dst, dst, s1, 2'd1);
            dut.u_if_stage.u_icache.u_mem.mem[base+2] = enc_esmi(dst, dst, s2, 2'd2);
            dut.u_if_stage.u_icache.u_mem.mem[base+3] = enc_esmi(dst, dst, s3, 2'd3);
        end
    endtask

    task expect_word;
        input [4:0] reg_index;
        input [31:0] want;
        begin
            if (dut.u_id_stage.u_register_file.regs[reg_index] !== want) begin
                $display("AES_ROUND1_CPU_FAIL x%0d got=%08h want=%08h", reg_index,
                    dut.u_id_stage.u_register_file.regs[reg_index], want);
                errors = errors + 1;
            end
        end
    endtask

    always @(posedge clk) begin
        if (rst_n && dut.crypto_en_e)
            $display("AES_TRACE t=%0t rd=x%0d rs1=x%0d rs2=x%0d bs=%0d fwdA=%b srcA=%08h srcB=%08h aes=%08h", $time,
                dut.rd_e, dut.rs1_e, dut.rs2_e, dut.crypto_bs_e, dut.forward_ae,
                dut.u_ex_stage.src_a_e, dut.u_ex_stage.pre_src_b_e, dut.u_ex_stage.aes_result);
    end

    initial begin
        errors = 0;
        // One startup NOP absorbs the inherited synchronous ROM/icache cold-fill
        // bubble before the first AES instruction; subsequent AES instructions
        // remain contiguous and retain full forwarding pressure.
        dut.u_if_stage.u_icache.u_mem.mem[0] = 32'h00000013; // addi x0,x0,0
        emit_column( 1, 5'd20, 5'd10, 5'd11, 5'd12, 5'd13); // U0 <- T0,T1,T2,T3
        emit_column( 5, 5'd21, 5'd11, 5'd12, 5'd13, 5'd10); // U1 <- T1,T2,T3,T0
        emit_column( 9, 5'd22, 5'd12, 5'd13, 5'd10, 5'd11); // U2 <- T2,T3,T0,T1
        emit_column(13, 5'd23, 5'd13, 5'd10, 5'd11, 5'd12); // U3 <- T3,T0,T1,T2
        dut.u_if_stage.u_icache.u_mem.mem[17] = 32'h0000006f; // jal x0,0

        // CPU register words are little-endian loads of the FIPS byte stream.
        // Therefore each printed 32-bit FIPS word is byte-swapped at this CPU
        // boundary; aes32esmi then matches the official RV32 source sequence.
        dut.u_id_stage.u_register_file.regs[10] = 32'h30201000;
        dut.u_id_stage.u_register_file.regs[11] = 32'h70605040;
        dut.u_id_stage.u_register_file.regs[12] = 32'hB0A09080;
        dut.u_id_stage.u_register_file.regs[13] = 32'hF0E0D0C0;
        dut.u_id_stage.u_register_file.regs[20] = 32'hFD74AAD6;
        dut.u_id_stage.u_register_file.regs[21] = 32'hFA72AFD2;
        dut.u_id_stage.u_register_file.regs[22] = 32'hF178A6DA;
        dut.u_id_stage.u_register_file.regs[23] = 32'hFE76ABD6;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (110) @(posedge clk);

        // CPU words are byte-swapped relative to printed FIPS state.
        expect_word(5'd20, 32'hE810D889);
        expect_word(5'd21, 32'h68CE5A85);
        expect_word(5'd22, 32'hD843182D);
        expect_word(5'd23, 32'hE48F12CB);
        if (errors == 0)
            $display("TOP_PIPELINE_AES_ROUND1_PASS state=%08h%08h%08h%08h",
                dut.u_id_stage.u_register_file.regs[20], dut.u_id_stage.u_register_file.regs[21],
                dut.u_id_stage.u_register_file.regs[22], dut.u_id_stage.u_register_file.regs[23]);
        else
            $display("TOP_PIPELINE_AES_ROUND1_FAIL errors=%0d", errors);
        $finish;
    end
endmodule
