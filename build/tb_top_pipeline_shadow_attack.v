`timescale 1ns/1ps
// CPU-level protected-return attack regression. A JAL pushes PC+4; function
// overwrites ordinary x1 with attacker target 0x20, then executes canonical ret.
// Shadow top remains original 0x04, so EX must fault and suppress pcsrc_e.
module tb_top_pipeline_shadow_attack;
 reg clk=0,rst_n=0; wire uart_tx,rgb_pclk,rgb_hsync,rgb_vsync,rgb_de,lcd_reset_n,lcd_disp; wire[4:0]rgb_r,rgb_b;wire[5:0]rgb_g; integer errors; reg saw_fault,saw_block;
 top_pipeline dut(.clk(clk),.rst_n(rst_n),.uart_tx(uart_tx),.rgb_pclk(rgb_pclk),.rgb_hsync(rgb_hsync),.rgb_vsync(rgb_vsync),.rgb_de(rgb_de),.lcd_reset_n(lcd_reset_n),.lcd_disp(lcd_disp),.rgb_r(rgb_r),.rgb_g(rgb_g),.rgb_b(rgb_b));
 always #5 clk=~clk;
 function [31:0] it; input[6:0]op;input[4:0]rd,rs1;input[2:0]f3;input integer im; begin it={im[11:0],rs1,f3,rd,op};end endfunction
 function [31:0] jal; input[4:0]rd;input integer off;reg[20:0]x;begin x=off;jal={x[20],x[10:1],x[11],x[19:12],rd,7'b1101111};end endfunction
 always @(posedge clk) if(rst_n && dut.security_fault_e) begin saw_fault=1; if(!dut.pcsrc_e) saw_block=1; end
 task ck;input condition;input[8*64-1:0]label;begin if(!condition)begin $display("SHADOW_ATTACK_FAIL %0s",label);errors=errors+1;end end endtask
 initial begin
  errors=0;saw_fault=0;saw_block=0;
  // Cache pre-warm isolates inherited synchronous ROM cold-fill behavior.
  dut.u_if_stage.u_icache.u_mem.mem[0]=jal(5'd1,16); // pc0 -> pc16; pushes RA=4
  dut.u_if_stage.u_icache.u_mem.mem[1]=32'h0000006f; // legitimate return destination loops
  dut.u_if_stage.u_icache.u_mem.mem[4]=it(7'b0010011,5'd1,5'd0,3'b000,64); // attacker overwrite ra=x1=0x40
  dut.u_if_stage.u_icache.u_mem.mem[5]=it(7'b1100111,5'd0,5'd1,3'b000,0);  // ret
  dut.u_if_stage.u_icache.u_mem.mem[6]=it(7'b0010011,5'd11,5'd0,3'b000,77); // sequential younger instruction must be squashed
  dut.u_if_stage.u_icache.u_mem.mem[7]=32'h0000006f;                        // safe loop
  dut.u_if_stage.u_icache.u_mem.mem[16]=it(7'b0010011,5'd10,5'd0,3'b000,99); // attacker target @0x40 must not execute
  repeat(3)@(posedge clk);
  dut.u_if_stage.u_icache.cache_data[0]=dut.u_if_stage.u_icache.u_mem.mem[0];dut.u_if_stage.u_icache.cache_data[1]=dut.u_if_stage.u_icache.u_mem.mem[1];dut.u_if_stage.u_icache.cache_data[4]=dut.u_if_stage.u_icache.u_mem.mem[4];dut.u_if_stage.u_icache.cache_data[5]=dut.u_if_stage.u_icache.u_mem.mem[5];dut.u_if_stage.u_icache.cache_data[6]=dut.u_if_stage.u_icache.u_mem.mem[6];dut.u_if_stage.u_icache.cache_data[7]=dut.u_if_stage.u_icache.u_mem.mem[7];dut.u_if_stage.u_icache.cache_data[16]=dut.u_if_stage.u_icache.u_mem.mem[16];
  dut.u_if_stage.u_icache.cache_tag[0]=0;dut.u_if_stage.u_icache.cache_tag[1]=0;dut.u_if_stage.u_icache.cache_tag[4]=0;dut.u_if_stage.u_icache.cache_tag[5]=0;dut.u_if_stage.u_icache.cache_tag[6]=0;dut.u_if_stage.u_icache.cache_tag[7]=0;dut.u_if_stage.u_icache.cache_tag[16]=0;
  dut.u_if_stage.u_icache.cache_valid[0]=1;dut.u_if_stage.u_icache.cache_valid[1]=1;dut.u_if_stage.u_icache.cache_valid[4]=1;dut.u_if_stage.u_icache.cache_valid[5]=1;dut.u_if_stage.u_icache.cache_valid[6]=1;dut.u_if_stage.u_icache.cache_valid[7]=1;dut.u_if_stage.u_icache.cache_valid[16]=1;
  rst_n=1;repeat(60)@(posedge clk);
  ck(saw_fault,"return mismatch observed"); ck(saw_block,"fault suppresses pcsrc_e");
  ck(dut.security_halted,"security_halted sticky set");
  if(dut.u_id_stage.u_register_file.regs[11] === 32'd77) begin $display("SHADOW_ATTACK_FAIL younger sequential instruction retired x11=77"); errors=errors+1; end
  if(dut.u_id_stage.u_register_file.regs[10] === 32'd99) begin $display("SHADOW_ATTACK_FAIL attacker target executed x10=99"); errors=errors+1; end
  ck(dut.u_shadow_stack_mem.ssp==1,"mismatch did not pop protected stack");
  // Counter contract for this attack: one JAL push, one canonical return
  // check, and exactly one return-address violation. minstrets/cycles include
  // the subsequent halted observation window and are only required nonzero.
  ck(dut.shadow_push_pop_count==32'd1,"counter: exactly one successful shadow push");
  ck(dut.cfi_check_count==32'd1,"counter: exactly one canonical return check");
  ck(dut.cfi_violation_count==32'd1,"counter: exactly one return violation");
  ck(dut.mcycle!=32'd0,"counter: mcycle advances");
  ck(dut.minstret!=32'd0,"counter: minstret advances");
  if(errors==0)$display("TOP_PIPELINE_SHADOW_ATTACK_BLOCK_PASS x1=%08h top=%08h cycles=%0d instret=%0d ssops=%0d cfi_checks=%0d cfi_violations=%0d",dut.u_id_stage.u_register_file.regs[1],dut.shadow_top_ra,dut.mcycle,dut.minstret,dut.shadow_push_pop_count,dut.cfi_check_count,dut.cfi_violation_count);else $display("TOP_PIPELINE_SHADOW_ATTACK_BLOCK_FAIL errors=%0d",errors);
  $finish;
 end
endmodule
