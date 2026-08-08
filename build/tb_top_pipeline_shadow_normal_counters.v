`timescale 1ns/1ps
// Verification-only normal nested-call regression.
// main -> f1 -> f2 -> f1 -> main, using canonical ret at both returns.
module tb_top_pipeline_shadow_normal_counters;
 reg clk=0, rst_n=0;
 wire uart_tx,rgb_pclk,rgb_hsync,rgb_vsync,rgb_de,lcd_reset_n,lcd_disp;
 wire [4:0] rgb_r,rgb_b; wire [5:0] rgb_g;
 integer errors;
 top_pipeline dut(.clk(clk),.rst_n(rst_n),.uart_tx(uart_tx),.rgb_pclk(rgb_pclk),
  .rgb_hsync(rgb_hsync),.rgb_vsync(rgb_vsync),.rgb_de(rgb_de),.lcd_reset_n(lcd_reset_n),
  .lcd_disp(lcd_disp),.rgb_r(rgb_r),.rgb_g(rgb_g),.rgb_b(rgb_b));
 always #5 clk=~clk;

 function [31:0] it;
  input[6:0]op; input[4:0]rd,rs1; input[2:0]f3; input integer im;
  begin it={im[11:0],rs1,f3,rd,op}; end
 endfunction
 function [31:0] jal;
  input[4:0]rd; input integer off; reg[20:0]x;
  begin x=off; jal={x[20],x[10:1],x[11],x[19:12],rd,7'b1101111}; end
 endfunction
 task ck;
  input condition; input[8*72-1:0]label;
  begin if(!condition)begin $display("SHADOW_NORMAL_FAIL %0s",label);errors=errors+1;end end
 endtask

 initial begin
  errors=0;
  // 0:  jal x1,16       main -> f1, push 0x04
  // 4:  addi x10,x0,42  executes after f1 returns
  // 8:  jal x0,0        terminal loop
  // 16: addi x5,x1,0    f1 preserves caller RA=0x04 in x5
  // 20: jal x1,16       f1 -> f2, push 0x18
  // 24: addi x1,x5,0    f1 restores caller RA
  // 28: ret             pop / return to 0x04
  // 36: addi x6,x0,7    f2 body
  // 40: ret             pop / return to 0x18
  #1;
  dut.u_if_stage.u_icache.u_mem.mem[0]=jal(5'd1,16);
  dut.u_if_stage.u_icache.u_mem.mem[1]=it(7'b0010011,5'd10,5'd0,3'b000,42);
  dut.u_if_stage.u_icache.u_mem.mem[2]=32'h0000006f;
  dut.u_if_stage.u_icache.u_mem.mem[4]=it(7'b0010011,5'd5,5'd1,3'b000,0);
  dut.u_if_stage.u_icache.u_mem.mem[5]=jal(5'd1,16);
  dut.u_if_stage.u_icache.u_mem.mem[6]=it(7'b0010011,5'd1,5'd5,3'b000,0);
  dut.u_if_stage.u_icache.u_mem.mem[7]=it(7'b1100111,5'd0,5'd1,3'b000,0);
  dut.u_if_stage.u_icache.u_mem.mem[9]=it(7'b0010011,5'd6,5'd0,3'b000,7);
  dut.u_if_stage.u_icache.u_mem.mem[10]=it(7'b1100111,5'd0,5'd1,3'b000,0);
  // Prewarm all used icache lines to isolate the inherited synchronous-ROM
  // cold-fill behavior from the control-flow experiment.
  repeat(3) @(posedge clk);
  dut.u_if_stage.u_icache.cache_data[0]=dut.u_if_stage.u_icache.u_mem.mem[0];
  dut.u_if_stage.u_icache.cache_data[1]=dut.u_if_stage.u_icache.u_mem.mem[1];
  dut.u_if_stage.u_icache.cache_data[2]=dut.u_if_stage.u_icache.u_mem.mem[2];
  dut.u_if_stage.u_icache.cache_data[4]=dut.u_if_stage.u_icache.u_mem.mem[4];
  dut.u_if_stage.u_icache.cache_data[5]=dut.u_if_stage.u_icache.u_mem.mem[5];
  dut.u_if_stage.u_icache.cache_data[6]=dut.u_if_stage.u_icache.u_mem.mem[6];
  dut.u_if_stage.u_icache.cache_data[7]=dut.u_if_stage.u_icache.u_mem.mem[7];
  dut.u_if_stage.u_icache.cache_data[9]=dut.u_if_stage.u_icache.u_mem.mem[9];
  dut.u_if_stage.u_icache.cache_data[10]=dut.u_if_stage.u_icache.u_mem.mem[10];
  dut.u_if_stage.u_icache.cache_tag[0]=0; dut.u_if_stage.u_icache.cache_tag[1]=0;
  dut.u_if_stage.u_icache.cache_tag[2]=0; dut.u_if_stage.u_icache.cache_tag[4]=0;
  dut.u_if_stage.u_icache.cache_tag[5]=0; dut.u_if_stage.u_icache.cache_tag[6]=0;
  dut.u_if_stage.u_icache.cache_tag[7]=0; dut.u_if_stage.u_icache.cache_tag[9]=0;
  dut.u_if_stage.u_icache.cache_tag[10]=0;
  dut.u_if_stage.u_icache.cache_valid[0]=1; dut.u_if_stage.u_icache.cache_valid[1]=1;
  dut.u_if_stage.u_icache.cache_valid[2]=1; dut.u_if_stage.u_icache.cache_valid[4]=1;
  dut.u_if_stage.u_icache.cache_valid[5]=1; dut.u_if_stage.u_icache.cache_valid[6]=1;
  dut.u_if_stage.u_icache.cache_valid[7]=1; dut.u_if_stage.u_icache.cache_valid[9]=1;
  dut.u_if_stage.u_icache.cache_valid[10]=1;
  rst_n=1;
  repeat(80) @(posedge clk);
  ck(!dut.security_halted,"normal nested returns must not halt");
  ck(dut.u_id_stage.u_register_file.regs[5]===32'h4,"f1 preserved main return address");
  ck(dut.u_id_stage.u_register_file.regs[6]===32'd7,"f2 body executed");
  ck(dut.u_id_stage.u_register_file.regs[10]===32'd42,"main resumed after nested returns");
  ck(dut.u_shadow_stack_mem.ssp==0,"two matched returns leave stack empty");
  ck(dut.shadow_push_pop_count==32'd4,"two pushes plus two pops");
  ck(dut.cfi_check_count==32'd2,"two canonical return checks");
  ck(dut.cfi_violation_count==32'd0,"no CFI violation in normal path");
  ck(dut.mcycle!=0 && dut.minstret!=0,"core counters advance");
  if(errors==0)
   $display("TOP_PIPELINE_SHADOW_NORMAL_COUNTERS_PASS cycles=%0d instret=%0d ssops=%0d cfi_checks=%0d cfi_violations=%0d",dut.mcycle,dut.minstret,dut.shadow_push_pop_count,dut.cfi_check_count,dut.cfi_violation_count);
  else $display("TOP_PIPELINE_SHADOW_NORMAL_COUNTERS_FAIL errors=%0d",errors);
  $finish;
 end
endmodule
