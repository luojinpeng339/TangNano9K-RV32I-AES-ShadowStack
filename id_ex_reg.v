module id_ex_reg(
    input clk,
    input rst_n,
    input flush_e,
    input stall_d,
    input mem_read_d,
    input ex_mem_reg_write,
    input reg_write_d,
    input [1:0] result_src_d,
    input mem_write_d,
    input jump_d,
    input [2:0] alu_control_d,
    input alu_src_d,
    input branch_d,
    input wire jalr_d,
    input [31:0] rd1_d, 
    input [31:0] rd2_d, 
    input [31:0] imm_ext_d, 
    input [31:0] pc_d, 
    input [31:0] pc_plus_4_d,
    input  wire [4:0]  rs1_d, 
    input [4:0] rs2_d, 
    input [4:0] rd_d,
    input wire      kexp1i_en_d,
    input wire [4:0] kexp_rnum_d,
    input wire crypto_en_d,
    input wire crypto_op_d,
    input wire [1:0] crypto_bs_d,
    input  wire [6:0] opcode_d,
    input  wire valid_d,
    output reg  valid_e,
    output reg  [6:0] opcode_e,
    output reg [31:0] rd1_e, 
    output reg [31:0] rd2_e, 
    output reg [31:0] imm_ext_e, 
    output reg [31:0] pc_e,
    output reg [31:0] pc_plus_4_e,
    output reg [4:0] rs1_e,
     output reg [4:0] rs2_e,
     output reg [4:0] rd_e,
      output reg reg_write_e,
      output reg mem_read_e,
    output reg  mem_write_e,
     output reg alu_src_e, 
    output reg jump_e, 
    output reg branch_e,
    output reg  [1:0]  result_src_e,
    output reg  [2:0]  alu_control_e,
    output reg       crypto_en_e,
    output reg       crypto_op_e,
    output reg [1:0] crypto_bs_e,
    output reg       kexp1i_en_e,
    output reg jalr_e,
    output reg [4:0] kexp_rnum_e
);

always @(posedge clk or negedge rst_n) begin

    if (!rst_n) begin
        rd1_e <= 32'b0;
        rd2_e <= 32'b0;
        imm_ext_e <= 32'b0;
        pc_e <= 32'b0;
        pc_plus_4_e  <= 32'b0;
        rs1_e <= 5'b0;
        rs2_e <= 5'b0;
        rd_e <= 5'b0;
        reg_write_e <= 1'b0; 
        mem_read_e <= 1'b0;
        mem_write_e <= 1'b0;
        alu_src_e <= 1'b0;
        jump_e <= 1'b0;
        branch_e <= 1'b0;
        result_src_e <= 2'b00;
        alu_control_e <= 3'b000;
        crypto_en_e <= 1'b0;
        crypto_op_e <= 1'b0;
        crypto_bs_e <= 2'b00;
        kexp1i_en_e <= 1'b0;
        kexp_rnum_e <= 5'd0;
        jalr_e <= 1'b0;
        opcode_e <= 7'b0;
        valid_e <= 1'b0;
    end

    else if (flush_e) begin
        rd1_e <= 32'b0;
        rd2_e <= 32'b0;
        imm_ext_e <= 32'b0;
        pc_e <= 32'b0;
        pc_plus_4_e  <= 32'b0;
        rs1_e <= 5'b0;
        rs2_e <= 5'b0;
        rd_e <= 5'b0;
        reg_write_e <= 1'b0; 
        mem_read_e <= 1'b0;
        mem_write_e <= 1'b0;
        alu_src_e <= 1'b0;
        jump_e <= 1'b0;
        branch_e <= 1'b0;
        result_src_e <= 2'b00;
        alu_control_e <= 3'b000;
        crypto_en_e <= 1'b0;
        crypto_op_e <= 1'b0;
        crypto_bs_e <= 2'b00;
        kexp1i_en_e <= 1'b0;
        kexp_rnum_e <= 5'd0;
        jalr_e <= 1'b0;
        opcode_e <= 7'b0;
        valid_e <= 1'b0;
    end
    else if (stall_d) begin
        
    end
    else begin
        rd1_e <= rd1_d; 
        rd2_e <= rd2_d; 
        imm_ext_e <= imm_ext_d;
        pc_e <= pc_d; 
        pc_plus_4_e <= pc_plus_4_d;
        rs1_e <= rs1_d;
        rs2_e <= rs2_d;
        rd_e <= rd_d;
        reg_write_e <= reg_write_d;
        mem_read_e <= mem_read_d;
        mem_write_e <= mem_write_d;
        alu_src_e <= alu_src_d;
        jump_e <= jump_d;
        branch_e <= branch_d;
        result_src_e <= result_src_d;
        alu_control_e <= alu_control_d;
        crypto_en_e <= crypto_en_d;
        crypto_op_e <= crypto_op_d;
        crypto_bs_e <= crypto_bs_d;
        kexp1i_en_e <= kexp1i_en_d;
        kexp_rnum_e <= kexp_rnum_d;
        jalr_e <= jalr_d;
        opcode_e <= opcode_d;
        valid_e <= valid_d;
    end
end

endmodule

