`timescale 1ns/1ps

module tb_top_pipeline_subword;
    reg clk = 1'b0;
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

    always #5 clk = ~clk;always @(posedge clk) begin
 $display("C%0t E bs=%0d en=%b srcA=%08h preB=%08h sel=%02h sbox=%02h aes=%08h aluE=%08h",$time,dut.crypto_bs_e,dut.crypto_en_e,dut.u_ex_stage.src_a_e,dut.u_ex_stage.pre_src_b_e,dut.u_ex_stage.u_aes32_fu.selected_byte,dut.u_ex_stage.u_aes32_fu.sbox_out,dut.u_ex_stage.aes_result,dut.alu_result_e);
end

    initial begin : test
        integer i;
        #1;

        // w3=x4=0C0D0E0F
        // RotWord(w3)=0D0E0F0C in x7
        dut.u_if_stage.u_icache.u_mem.mem[0] = 32'h00821293; // slli x5,x4,8
        dut.u_if_stage.u_icache.u_mem.mem[1] = 32'h01825313; // srli x6,x4,24
        dut.u_if_stage.u_icache.u_mem.mem[2] = 32'h0062E3B3; // or x7,x5,x6

        // x8 = SubWord(x7), four official aes32esi instructions.
        dut.u_if_stage.u_icache.u_mem.mem[3] = 32'h22700433; // aes32esi x8,x0,x7,0: FE
        dut.u_if_stage.u_icache.u_mem.mem[4] = 32'h62740433; // aes32esi x8,x8,x7,1: 76 << 8
        dut.u_if_stage.u_icache.u_mem.mem[5] = 32'hA2740433; // aes32esi x8,x8,x7,2: AB << 16
        dut.u_if_stage.u_icache.u_mem.mem[6] = 32'hE2740433; // aes32esi x8,x8,x7,3: D7 << 24
        dut.u_if_stage.u_icache.u_mem.mem[7] = 32'h0000006F; // jal x0,0

        for (i = 8; i < 64; i = i + 1)
            dut.u_if_stage.u_icache.u_mem.mem[i] = 32'h00000013;

        dut.u_id_stage.u_register_file.regs[4] = 32'h0C0D0E0F;

        #12;
        rst_n = 1'b1;
        repeat (45) @(posedge clk);
        #1;

        $display("FINAL SUBWORD: x7=%08h x8=%08h",
            dut.u_id_stage.u_register_file.regs[7],
            dut.u_id_stage.u_register_file.regs[8]);

        if (dut.u_id_stage.u_register_file.regs[7] !== 32'h0D0E0F0C) begin
            $display("FAIL: RotWord result");
            $fatal;
        end
        if (dut.u_id_stage.u_register_file.regs[8] !== 32'hD7AB76FE) begin
            $display("FAIL: SubWord result");
            $fatal;
        end

        $display("AES_SUBWORD_TEST: PASS");
        $finish;
    end
endmodule

