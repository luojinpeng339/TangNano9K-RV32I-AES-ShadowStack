module shadow_stack_control (
    input  wire [6:0]  opcode,
    input  wire [4:0]  rd,
    input  wire [4:0]  rs1,
    input  wire [31:0] imm,
    input  wire [31:0] pc_e,
    input  wire [31:0] forwarded_rs1,

    input  wire [31:0] top_ra,
    input  wire shadow_empty,
    input  wire        shadow_overflow_fault,
    input  wire shadow_underflow_fault,

    output wire is_call,
    output wire        is_return,

    output wire        push_en,
    output wire [31:0] push_ra,
    output wire        pop_en,

    output wire [31:0] return_target,
    output wire        cfi_check,
    output wire        cfi_match,
    output wire        mismatch_fault,
    output wire return_underflow_fault,
    output wire        security_fault
);

    // TODO 1:
    // JAL + rd!=0 -> is_call
    assign is_call = (opcode == 7'b1101111) && (rd != 5'b0);

    // TODO 2:
    // JALR x0,0(x1) -> is_return
    assign is_return = (opcode == 7'b1100111) &&
                       (rd == 5'b0) && 
                       (rs1 == 5'b1) &&
                       (imm == 32'b0);
    // TODO 3:
    // return_target = forwarded_rs1 + imm
    assign return_target = forwarded_rs1 + imm;
    // TODO 4:
    // cfi_check = is_return
    assign cfi_check = is_return;
    // TODO 5:
    // cfi_match = is_return && !shadow_empty &&
    //              (return_target == top_ra)
    assign cfi_match = is_return &&
                !shadow_empty &&
                (return_target == top_ra);
    // TODO 6:
    // mismatch_fault = is_return && !shadow_empty &&
    //                   (return_target != top_ra)
    assign mismatch_fault = is_return &&
                            !shadow_empty &&
                            (return_target != top_ra);
    // TODO 7:
    // push_en = is_call
    // push_ra = pc_e + 4
    // pop_en = cfi_match
    assign push_en = is_call;
    assign push_ra = pc_e + 32'd4;
    assign pop_en = cfi_match;
    assign return_underflow_fault =is_return &&shadow_empty;
    // TODO 8:
    // security_fault =
    //     shadow_overflow_fault ||
    //     shadow_underflow_fault ||
    //     mismatch_fault
    assign security_fault = shadow_overflow_fault ||
                            shadow_underflow_fault ||
                            return_underflow_fault ||
                            mismatch_fault;
endmodule