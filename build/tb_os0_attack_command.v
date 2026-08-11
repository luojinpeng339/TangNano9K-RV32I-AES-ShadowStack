`timescale 1ns/1ps
module tb_os0_attack_command;
 localparam CPB=2;reg clk=0,rst_n=0,host_tx=1;wire board_tx,rgb_pclk,rgb_hsync,rgb_vsync,rgb_de,lcd_reset_n,lcd_disp;wire[4:0]rgb_r,rgb_b;wire[5:0]rgb_g;integer i,k,starts=0;
 top_pipeline dut(.clk(clk),.rst_n(rst_n),.uart_rx(host_tx),.uart_tx(board_tx),.rgb_pclk(rgb_pclk),.rgb_hsync(rgb_hsync),.rgb_vsync(rgb_vsync),.rgb_de(rgb_de),.lcd_reset_n(lcd_reset_n),.lcd_disp(lcd_disp),.rgb_r(rgb_r),.rgb_g(rgb_g),.rgb_b(rgb_b));defparam dut.u_mem_stage.u_uart_mmio.CLKS_PER_BIT=CPB;always #5 clk=~clk;always@(negedge board_tx)starts=starts+1;
 task bits;input integer n;begin repeat(n*CPB)@(posedge clk);end endtask
 task send;input[7:0]v;begin host_tx=0;bits(1);for(k=0;k<8;k=k+1)begin host_tx=v[k];bits(1);end host_tx=1;bits(50);end endtask
 task discard;input integer n;integer j;begin for(j=0;j<n;j=j+1)begin@(negedge board_tx);bits(10);end end endtask
 initial begin
  $readmemh("os/uart_line_monitor.hex",dut.u_if_stage.u_instr_mem.mem);repeat(3)@(posedge clk);rst_n=1;discard(9);
  send("a");send("t");send("t");send("a");send("c");send("k");send(8'h0d);repeat(1000)@(posedge clk);
  if(dut.security_halted&&dut.cfi_violation_count==1)$display("OS0_ATTACK_COMMAND_PASS HALT=1 CV=1 CC=%h",dut.cfi_check_count);else $display("OS0_ATTACK_COMMAND_FAIL halt=%b cv=%h cc=%h pc=%h starts=%0d",dut.security_halted,dut.cfi_violation_count,dut.cfi_check_count,dut.u_if_stage.pc_f,starts);$finish;
 end
endmodule
