module hazard_unit(
    input  wire        id_ex_mem_read,
    input  wire        ex_mem_reg_write,
    input  wire [4:0]  ex_rd,
    input  wire [4:0]  mem_rd,
    input  wire [4:0]  wb_rd,
    input  wire        reg_write_w,
    input  wire        pcsrc_e,
    input  wire [4:0]  ex_rs1,
    input  wire [4:0]  ex_rs2,
    input  wire [4:0]  id_rs1,
    input  wire [4:0]  id_rs2,
    input  wire        branch_mispredicted,
    input  ex_mem_mem_read,
    output reg         stall_f,
    output reg         stall_d,
    output reg         flush_e,
    output reg         flush_d,
    output reg  [1:0]  forward_ae,
    output reg  [1:0]  forward_be
);

reg lwstall;

   
always @(*) begin
    stall_f = 0;
    stall_d = 0;
    flush_e = 0;
    flush_d = 0;
    forward_ae = 2'b00;
    forward_be = 2'b00;
    lwstall = 0;

    lwstall = (id_ex_mem_read && (ex_rd == id_rs1 || ex_rd ==id_rs2));
        stall_f = lwstall ;
        stall_d = lwstall ;
        flush_e = lwstall;
    
    // Forward A: MEM阶段结果优先，其次WB阶段
    // 修复：WB转发用reg_write_w而非ex_mem_reg_write
    forward_ae = 2'b00;
    if (ex_mem_reg_write && !ex_mem_mem_read && (mem_rd == ex_rs1) && (ex_rs1 != 5'd0))
        forward_ae = 2'b10;

    else if (reg_write_w &&  (wb_rd == ex_rs1) && (ex_rs1 != 5'd0))
        forward_ae = 2'b01;

    // Forward B: 同上逻辑
    forward_be = 2'b00;
    if (ex_mem_reg_write && !ex_mem_mem_read && (mem_rd == ex_rs2) && (ex_rs2 != 5'd0))
        forward_be = 2'b10;
    else if (reg_write_w && (wb_rd == ex_rs2) && (ex_rs2 != 5'd0))
        forward_be = 2'b01;
    if (branch_mispredicted) begin
    flush_d = 1;
    flush_e = 1;
    end
end



endmodule
