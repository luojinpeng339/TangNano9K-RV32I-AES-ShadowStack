`timescale 1ns/1ps
module tb_attack_sequence_current;
 reg clk=0,rst_n=0;wire uart_tx,rgb_pclk,rgb_hsync,rgb_vsync,rgb_de,lcd_reset_n,lcd_disp;wire[4:0]rgb_r,rgb_b;wire[5:0]rgb_g;integer errors=0;
 top_pipeline dut(.clk(clk),.rst_n(rst_n),.uart_rx(1'b1),.uart_tx(uart_tx),.rgb_pclk(rgb_pclk),.rgb_hsync(rgb_hsync),.rgb_vsync(rgb_vsync),.rgb_de(rgb_de),.lcd_reset_n(lcd_reset_n),.lcd_disp(lcd_disp),.rgb_r(rgb_r),.rgb_g(rgb_g),.rgb_b(rgb_b));always #5 clk=~clk;
 initial begin
  // PC0 call to PC16; PC16 corrupts x1; PC20 canonical ret.
  dut.u_if_stage.u_instr_mem.mem[0]=32'h010000ef; // jal x1,+16
  dut.u_if_stage.u_instr_mem.mem[1]=32'h0000006f;
  dut.u_if_stage.u_instr_mem.mem[4]=32'h04000093; // addi x1,x0,64
  dut.u_if_stage.u_instr_mem.mem[5]=32'h00008067; // jalr x0,0(x1)
  dut.u_if_stage.u_instr_mem.mem[6]=32'h0000006f;
  #16 rst_n=1;repeat(80)@(posedge clk);
  if(!dut.security_halted||dut.cfi_violation_count!==1)begin $display("ATTACK_CURRENT_FAIL halt=%b cv=%h pc=%h",dut.security_halted,dut.cfi_violation_count,dut.u_if_stage.pc_f);errors=errors+1;end
  if(errors==0)$display("ATTACK_CURRENT_PASS halt=1 cv=1");$finish;
 end
endmodule
