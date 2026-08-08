//============================================================================  
// Module          : id_stage  
// Author          : ZYY_2034580440  
// Created         : 2024.03.18  
// Design Notes    : Instruction decode with RV32IMFD extension awareness.  
//                  Control unit produces extended signals for DIV/FPU.  
//                  Immediate extraction supports custom instruction formats.  
// DIV Support     : DIV, DIVU, REM, REMU opcode decoding (RESERVED)  
// FPU Support     : FADD, FSUB, FMUL, FDIV opcode decoding (RESERVED)  
// Fault Detect    : Illegal instruction trap with cause code generation 



//+-------------+--------+--------+------+--------+--------+
//31          25 24    20 19    15 14  12 11     7 6       0
//+-------------+--------+--------+------+--------+--------+
//|   funct7    |  rs2   |  rs1   |funct3|   rd   | opcode |
//+-------------+--------+--------+------+--------+--------+

//============================================================================  
module id_stage (
    input clk,
    input wire [31 : 0] instr_d,
    input  wire [4:0]  rd_w,        
    input  wire  reg_write_w, 
    input  wire [31:0] result_w,   
    input  wire [31:0] pc_d_in,
    input [31:0] pc_plus_4_i,
    output [31 : 0] pc_plus_4_d,
    output wire [31:0] pc_d_out,
    output wire [4:0] rs1_d,
    output wire [4:0] rs2_d,
    output wire [4:0] rd_d, 
    output wire [31:0] rd1_d,        
    output wire [31:0] rd2_d,        
    output wire [31:0] imm_ext_d,
    output wire  reg_write_d,
    output wire mem_read_d,
    output wire  mem_write_d,
    output wire [1:0] result_src_d,
    output wire [2:0] alu_control_d,
    output wire branch_d,
    output wire jump_d,
    output wire alu_src_d,
    output crypto_en_d,
    output crypto_op_d,
    output wire [1:0] crypto_bs_d,
    output wire [4:0] kexp_rnum_d,
    output wire kexp1i_en_d,
    output wire jalr_d,
    output wire [6:0] opcode_d
);

    wire [6:0] opcode = instr_d[6:0];
    wire [2:0]  funct3 = instr_d[14:12];
    wire [6:0]  funct7 = instr_d[31:25];
    wire [15:0] imm    = instr_d[15:0];
    //[19:15] rs1, [24:20] rs2, [11:7] rd  2026.8.5 -> 改为官方规定Zkne 的 AES 指令不是个人的 RISC-V 编码
    assign rs1_d = instr_d[19:15];
    assign rs2_d = instr_d[24:20];
    assign rd_d  = instr_d[11:7];
    assign opcode_d = opcode;
    wire [1:0]  imm_src_d;
    wire crypto_en_i;
    wire crypto_op_i;
    wire kexp1i_en_i;
    wire jalr_i;
    assign jalr_d = jalr_i;
    assign crypto_bs_d = instr_d[31:30];
    assign crypto_en_d = crypto_en_i;
    assign crypto_op_d = crypto_op_i;
    assign kexp1i_en_d = kexp1i_en_i;
    assign kexp_rnum_d = instr_d[24:20];

    register_file #(
        .WIDTH (32)
    ) u_register_file (
        .clk (clk),
        .addr2 (rs2_d),
        .addr1 (rs1_d),
        .addr3 (rd_w),
        .wdata (result_w),
        .write_en (reg_write_w),
        .rdata1 (rd1_d),
        .rdata2  (rd2_d)

    );

    control_unit u_control_unit (
        .opcode (opcode),
        .funct3 (instr_d[14:12]),
        .funct7 (instr_d[31:25]),
        .reg_write (reg_write_d),
        .mem_read (mem_read_d),
        .mem_write (mem_write_d),
        .result_src (result_src_d),
        .alu_control (alu_control_d),
        .imm_src (imm_src_d),
        .alu_src(alu_src_d),
        .branch(branch_d),
        .jump(jump_d),
        .crypto_en(crypto_en_i),
        .crypto_op(crypto_op_i),
        .kexp1i_en(kexp1i_en_i),
        .jalr(jalr_i)
    );

    extend u_extend (
        .instr (instr_d),   
        .imm_src (imm_src_d), 
        .imm_ext (imm_ext_d) 
    );
    
    assign pc_d_out = pc_d_in;
    assign pc_plus_4_d = pc_plus_4_i; 
endmodule
       
        