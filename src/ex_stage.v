//============================================================================  
// Module          : ex_stage  
// Author          : Jinpeng Luo  
// Provenance      : Original work; header normalized 2026-08
// Design Notes    : Execution stage with extensible datapath for DIV/FPU.  
//                  Main ALU handles integer ops, aux units for DIV/FP.  
//                  Forwarding network supports multi-cycle operations.  
// DIV Integration : div_start, div_busy signals for multi-cycle division  
// FPU Integration : fpu_ready, fpu_exception signals for floating-point  
// Fault Recovery  : Exception trap address calculation (mtval generation)  
//============================================================================  
module ex_stage(  
input clk,  
input reg_write_e,  
input [1:0] result_src_e,     // RV32I result source: memory, ALU, or PC+4  
input mem_write_e,  
input jump_e,  
input branch_e,  
input [2:0] alu_control_e,    // RV32I ALU control  
input alu_src_e,  
input [31:0] addr1_e,  
input [31:0] addr2_e,  
input [31:0] pc_e_in,  
input [1:0] forward_a_e,  
input [31:0] alu_result_m,  
input [1:0] forward_b_e,  
input [31:0] imm_ext_e,  
input [31:0] result_w,  
input [4:0] rd_e,  
input [31:0] pc_plus_4_in,  
// RESERVED for DIV/FPU  
input div_start,              // Start multi-cycle division  
input fpu_start,              // Start floating-point operation  
input crypto_en_e,
input crypto_op_e,
input wire jalr_e,
input [1:0] crypto_bs_e,
input kexp1i_en_e,
input wire [4:0] kexp_rnum_e,
input  wire [6:0] opcode_e,
input  wire [4:0] rs1_index_e,

input  wire [31:0] shadow_top_ra,
input  wire        shadow_empty,
input  wire        shadow_overflow_fault,
input  wire        shadow_underflow_fault,

output wire        shadow_push_en,
output wire [31:0] shadow_push_ra,
output wire        shadow_pop_en,

output wire        security_fault_e,
output wire [31:0] pc_e_out,  
output [31:0] pc_plus_4_out,  
output [4:0] rd_e_out,  
output [31:0] aluresult_e,  
output [31:0] pc_target_e,  
output wire pcsrc_e,  
output wire [31:0] write_data_e,  
output wire zero_e,  
// RESERVED outputs for extended units  
output div_busy,              // Division in progress  
output fpu_ready,             // FPU result available  
output [31:0] div_result_e,   // Division result (quotient/remainder)  
output [31:0] fpu_result_e,   // Floating-point result  
output exception_trap,        // Exception condition detected
output wire cfi_check_e,
output wire cfi_violation_event_e
);  

wire[31: 0] src_a_e;
    assign src_a_e =  (forward_a_e == 2'b10) ? alu_result_m :   (forward_a_e == 2'b01) ? result_w :addr1_e;   
wire [31:0] pre_src_b_e;
    assign pre_src_b_e = (forward_b_e == 2'b10) ? alu_result_m :(forward_b_e == 2'b01) ? result_w :addr2_e;
wire [31:0] src_b_e;
    assign src_b_e = alu_src_e ? imm_ext_e : pre_src_b_e;
wire [31:0] alu_result_raw;
wire [31:0] aes_result;
wire [31:0] kexp1i_result;
wire [31:0] jalr_target_e;
wire [31:0] shadow_return_target;
wire is_shadow_call;
wire is_shadow_return;
wire cfi_check_internal;
wire cfi_match_e;
wire mismatch_fault_e;
wire return_underflow_fault_e;

alu #(
    .WIDTH (32)
)u_alu(
    .srca (src_a_e ),
    .srcb (src_b_e),
    .alu_control(alu_control_e),
    .aluresult(alu_result_raw),
    .zero(zero_e)
);

aes32_fu u_aes32_fu (
    .rs1(src_a_e),
    .rs2(pre_src_b_e),
    .bs(crypto_bs_e),
    .crypto_op(crypto_op_e),
    .aes_result(aes_result)
);

aes32_ks1i_fu u_kexp1i (
    .rs1   (src_a_e),
    .rnum  (kexp_rnum_e),
    .result(kexp1i_result)
);
shadow_stack_control u_shadow_control (
    .opcode                  (opcode_e),
    .rd                      (rd_e),
    .rs1                     (rs1_index_e),
    .imm                     (imm_ext_e),
    .pc_e                    (pc_e_in),
    .forwarded_rs1           (src_a_e),

    .top_ra                  (shadow_top_ra),
    .shadow_empty            (shadow_empty),
    .shadow_overflow_fault   (shadow_overflow_fault),
    .shadow_underflow_fault  (shadow_underflow_fault),

    .is_call                 (is_shadow_call),
    .is_return               (is_shadow_return),

    .push_en                 (shadow_push_en),
    .push_ra                 (shadow_push_ra),
    .pop_en                  (shadow_pop_en),

    .return_target           (shadow_return_target),
    .cfi_check               (cfi_check_internal),
    .cfi_match               (cfi_match_e),
    .mismatch_fault          (mismatch_fault_e),
    .return_underflow_fault  (return_underflow_fault_e),
    .security_fault          (security_fault_e)
);

assign aluresult_e =
        kexp1i_en_e ? kexp1i_result :
        crypto_en_e ? aes_result :
        alu_result_raw;
 assign jalr_target_e = (src_a_e + imm_ext_e) & 32'hFFFF_FFFE;
assign pc_target_e = jalr_e ? jalr_target_e : (imm_ext_e + pc_e_in);
 assign pcsrc_e = (jump_e | (branch_e & zero_e)) && !security_fault_e;
 assign write_data_e = pre_src_b_e;
 assign pc_plus_4_out = pc_plus_4_in;
 assign rd_e_out = rd_e;
 assign pc_e_out = pc_e_in;
 assign cfi_check_e = cfi_check_internal;

assign cfi_violation_event_e =
    mismatch_fault_e || return_underflow_fault_e;

endmodule


