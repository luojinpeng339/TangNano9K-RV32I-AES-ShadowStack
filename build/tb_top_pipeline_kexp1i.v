`timescale 1ns/1ps
// CPU-level regression for custom-0 kexp1i and the AES-128 K0 -> K1 chain.
// Program exercises: custom decode, ID/EX rnum latch, EX kexp FU, ordinary
// EX/MEM forwarding into four immediately dependent XOR instructions, and WB.
module tb_top_pipeline_kexp1i;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire uart_tx, rgb_pclk, rgb_hsync, rgb_vsync, rgb_de, lcd_reset_n, lcd_disp;
    wire [4:0] rgb_r, rgb_b;
    wire [5:0] rgb_g;
    integer errors;

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
            // custom-0 opcode, funct3=000: kexp1i rd,rs1,rnum
            enc_kexp1i = {7'b0000000, rnum, rs1, 3'b000, rd, 7'b0001011};
        end
    endfunction
    function [31:0] enc_xor;
        input [4:0] rd, rs1, rs2;
        begin
            enc_xor = {7'b0000000, rs2, rs1, 3'b100, rd, 7'b0110011};
        end
    endfunction

    task expect_reg;
        input [4:0] index;
        input [31:0] want;
        begin
            if (dut.u_id_stage.u_register_file.regs[index] !== want) begin
                $display("KEXP1I_CPU_FAIL x%0d got=%08h want=%08h", index,
                         dut.u_id_stage.u_register_file.regs[index], want);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        errors = 0;
        // Program: t=g(w3); w4=w0^t; w5=w1^w4; w6=w2^w5; w7=w3^w6.
        // Every XOR after kexp1i is immediately dependent on the prior result.
        dut.u_if_stage.u_icache.u_mem.mem[0] = enc_kexp1i(5'd19, 5'd13, 5'd1);
        dut.u_if_stage.u_icache.u_mem.mem[1] = enc_xor(5'd20, 5'd10, 5'd19);
        dut.u_if_stage.u_icache.u_mem.mem[2] = enc_xor(5'd21, 5'd11, 5'd20);
        dut.u_if_stage.u_icache.u_mem.mem[3] = enc_xor(5'd22, 5'd12, 5'd21);
        dut.u_if_stage.u_icache.u_mem.mem[4] = enc_xor(5'd23, 5'd13, 5'd22);
        dut.u_if_stage.u_icache.u_mem.mem[5] = 32'h0000006f; // jal x0,0

        // FIPS-197 K0 words: direct state initialization isolates the instruction
        // chain under test from constant-loading instruction coverage.
        dut.u_id_stage.u_register_file.regs[10] = 32'h00010203;
        dut.u_id_stage.u_register_file.regs[11] = 32'h04050607;
        dut.u_id_stage.u_register_file.regs[12] = 32'h08090A0B;
        dut.u_id_stage.u_register_file.regs[13] = 32'h0C0D0E0F;

        repeat (3) @(posedge clk);
        rst_n = 1'b1;
        repeat (48) @(posedge clk);

        expect_reg(5'd19, 32'hD6AB76FE); // g(w3)
        expect_reg(5'd20, 32'hD6AA74FD); // w4
        expect_reg(5'd21, 32'hD2AF72FA); // w5
        expect_reg(5'd22, 32'hDAA678F1); // w6
        expect_reg(5'd23, 32'hD6AB76FE); // w7
        if (errors == 0)
            $display("TOP_PIPELINE_KEXP1I_K0_TO_K1_PASS t=%08h w4=%08h w5=%08h w6=%08h w7=%08h",
                dut.u_id_stage.u_register_file.regs[19], dut.u_id_stage.u_register_file.regs[20],
                dut.u_id_stage.u_register_file.regs[21], dut.u_id_stage.u_register_file.regs[22],
                dut.u_id_stage.u_register_file.regs[23]);
        else
            $display("TOP_PIPELINE_KEXP1I_K0_TO_K1_FAIL errors=%0d", errors);
        $finish;
    end
endmodule
