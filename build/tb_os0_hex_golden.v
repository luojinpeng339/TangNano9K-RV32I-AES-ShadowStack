`timescale 1ns/1ps
// Unit golden model for OS-0 print_hex32 algorithm: source register must not
// be overwritten by the ASCII byte sent to putc.
module tb_os0_hex_golden;
 reg [31:0] source; reg [31:0] shifted; reg [3:0] nibble; reg [7:0] out[0:7]; integer i,errors=0;
 function [7:0] ascii_hex; input [3:0] n; begin ascii_hex=(n<10)?(8'h30+n):(8'h41+n-10); end endfunction
 task check; input [31:0] value; input [63:0] expected; begin
  source=value; shifted=source;
  for(i=0;i<8;i=i+1)begin nibble=shifted[31:28]; shifted=shifted<<4; out[i]=ascii_hex(nibble); if(out[i]!==expected[(7-i)*8 +:8])errors=errors+1; end
 end endtask
 initial begin
  check(32'h4AE6888B,"4AE6888B");
  check(32'h16188880,"16188880");
  check(32'h00000015,"00000015");
  if(errors==0)$display("OS0_HEX_GOLDEN_PASS source_preserved_across_ascii_output");else $display("OS0_HEX_GOLDEN_FAIL errors=%0d",errors);$finish;
 end
endmodule
