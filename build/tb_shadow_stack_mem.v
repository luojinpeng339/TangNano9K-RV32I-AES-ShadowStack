`timescale 1ns/1ps
module tb_shadow_stack_mem;
    localparam DEPTH = 4;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg push_en, pop_en;
    reg [31:0] push_ra;
    wire [31:0] top_ra;
    wire empty, full;
    wire push_ok, pop_ok, overflow_fault, underflow_fault;
    integer errors, i;

    shadow_stack_mem #(.DEPTH(DEPTH)) dut (
        .clk(clk), .rst_n(rst_n), .push_en(push_en), .push_ra(push_ra), .pop_en(pop_en),
        .top_ra(top_ra), .empty(empty), .full(full), .push_ok(push_ok), .pop_ok(pop_ok),
        .overflow_fault(overflow_fault), .underflow_fault(underflow_fault)
    );
    always #5 clk = ~clk;

    task check_state;
        input condition;
        input [8*96-1:0] label;
        begin
            if (!condition) begin
                $display("SHADOW_STACK_FAIL: %0s t=%0t top=%08h empty=%b full=%b push_ok=%b pop_ok=%b ovf=%b udf=%b ssp=%0d",
                    label, $time, top_ra, empty, full, push_ok, pop_ok, overflow_fault, underflow_fault, dut.ssp);
                errors = errors + 1;
            end
        end
    endtask

    task push;
        input [31:0] ra;
        begin
            push_en=1; pop_en=0; push_ra=ra; @(posedge clk); #1; push_en=0;
        end
    endtask
    task pop;
        begin
            push_en=0; pop_en=1; @(posedge clk); #1; pop_en=0;
        end
    endtask

    initial begin
        errors=0; push_en=0; pop_en=0; push_ra=0;
        repeat(2) @(posedge clk); #1;
        check_state(empty && !full && top_ra==0 && !push_ok && !pop_ok && !overflow_fault && !underflow_fault,
               "reset state");
        rst_n=1;

        push(32'h0000_0004);
        check_state(!empty && !full && top_ra==32'h0000_0004 && push_ok && !pop_ok, "push A");
        @(posedge clk); #1;
        check_state(!push_ok && !pop_ok, "push_ok pulse width");

        push(32'h0000_0020);
        check_state(top_ra==32'h0000_0020 && dut.ssp==2 && push_ok, "push B / LIFO top");
        pop;
        check_state(top_ra==32'h0000_0004 && dut.ssp==1 && pop_ok, "pop B exposes A");
        pop;
        check_state(empty && top_ra==0 && dut.ssp==0 && pop_ok, "pop A reaches empty");

        pop;
        check_state(empty && !pop_ok && underflow_fault, "empty pop underflow");
        push(32'h0000_0055);
        check_state(push_ok && top_ra==32'h55 && underflow_fault, "underflow sticky across valid push");

        // Reset clears sticky fault, then fill exactly DEPTH entries.
        rst_n=0; @(posedge clk); #1; rst_n=1;
        for(i=0;i<DEPTH;i=i+1) begin
            push(32'h1000_0000+i);
            check_state(push_ok && dut.ssp==i+1, "push through capacity");
        end
        check_state(full && top_ra==32'h1000_0003, "full after DEPTH pushes");
        push(32'hDEAD_BEEF);
        check_state(full && !push_ok && overflow_fault && top_ra==32'h1000_0003, "overflow preserves top");
        pop;
        check_state(!full && pop_ok && overflow_fault && top_ra==32'h1000_0002, "overflow sticky across valid pop");

        // Simultaneous request is deliberately no-op in v1.
        push_en=1; pop_en=1; push_ra=32'hCAFE_BABE; @(posedge clk); #1; push_en=0; pop_en=0;
        check_state(dut.ssp==3 && top_ra==32'h1000_0002 && !push_ok && !pop_ok,
               "simultaneous push/pop no-op");

        // Reset must clear both sticky faults and invalidate the stack.
        rst_n=0; @(posedge clk); #1;
        check_state(empty && top_ra==0 && !overflow_fault && !underflow_fault && !push_ok && !pop_ok,
               "reset clears faults and state");

        if(errors==0) $display("TB_SHADOW_STACK_MEM_PASS depth=%0d", DEPTH);
        else $display("TB_SHADOW_STACK_MEM_FAIL errors=%0d", errors);
        $finish;
    end
endmodule
