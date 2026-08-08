`timescale 1ns/1ps
// Captures UART bytes at the transmitter's own byte-completion boundary.
module tb_uart_status_reporter;
 reg clk=0,rst_n=0; wire tx,done; integer errors=0; integer n=0;
 reg [8*100-1:0] text;
 uart_status_reporter #(.CLK_PER_BIT(4),.WAIT_CYCLES(3)) dut(
  .clk(clk),.rst_n(rst_n),.uart_tx(tx),.report_done(done),.security_halted(1'b1),
  .mcycle(32'h0000000a),.minstret(32'h0000000b),.aes_retired_count(32'h0000000c),
  .shadow_push_pop_count(32'h0000000d),.cfi_check_count(32'h0000000e),.cfi_violation_count(32'h0000000f));
 always #5 clk=~clk;
 always @(posedge clk) begin
  if (rst_n && dut.tx_state==2'd3 && dut.baud_count==3) begin
   case(n)
    0: if(dut.tx_byte!=="S") errors=errors+1;
    1: if(dut.tx_byte!=="E") errors=errors+1;
    2: if(dut.tx_byte!=="C") errors=errors+1;
    3: if(dut.tx_byte!=="-") errors=errors+1;
    4: if(dut.tx_byte!=="C") errors=errors+1;
    5: if(dut.tx_byte!=="P") errors=errors+1;
    6: if(dut.tx_byte!=="U") errors=errors+1;
    9: if(dut.tx_byte!=="H") errors=errors+1;
    11: if(dut.tx_byte!=="1") errors=errors+1;
    default: ;
   endcase
   n=n+1;
  end
 end
 initial begin
  repeat(2) @(posedge clk); rst_n=1;
  wait(done); @(posedge clk);
  if(errors==0 && n==92) $display("UART_STATUS_REPORTER_SMOKE_PASS bytes=%0d",n);
  else $display("UART_STATUS_REPORTER_SMOKE_FAIL bytes=%0d errors=%0d",n,errors);
  $finish;
 end
endmodule
