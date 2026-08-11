`timescale 1ns/1ps
// End-to-end formatter proof: force a known counter source and receive its
// actual bytes through the monitor's UART path. Test-only force; no RTL edit.
module tb_os0_status_known_counter;
 localparam CPB=2; reg clk=0,rst_n=0,host_tx=1; wire board_tx,rgb_pclk,rgb_hsync,rgb_vsync,rgb_de,lcd_reset_n,lcd_disp; wire[4:0]rgb_r,rgb_b;wire[5:0]rgb_g;integer i,k,errors=0;reg[7:0]got[0:15];
 top_pipeline dut(.clk(clk),.rst_n(rst_n),.uart_rx(host_tx),.uart_tx(board_tx),.rgb_pclk(rgb_pclk),.rgb_hsync(rgb_hsync),.rgb_vsync(rgb_vsync),.rgb_de(rgb_de),.lcd_reset_n(lcd_reset_n),.lcd_disp(lcd_disp),.rgb_r(rgb_r),.rgb_g(rgb_g),.rgb_b(rgb_b));
 defparam dut.u_mem_stage.u_uart_mmio.CLKS_PER_BIT=CPB;
 always #5 clk=~clk;
 task bits;input integer n;begin repeat(n*CPB)@(posedge clk);end endtask
 task send;input[7:0]v;begin host_tx=0;bits(1);for(k=0;k<8;k=k+1)begin host_tx=v[k];bits(1);end host_tx=1;bits(20);end endtask
 task discard;input integer n;integer j;begin for(j=0;j<n;j=j+1)begin @(negedge board_tx);bits(10);end end endtask
 task recv;integer j;begin for(j=0;j<16;j=j+1)begin @(negedge board_tx);bits(1);for(i=0;i<8;i=i+1)begin bits(1);got[j][i]=board_tx;end end end endtask
 initial begin
  $readmemh("os/uart_line_monitor.hex",dut.u_if_stage.u_instr_mem.mem);repeat(3)@(posedge clk);rst_n=1; force dut.mcycle=32'hD1234567; discard(9);
  fork begin send("s");send("t");send("a");send("t");send("u");send("s");send(8'h0d);end begin recv();end join
  if({got[8],got[9],got[10],got[11],got[12],got[13],got[14],got[15]}!=="D1234567") begin $display("KNOWN_COUNTER_FAIL got=%h%h%h%h%h%h%h%h",got[8],got[9],got[10],got[11],got[12],got[13],got[14],got[15]);errors=errors+1;end
  if(errors==0)$display("KNOWN_COUNTER_PASS MC=D1234567 through UART monitor");$finish;
 end
endmodule
