`timescale 1ns/1ps
module tb_bios_text_renderer;
 reg[8:0]x; reg[7:0]y; reg h=0; reg[31:0]mc=32'h1234ABCD,mi=0,ar=0,so=0,cc=0,cv=0; reg[5:0]sd=6'h2a; wire[15:0]pixel; integer errors=0;
 bios_text_renderer dut(.x(x),.y(y),.security_halted(h),.mcycle(mc),.minstret(mi),.aes_retired_count(ar),.shadow_ops(so),.cfi_checks(cc),.cfi_violations(cv),.shadow_depth(sd),.pixel_out(pixel));
 task check; input[8:0]xx;input[7:0]yy;input[15:0]want; begin x=xx;y=yy;#1;if(pixel!==want)begin $display("DASH_FAIL x=%0d y=%0d got=%h want=%h",xx,yy,pixel,want);errors=errors+1;end end endtask
 initial begin
  // title S, HALT=0 green, MC first hex digit '1', then HALT=1 red.
  check(9'd18,8'd16,16'h07ff); check(9'd58,8'd48,16'h07e0); check(9'd51,8'd80,16'h07e0);
  h=1;check(9'd59,8'd48,16'hf800);
  if(errors==0)$display("DASHBOARD_RENDERER_PASS live_status_palette");else $display("DASHBOARD_RENDERER_FAIL errors=%0d",errors);$finish;
 end
endmodule
