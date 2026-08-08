`timescale 1ns/1ps
module tb_shadow_stack_control;
    reg [6:0] opcode;
    reg [4:0] rd, rs1;
    reg [31:0] imm, pc_e, forwarded_rs1, top_ra;
    reg shadow_empty, shadow_overflow_fault, shadow_underflow_fault;
    wire is_call, is_return, push_en, pop_en, cfi_check, cfi_match, mismatch_fault, return_underflow_fault, security_fault;
    wire [31:0] push_ra, return_target;
    integer errors;

    shadow_stack_control dut (
        .opcode(opcode), .rd(rd), .rs1(rs1), .imm(imm), .pc_e(pc_e), .forwarded_rs1(forwarded_rs1),
        .top_ra(top_ra), .shadow_empty(shadow_empty), .shadow_overflow_fault(shadow_overflow_fault),
        .shadow_underflow_fault(shadow_underflow_fault), .is_call(is_call), .is_return(is_return),
        .push_en(push_en), .push_ra(push_ra), .pop_en(pop_en), .return_target(return_target),
        .cfi_check(cfi_check), .cfi_match(cfi_match), .mismatch_fault(mismatch_fault),
        .return_underflow_fault(return_underflow_fault), .security_fault(security_fault)
    );

    task check;
        input condition;
        input [8*88-1:0] label;
        begin
            if (!condition) begin
                $display("SHADOW_CTRL_FAIL %0s: call=%b ret=%b push=%b pop=%b target=%08h match=%b mismatch=%b fault=%b",
                    label,is_call,is_return,push_en,pop_en,return_target,cfi_match,mismatch_fault,security_fault);
                errors=errors+1;
            end
        end
    endtask

    task defaults;
        begin
            opcode=0; rd=0; rs1=0; imm=0; pc_e=0; forwarded_rs1=0; top_ra=0;
            shadow_empty=0; shadow_overflow_fault=0; shadow_underflow_fault=0; #1;
        end
    endtask

    initial begin
        errors=0;
        // A: call must push PC+4.
        defaults; opcode=7'b1101111; rd=5'd1; pc_e=32'h100; #1;
        check(is_call && push_en && push_ra==32'h104 && !is_return && !pop_en && !security_fault, "normal JAL call");
        // JAL x0 is a jump, not protected call.
        defaults; opcode=7'b1101111; rd=0; pc_e=32'h100; #1;
        check(!is_call && !push_en, "JAL x0 is not call");
        // B: canonical ret, compare must use forwarded rs1.
        defaults; opcode=7'b1100111; rd=0; rs1=1; imm=0; forwarded_rs1=32'h104; top_ra=32'h104; #1;
        check(is_return && cfi_check && return_target==32'h104 && cfi_match && pop_en && !mismatch_fault && !security_fault, "matched canonical ret");
        // Immediate is included in actual JALR target but nonzero immediate is not canonical ret in v1.
        defaults; opcode=7'b1100111; rd=0; rs1=1; imm=4; forwarded_rs1=32'h100; top_ra=32'h104; #1;
        check(!is_return && !cfi_check && !pop_en && return_target==32'h104, "noncanonical jalr ignored");
        // Another indirect JALR must remain outside first-version scope.
        defaults; opcode=7'b1100111; rd=0; rs1=5; imm=0; forwarded_rs1=32'h104; top_ra=32'h104; #1;
        check(!is_return && !cfi_check && !pop_en, "noncanonical base ignored");
        // C: tampered normal stack RA: report mismatch and do NOT pop.
        defaults; opcode=7'b1100111; rd=0; rs1=1; imm=0; forwarded_rs1=32'h180; top_ra=32'h104; #1;
        check(is_return && cfi_check && !cfi_match && mismatch_fault && security_fault && !pop_en, "tampered return blocks pop");
        // D: empty return: no bogus top comparison and no pop.
        defaults; opcode=7'b1100111; rd=0; rs1=1; imm=0; forwarded_rs1=32'h104; top_ra=0; shadow_empty=1; #1;
        check(is_return && cfi_check && !cfi_match && !mismatch_fault && return_underflow_fault && !pop_en && security_fault,
              "empty return immediate underflow fault");
        // Current memory fault input correctly propagates to security output.
        shadow_underflow_fault=1; #1;
        check(security_fault, "underflow fault propagates");
        defaults; shadow_overflow_fault=1; #1;
        check(security_fault, "overflow fault propagates");
        if(errors==0) $display("TB_SHADOW_STACK_CONTROL_LOGIC_PASS");
        else $display("TB_SHADOW_STACK_CONTROL_LOGIC_FAIL errors=%0d",errors);
        $finish;
    end
endmodule
