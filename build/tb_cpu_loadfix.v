`timescale 1ns/1ps
// Temporary CPU architectural smoke test. Kept under build/; not RTL.
module tb_cpu_loadfix;
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
        input [4:0] n;
        input [31:0] want;
        begin
            if (dut.u_id_stage.u_register_file.regs[n] !== want) begin
                $display("CPU_REG_FAIL x%0d got=%08h want=%08h", n, dut.u_id_stage.u_register_file.regs[n], want);
                errors = errors + 1;
            end
        end
    endtask

    initial begin
        #17 rst_n = 1'b1;
        repeat (45) @(posedge clk);
        expect_reg(5'd1, 32'd5);
        expect_reg(5'd2, 32'd7);
        expect_reg(5'd3, 32'd12);
        expect_reg(5'd4, 32'd12);
        expect_reg(5'd10, 32'd5);
        if (dut.u_mem_stage.u_data_mem.mem[10'd128] !== 32'd12) begin
            $display("CPU_MEM_FAIL mem[128] got=%08h want=0000000c", dut.u_mem_stage.u_data_mem.mem[10'd128]);
            errors = errors + 1;
        end
        if (errors == 0) $display("TB_CPU_LOADFIX_PASS");
        else $display("TB_CPU_LOADFIX_FAIL errors=%0d", errors);
        $finish;
    end
endmodule
