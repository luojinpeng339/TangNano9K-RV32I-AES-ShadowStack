`timescale 1ns/1ps
// Board-faithful cold-start check: no hierarchical instruction/cache prewarm.
module tb_shadow_normal_cold;
 reg clk=0,rst_n=0; wire uart_tx,rgb_pclk,rgb_hsync,rgb_vsync,rgb_de,lcd_reset_n,lcd_disp; wire[4:0]rgb_r,rgb_b;wire[5:0]rgb_g;
 top_pipeline dut(.clk(clk),.rst_n(rst_n),.uart_tx(uart_tx),.rgb_pclk(rgb_pclk),.rgb_hsync(rgb_hsync),.rgb_vsync(rgb_vsync),.rgb_de(rgb_de),.lcd_reset_n(lcd_reset_n),.lcd_disp(lcd_disp),.rgb_r(rgb_r),.rgb_g(rgb_g),.rgb_b(rgb_b));
 always #5 clk=~clk;
 initial begin
  repeat(2) @(posedge clk); rst_n=1;
  repeat(4098) @(posedge clk);
  $display("COLD_NORMAL h=%0d ir=%0d so=%0d cc=%0d cv=%0d x5=%08h x6=%08h x10=%08h ssp=%0d",dut.security_halted,dut.minstret,dut.shadow_push_pop_count,dut.cfi_check_count,dut.cfi_violation_count,dut.u_id_stage.u_register_file.regs[5],dut.u_id_stage.u_register_file.regs[6],dut.u_id_stage.u_register_file.regs[10],dut.u_shadow_stack_mem.ssp);
  $finish;
 end
endmodule
