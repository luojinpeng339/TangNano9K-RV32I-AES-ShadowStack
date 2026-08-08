`timescale 1ns/1ps
// CPU-level JAL/JALR regression. Tests JAL link, canonical return and
// forwarding into JALR's target calculation.
module tb_top_pipeline_jalr;
    reg clk=0, rst_n=0;
    wire uart_tx, rgb_pclk, rgb_hsync, rgb_vsync, rgb_de, lcd_reset_n, lcd_disp;
    wire [4:0] rgb_r,rgb_b; wire [5:0] rgb_g;
    integer errors;
    top_pipeline dut(.clk(clk),.rst_n(rst_n),.uart_tx(uart_tx),.rgb_pclk(rgb_pclk),.rgb_hsync(rgb_hsync),.rgb_vsync(rgb_vsync),.rgb_de(rgb_de),.lcd_reset_n(lcd_reset_n),.lcd_disp(lcd_disp),.rgb_r(rgb_r),.rgb_g(rgb_g),.rgb_b(rgb_b));
    always #5 clk=~clk;
    function [31:0] i_type;
        input [6:0] opcode; input [4:0] rd,rs1; input [2:0] f3; input integer imm;
        begin i_type={imm[11:0],rs1,f3,rd,opcode}; end
    endfunction
    function [31:0] jal;
        input [4:0] rd; input integer off; reg [20:0] x;
        begin x=off; jal={x[20],x[10:1],x[11],x[19:12],rd,7'b1101111}; end
    endfunction
    task chk; input [4:0] n; input [31:0] v; begin if(dut.u_id_stage.u_register_file.regs[n]!==v)begin $display("JALR_FAIL x%0d got=%08h want=%08h",n,dut.u_id_stage.u_register_file.regs[n],v);errors=errors+1;end end endtask
    initial begin
      errors=0;
      // Populate the program RAM and pre-warm just these instruction-cache
      // lines. This isolates JAL/JALR from the inherited synchronous-ROM cold
      // fill behavior; no production RTL is altered.
      dut.u_if_stage.u_icache.u_mem.mem[0]=jal(5'd1,16);          // PC0: jal x1, PC16; x1=4
      dut.u_if_stage.u_icache.u_mem.mem[1]=i_type(7'b0010011,5'd10,5'd0,3'b000,42); // PC4 after return
      dut.u_if_stage.u_icache.u_mem.mem[2]=32'h0000006f;         // PC8 terminal loop
      dut.u_if_stage.u_icache.u_mem.mem[4]=i_type(7'b0010011,5'd5,5'd0,3'b000,7);  // PC16 function
      dut.u_if_stage.u_icache.u_mem.mem[5]=i_type(7'b1100111,5'd0,5'd1,3'b000,0);  // PC20 ret
      repeat(3) @(posedge clk);
      dut.u_if_stage.u_icache.cache_data[0]=dut.u_if_stage.u_icache.u_mem.mem[0];
      dut.u_if_stage.u_icache.cache_data[1]=dut.u_if_stage.u_icache.u_mem.mem[1];
      dut.u_if_stage.u_icache.cache_data[2]=dut.u_if_stage.u_icache.u_mem.mem[2];
      dut.u_if_stage.u_icache.cache_data[4]=dut.u_if_stage.u_icache.u_mem.mem[4];
      dut.u_if_stage.u_icache.cache_data[5]=dut.u_if_stage.u_icache.u_mem.mem[5];
      dut.u_if_stage.u_icache.cache_tag[0]=0; dut.u_if_stage.u_icache.cache_tag[1]=0;
      dut.u_if_stage.u_icache.cache_tag[2]=0; dut.u_if_stage.u_icache.cache_tag[4]=0;
      dut.u_if_stage.u_icache.cache_tag[5]=0;
      dut.u_if_stage.u_icache.cache_valid[0]=1; dut.u_if_stage.u_icache.cache_valid[1]=1;
      dut.u_if_stage.u_icache.cache_valid[2]=1; dut.u_if_stage.u_icache.cache_valid[4]=1;
      dut.u_if_stage.u_icache.cache_valid[5]=1;
      rst_n=1; repeat(65) @(posedge clk);
      chk(5'd1,32'd4); chk(5'd5,32'd7); chk(5'd10,32'd42);
      if(errors==0)$display("TOP_PIPELINE_JALR_CALL_RETURN_PASS ra=%08h x5=%0d x10=%0d",dut.u_id_stage.u_register_file.regs[1],dut.u_id_stage.u_register_file.regs[5],dut.u_id_stage.u_register_file.regs[10]); else $display("TOP_PIPELINE_JALR_CALL_RETURN_FAIL errors=%0d",errors);
      $finish;
    end
endmodule
