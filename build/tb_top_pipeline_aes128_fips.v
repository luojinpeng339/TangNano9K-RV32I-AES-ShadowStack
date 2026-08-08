`timescale 1ns/1ps
// Full CPU AES-128 FIPS-197 regression.
// Input state is ARK0 and x20..x23 hold K0. Each round first derives the next
// key via custom kexp1i, then accumulates AES32 byte contributions into temps.
// No direct round-key injection by TB after reset: all K1..K10 are generated
// by instructions running through the five-stage pipeline.
module tb_top_pipeline_aes128_fips;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire uart_tx, rgb_pclk, rgb_hsync, rgb_vsync, rgb_de, lcd_reset_n, lcd_disp;
    wire [4:0] rgb_r, rgb_b;
    wire [5:0] rgb_g;
    integer errors, pc, round;

    top_pipeline dut (
        .clk(clk), .rst_n(rst_n), .uart_tx(uart_tx), .rgb_pclk(rgb_pclk),
        .rgb_hsync(rgb_hsync), .rgb_vsync(rgb_vsync), .rgb_de(rgb_de),
        .lcd_reset_n(lcd_reset_n), .lcd_disp(lcd_disp), .rgb_r(rgb_r),
        .rgb_g(rgb_g), .rgb_b(rgb_b)
    );
    always #5 clk = ~clk;

    function [31:0] enc_kexp1i;
        input [4:0] rd, rs1, rnum;
        begin enc_kexp1i = {7'b0,rnum,rs1,3'b000,rd,7'b0001011}; end
    endfunction
    function [31:0] enc_xor;
        input [4:0] rd, rs1, rs2;
        begin enc_xor = {7'b0,rs2,rs1,3'b100,rd,7'b0110011}; end
    endfunction
    function [31:0] enc_aes;
        input is_final;
        input [4:0] rd, rs1, rs2;
        input [1:0] bs;
        begin
            enc_aes = {bs, (is_final ? 5'b10001 : 5'b10011), rs2, rs1, 3'b000, rd, 7'b0110011};
        end
    endfunction
    function [31:0] enc_shift;
        input is_right;
        input [4:0] rd, rs1;
        input [4:0] shamt;
        begin
            enc_shift = {7'b0000000, shamt, rs1, (is_right ? 3'b101 : 3'b001), rd, 7'b0010011};
        end
    endfunction

    task emit_key_next;
        input [4:0] rnum;
        begin
            dut.u_if_stage.u_icache.u_mem.mem[pc+0] = enc_kexp1i(5'd19,5'd23,rnum);
            dut.u_if_stage.u_icache.u_mem.mem[pc+1] = enc_xor(5'd20,5'd20,5'd19);
            dut.u_if_stage.u_icache.u_mem.mem[pc+2] = enc_xor(5'd21,5'd21,5'd20);
            dut.u_if_stage.u_icache.u_mem.mem[pc+3] = enc_xor(5'd22,5'd22,5'd21);
            dut.u_if_stage.u_icache.u_mem.mem[pc+4] = enc_xor(5'd23,5'd23,5'd22);
            pc = pc + 5;
        end
    endtask
    task emit_bswap;
        input [4:0] dst, src;
        begin
            // dst=bswap32(src), strictly isolating one byte at a time using
            // only existing SLLI/SRLI/XOR. x18 accumulator, x19 scratch.
            // Source bytes [31:24,23:16,15:8,7:0] become [7:0,15:8,23:16,31:24].
            dut.u_if_stage.u_icache.u_mem.mem[pc+0]  = enc_shift(0,5'd18,src,5'd24); // old b0 -> new b3
            dut.u_if_stage.u_icache.u_mem.mem[pc+1]  = enc_shift(0,5'd19,src,5'd16);
            dut.u_if_stage.u_icache.u_mem.mem[pc+2]  = enc_shift(1,5'd19,5'd19,5'd24); // isolate old b1
            dut.u_if_stage.u_icache.u_mem.mem[pc+3]  = enc_shift(0,5'd19,5'd19,5'd16); // old b1 -> new b2
            dut.u_if_stage.u_icache.u_mem.mem[pc+4]  = enc_xor(5'd18,5'd18,5'd19);
            dut.u_if_stage.u_icache.u_mem.mem[pc+5]  = enc_shift(0,5'd19,src,5'd8);
            dut.u_if_stage.u_icache.u_mem.mem[pc+6]  = enc_shift(1,5'd19,5'd19,5'd24); // isolate old b2
            dut.u_if_stage.u_icache.u_mem.mem[pc+7]  = enc_shift(0,5'd19,5'd19,5'd8);  // old b2 -> new b1
            dut.u_if_stage.u_icache.u_mem.mem[pc+8]  = enc_xor(5'd18,5'd18,5'd19);
            dut.u_if_stage.u_icache.u_mem.mem[pc+9]  = enc_shift(1,5'd19,src,5'd24);  // old b3 -> new b0
            dut.u_if_stage.u_icache.u_mem.mem[pc+10] = enc_xor(dst,5'd18,5'd19);
            pc = pc + 11;
        end
    endtask
    task emit_state_round;
        input is_final;
        integer c, b;
        reg [4:0] dst, src;
        begin
            // Convert newly generated key words from key-schedule/FIPS word
            // order to the little-endian word order used by aes32esmi state.
            emit_bswap(5'd24,5'd20);
            emit_bswap(5'd25,5'd21);
            emit_bswap(5'd26,5'd22);
            emit_bswap(5'd27,5'd23);
            // Seed accumulators U0..U3 in x14..x17 with the converted key.
            for (c=0; c<4; c=c+1)
                dut.u_if_stage.u_icache.u_mem.mem[pc+c] = enc_xor(5'd14+c,5'd24+c,5'd0);
            pc = pc + 4;
            for (c=0; c<4; c=c+1)
                for (b=0; b<4; b=b+1) begin
                    dst = 5'd14+c;
                    src = 5'd10+((c+b)%4);
                    dut.u_if_stage.u_icache.u_mem.mem[pc] = enc_aes(is_final,dst,dst,src,b[1:0]);
                    pc = pc + 1;
                end
            for (c=0; c<4; c=c+1)
                dut.u_if_stage.u_icache.u_mem.mem[pc+c] = enc_xor(5'd10+c,5'd14+c,5'd0);
            pc = pc + 4;
        end
    endtask

    task expect_word;
        input [4:0] reg_index;
        input [31:0] want;
        begin
            if (dut.u_id_stage.u_register_file.regs[reg_index] !== want) begin
                $display("AES128_CPU_FAIL x%0d got=%08h want=%08h",reg_index,
                    dut.u_id_stage.u_register_file.regs[reg_index],want);
                errors=errors+1;
            end
        end
    endtask

    initial begin
        errors=0; pc=0;
        // Absorb inherited synchronous instr-mem / icache cold fill.
        dut.u_if_stage.u_icache.u_mem.mem[pc] = 32'h00000013; pc=pc+1;
        for (round=1; round<=10; round=round+1) begin
            emit_key_next(round[4:0]);
            emit_state_round(round==10);
        end
        dut.u_if_stage.u_icache.u_mem.mem[pc] = 32'h0000006f; // terminal loop

        // State words are little-endian for the RV32 AES32 round sequence.
        // Key-schedule words deliberately stay in FIPS/MSB-first order because
        // kexp1i implements RotWord/SubWord on that representation; each new
        // key is byte-swapped only when injected into a state round.
        dut.u_id_stage.u_register_file.regs[10]=32'h30201000;
        dut.u_id_stage.u_register_file.regs[11]=32'h70605040;
        dut.u_id_stage.u_register_file.regs[12]=32'hB0A09080;
        dut.u_id_stage.u_register_file.regs[13]=32'hF0E0D0C0;
        dut.u_id_stage.u_register_file.regs[20]=32'h00010203;
        dut.u_id_stage.u_register_file.regs[21]=32'h04050607;
        dut.u_id_stage.u_register_file.regs[22]=32'h08090A0B;
        dut.u_id_stage.u_register_file.regs[23]=32'h0C0D0E0F;

        repeat(3) @(posedge clk); rst_n=1'b1;
        // 10*(5+4*11+4+16+4)+startup = 741 instructions plus pipeline/terminal slack.
        repeat(2200) @(posedge clk);

        // FIPS ciphertext 69C4E0D8 6A7B0430  D8CDB780 70B4C55A,
        // represented as CPU little-endian 32-bit words.
        expect_word(5'd10,32'hD8E0C469);
        expect_word(5'd11,32'h30047B6A);
        expect_word(5'd12,32'h80B7CDD8);
        expect_word(5'd13,32'h5AC5B470);
        if(errors==0)
            $display("TOP_PIPELINE_AES128_FIPS_PASS ciphertext=69C4E0D86A7B0430D8CDB78070B4C55A instructions=%0d",pc);
        else $display("TOP_PIPELINE_AES128_FIPS_FAIL errors=%0d",errors);
        $finish;
    end
endmodule
