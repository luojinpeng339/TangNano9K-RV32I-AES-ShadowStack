`timescale 1ns/1ps
// Verification-only: injects a base-RV32I load-use program hierarchically.
// Does not modify test_program.hex or any core RTL source.
module tb_load_use_regression;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    wire uart_tx, rgb_pclk, rgb_hsync, rgb_vsync, rgb_de, lcd_reset_n, lcd_disp;
    wire [4:0] rgb_r, rgb_b;
    wire [5:0] rgb_g;
    integer errors = 0;
    always #5 clk = ~clk;

    top_pipeline dut (
        .clk(clk), .rst_n(rst_n), .uart_tx(uart_tx), .rgb_pclk(rgb_pclk),
        .rgb_hsync(rgb_hsync), .rgb_vsync(rgb_vsync), .rgb_de(rgb_de),
        .lcd_reset_n(lcd_reset_n), .lcd_disp(lcd_disp), .rgb_r(rgb_r), .rgb_g(rgb_g), .rgb_b(rgb_b)
    );

    task expect_reg;
        input [4:0] index;
        input [31:0] want;
        begin
            if (dut.u_id_stage.u_register_file.regs[index] !== want) begin
                $display("LOAD_USE_REG_FAIL x%0d got=%08h want=%08h", index,
                         dut.u_id_stage.u_register_file.regs[index], want);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        // Program:
        // addi x1,x0,12; addi x2,x0,7; addi x5,x0,512;
        // sw x1,0(x5); lw x4,0(x5); sub x10,x4,x2; jal x0,0.
        #1;
        dut.u_if_stage.u_icache.u_mem.mem[0] = 32'h00c00093;
        dut.u_if_stage.u_icache.u_mem.mem[1] = 32'h00700113;
        dut.u_if_stage.u_icache.u_mem.mem[2] = 32'h20000293;
        dut.u_if_stage.u_icache.u_mem.mem[3] = 32'h0012a023;
        dut.u_if_stage.u_icache.u_mem.mem[4] = 32'h0002a203;
        dut.u_if_stage.u_icache.u_mem.mem[5] = 32'h40220533;
        dut.u_if_stage.u_icache.u_mem.mem[6] = 32'h0000006f;
        rst_n = 1'b0;
        #16 rst_n = 1'b1;
        repeat (48) @(posedge clk);

        expect_reg(5'd1, 32'd12);
        expect_reg(5'd2, 32'd7);
        expect_reg(5'd4, 32'd12);
        expect_reg(5'd10, 32'd5);
        if (dut.u_mem_stage.u_data_mem.mem[10'd128] !== 32'd12) begin
            $display("LOAD_USE_MEM_FAIL mem[128] got=%08h want=0000000c",
                     dut.u_mem_stage.u_data_mem.mem[10'd128]);
            errors = errors + 1;
        end
        if (errors == 0) $display("LOAD_USE_REGRESSION_PASS");
        else $display("LOAD_USE_REGRESSION_FAIL errors=%0d", errors);
        $finish;
    end
endmodule
