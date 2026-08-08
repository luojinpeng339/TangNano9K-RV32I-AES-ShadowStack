`timescale 1ns/1ps

// AES-128 key expansion K0 -> K1 full-pipeline connectivity test.
// Kept under build/ so the source root remains free of testbench files.
module tb_top_pipeline_keyexp;
    reg clk   = 1'b0;
    reg rst_n = 1'b0;

    wire uart_tx, rgb_pclk, rgb_hsync, rgb_vsync, rgb_de;
    wire lcd_reset_n, lcd_disp;
    wire [4:0] rgb_r, rgb_b;
    wire [5:0] rgb_g;

    top_pipeline dut (
        .clk(clk), .rst_n(rst_n), .uart_tx(uart_tx),
        .rgb_pclk(rgb_pclk), .rgb_hsync(rgb_hsync), .rgb_vsync(rgb_vsync),
        .rgb_de(rgb_de), .lcd_reset_n(lcd_reset_n), .lcd_disp(lcd_disp),
        .rgb_r(rgb_r), .rgb_g(rgb_g), .rgb_b(rgb_b)
    );

    always #5 clk = ~clk;

    initial begin : test
        integer i;
        #1;

        // K0 = 00010203_04050607_08090A0B_0C0D0E0F.
        // Preload is deliberate: this test verifies the real five-stage
        // CPU/AES instruction data path, not constant-loading instructions.
        dut.u_id_stage.u_register_file.regs[1] = 32'h0001_0203; // w0
        dut.u_id_stage.u_register_file.regs[2] = 32'h0405_0607; // w1
        dut.u_id_stage.u_register_file.regs[3] = 32'h0809_0A0B; // w2
        dut.u_id_stage.u_register_file.regs[4] = 32'h0C0D_0E0F; // w3
        dut.u_id_stage.u_register_file.regs[14] = 32'h0100_0000; // Rcon(1)

        // x7 = RotWord(w3) = 0D0E0F0C.
        dut.u_if_stage.u_icache.u_mem.mem[0]  = 32'h0082_1293; // slli x5, x4, 8
        dut.u_if_stage.u_icache.u_mem.mem[1]  = 32'h0182_5313; // srli x6, x4, 24
        dut.u_if_stage.u_icache.u_mem.mem[2]  = 32'h0062_E3B3; // or   x7, x5, x6

        // x8 = SubWord(x7) = D7AB76FE, built with four aes32esi instructions.
        dut.u_if_stage.u_icache.u_mem.mem[3]  = 32'h2270_0433; // aes32esi x8, x0, x7, 0
        dut.u_if_stage.u_icache.u_mem.mem[4]  = 32'h6274_0433; // aes32esi x8, x8, x7, 1
        dut.u_if_stage.u_icache.u_mem.mem[5]  = 32'hA274_0433; // aes32esi x8, x8, x7, 2
        dut.u_if_stage.u_icache.u_mem.mem[6]  = 32'hE274_0433; // aes32esi x8, x8, x7, 3

        // temp = SubWord(RotWord(w3)) XOR Rcon(1).
        dut.u_if_stage.u_icache.u_mem.mem[7]  = 32'h00E4_44B3; // xor x9,  x8, x14

        // w4..w7: each word feeds the next, exercising EX/MEM and MEM/WB forwarding.
        dut.u_if_stage.u_icache.u_mem.mem[8]  = 32'h0090_C533; // xor x10, x1, x9
        dut.u_if_stage.u_icache.u_mem.mem[9]  = 32'h00A1_45B3; // xor x11, x2, x10
        dut.u_if_stage.u_icache.u_mem.mem[10] = 32'h00B1_C633; // xor x12, x3, x11
        dut.u_if_stage.u_icache.u_mem.mem[11] = 32'h00C2_46B3; // xor x13, x4, x12
        dut.u_if_stage.u_icache.u_mem.mem[12] = 32'h0000_006F; // jal x0, 0

        // Eliminate unrelated ROM contents after the stop loop.
        for (i = 13; i < 64; i = i + 1)
            dut.u_if_stage.u_icache.u_mem.mem[i] = 32'h0000_0013; // nop

        #12;
        rst_n = 1'b1;
        repeat (70) @(posedge clk);
        #1;

        $display("KEYEXP K0->K1:");
        $display("  x7 RotWord = %08h (expected 0D0E0F0C)", dut.u_id_stage.u_register_file.regs[7]);
        $display("  x8 SubWord = %08h (expected D7AB76FE)", dut.u_id_stage.u_register_file.regs[8]);
        $display("  x9 temp    = %08h (expected D6AB76FE)", dut.u_id_stage.u_register_file.regs[9]);
        $display("  x10 w4     = %08h (expected D6AA74FD)", dut.u_id_stage.u_register_file.regs[10]);
        $display("  x11 w5     = %08h (expected D2AF72FA)", dut.u_id_stage.u_register_file.regs[11]);
        $display("  x12 w6     = %08h (expected DAA678F1)", dut.u_id_stage.u_register_file.regs[12]);
        $display("  x13 w7     = %08h (expected D6AB76FE)", dut.u_id_stage.u_register_file.regs[13]);

        if (dut.u_id_stage.u_register_file.regs[7]  !== 32'h0D0E_0F0C) $fatal(1, "FAIL: RotWord");
        if (dut.u_id_stage.u_register_file.regs[8]  !== 32'hD7AB_76FE) $fatal(1, "FAIL: SubWord");
        if (dut.u_id_stage.u_register_file.regs[9]  !== 32'hD6AB_76FE) $fatal(1, "FAIL: temp / Rcon");
        if (dut.u_id_stage.u_register_file.regs[10] !== 32'hD6AA_74FD) $fatal(1, "FAIL: w4");
        if (dut.u_id_stage.u_register_file.regs[11] !== 32'hD2AF_72FA) $fatal(1, "FAIL: w5");
        if (dut.u_id_stage.u_register_file.regs[12] !== 32'hDAA6_78F1) $fatal(1, "FAIL: w6");
        if (dut.u_id_stage.u_register_file.regs[13] !== 32'hD6AB_76FE) $fatal(1, "FAIL: w7");

        $display("AES_KEYEXP_K0_TO_K1_TEST: PASS");
        $finish;
    end
endmodule
