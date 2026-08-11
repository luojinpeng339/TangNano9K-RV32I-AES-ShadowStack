`timescale 1ns/1ps
// Isolate the formatter's core data operation in the actual five-stage CPU.
// Program: addi x5,0,0; lw x13,0(x5); slli x13,x13,4; jal x0,0.
module tb_os0_formatter_shift_cpu;
 reg clk=0,rst_n=0; wire uart_tx,rgb_pclk,rgb_hsync,rgb_vsync,rgb_de,lcd_reset_n,lcd_disp; wire[4:0]rgb_r,rgb_b;wire[5:0]rgb_g;integer errors=0;
 top_pipeline dut(.clk(clk),.rst_n(rst_n),.uart_rx(1'b1),.uart_tx(uart_tx),.rgb_pclk(rgb_pclk),.rgb_hsync(rgb_hsync),.rgb_vsync(rgb_vsync),.rgb_de(rgb_de),.lcd_reset_n(lcd_reset_n),.lcd_disp(lcd_disp),.rgb_r(rgb_r),.rgb_g(rgb_g),.rgb_b(rgb_b));
 always #5 clk=~clk;
 initial begin
  #1;
  dut.u_if_stage.u_instr_mem.mem[0]=32'h00000293; // addi x5,x0,0
  dut.u_if_stage.u_instr_mem.mem[1]=32'h0002a683; // lw x13,0(x5)
  dut.u_if_stage.u_instr_mem.mem[2]=32'h00469693; // slli x13,x13,4
  dut.u_if_stage.u_instr_mem.mem[3]=32'h0000006f; // jal x0,0
  dut.u_mem_stage.u_data_mem.mem[0]=32'hD1234567;
  #16 rst_n=1; repeat(45)@(posedge clk);
  if(dut.u_id_stage.u_register_file.regs[13]!==32'h12345670) begin $display("FORMATTER_SHIFT_CPU_FAIL x13=%h want=12345670",dut.u_id_stage.u_register_file.regs[13]);errors=errors+1;end
  if(errors==0)$display("FORMATTER_SHIFT_CPU_PASS x13=12345670");$finish;
 end
endmodule
