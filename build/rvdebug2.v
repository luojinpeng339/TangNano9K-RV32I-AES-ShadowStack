`timescale 1ns/1ps

// CPU baseline regression after standard RV32 register-field migration.
// Runs addi/add/sw/lw/sub through the real five-stage top pipeline.
module tb_top_pipeline_rv32i;
    reg clk = 0, rst_n = 0;
    wire uart_tx, rgb_pclk, rgb_hsync, rgb_vsync, rgb_de, lcd_reset_n, lcd_disp;
    wire [4:0] rgb_r, rgb_b; wire [5:0] rgb_g;

    top_pipeline dut (.clk(clk),.rst_n(rst_n),.uart_tx(uart_tx),.rgb_pclk(rgb_pclk),.rgb_hsync(rgb_hsync),.rgb_vsync(rgb_vsync),.rgb_de(rgb_de),.lcd_reset_n(lcd_reset_n),.lcd_disp(lcd_disp),.rgb_r(rgb_r),.rgb_g(rgb_g),.rgb_b(rgb_b));
    always #5 clk=~clk;always @(posedge clk) begin
  $display("C%0t ID=%08h | E rs1=%0d rs2=%0d rd=%0d rw=%b ALU=%08h | M rd=%0d rw=%b ALU=%08h | W rd=%0d rw=%b ALU=%08h rdata=%08h result=%08h | fwA=%b fwB=%b x4=%08h x10=%08h",$time,dut.instr_d,dut.rs1_e,dut.rs2_e,dut.rd_e,dut.reg_write_e,dut.alu_result_e,dut.rd_m,dut.reg_write_m,dut.alu_result_m,dut.rd_w,dut.reg_write_w,dut.alu_result_w,dut.read_data_w,dut.result_w,dut.forward_ae,dut.forward_be,dut.u_id_stage.u_register_file.regs[4],dut.u_id_stage.u_register_file.regs[10]);
end

    initial begin : test
        integer i;
        #1;
        // Standard encodings: addi x1,0,5; addi x2,0,7; add x3,x1,x2;
        // addi x5,0,0x200; sw x3,0(x5); lw x4,0(x5); sub x10,x4,x2; loop.
        dut.u_if_stage.u_icache.u_mem.mem[0] = 32'h00500093;
        dut.u_if_stage.u_icache.u_mem.mem[1] = 32'h00700113;
        dut.u_if_stage.u_icache.u_mem.mem[2] = 32'h002081B3;
        dut.u_if_stage.u_icache.u_mem.mem[3] = 32'h20000293;
        dut.u_if_stage.u_icache.u_mem.mem[4] = 32'h0032A023;
        dut.u_if_stage.u_icache.u_mem.mem[5] = 32'h0002A203;
        dut.u_if_stage.u_icache.u_mem.mem[6] = 32'h40220533;
        dut.u_if_stage.u_icache.u_mem.mem[7] = 32'h0000006F;
        for (i=8; i<64; i=i+1) dut.u_if_stage.u_icache.u_mem.mem[i] = 32'h00000013;
        #12 rst_n=1;
        repeat(45) @(posedge clk);
        #1;
        $display("FINAL RV32I: x1=%0d x2=%0d x3=%0d x4=%0d x5=%08h x10=%0d mem[128]=%0d",
            dut.u_id_stage.u_register_file.regs[1], dut.u_id_stage.u_register_file.regs[2],
            dut.u_id_stage.u_register_file.regs[3], dut.u_id_stage.u_register_file.regs[4],
            dut.u_id_stage.u_register_file.regs[5], dut.u_id_stage.u_register_file.regs[10],
            dut.u_mem_stage.u_data_mem.mem[128]);
        if (dut.u_id_stage.u_register_file.regs[1] !== 32'd5 ||
            dut.u_id_stage.u_register_file.regs[2] !== 32'd7 ||
            dut.u_id_stage.u_register_file.regs[3] !== 32'd12 ||
            dut.u_id_stage.u_register_file.regs[4] !== 32'd12 ||
            dut.u_id_stage.u_register_file.regs[10] !== 32'd5 ||
            dut.u_mem_stage.u_data_mem.mem[128] !== 32'd12) begin
            $display("RV32I_BASELINE_TEST: FAIL"); $fatal;
        end
        $display("RV32I_BASELINE_TEST: PASS");
        $finish;
    end
endmodule

