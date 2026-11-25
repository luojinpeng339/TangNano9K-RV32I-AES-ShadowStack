module tb_issue_queue;
    timeunit 1ns;
    timeprecision 1ps;

    localparam [2:0] ADD = 3'b000, XOR = 3'b100;
    reg clk = 0, rst_n = 0;
    reg dispatch_valid = 0, dispatch_is_load = 0;
    reg [2:0] dispatch_op = 0, dispatch_src1_tag = 0;
    reg [31:0] dispatch_src1_value = 0, dispatch_src2_value = 0;
    reg dispatch_src1_ready = 0;
    wire iq_ready, rob_ready;
    wire [2:0] dispatch_tag;

    reg wb_valid = 0;
    reg [2:0] wb_tag = 0;
    reg [31:0] wb_result = 0;
    reg alu_available = 0, load_available = 0;
    wire alu_issue_valid, load_issue_valid;
    wire [2:0] alu_issue_tag, alu_issue_op, load_issue_tag;
    wire [31:0] alu_src1, alu_src2, load_base, load_offset, alu_result;

    reg commit_ready = 0;
    wire commit_valid;
    wire [2:0] commit_tag;
    wire [31:0] commit_result;
    string vcd_path;

    always #5 clk = ~clk;

    // Both queues must accept a dispatched instruction at the same edge.
    issue_queue dut (
        .clk(clk), .rst_n(rst_n),
        .dispatch_valid(dispatch_valid && rob_ready), .dispatch_ready(iq_ready),
        .dispatch_tag(dispatch_tag), .dispatch_is_load(dispatch_is_load), .dispatch_op(dispatch_op),
        .dispatch_src1_ready(dispatch_src1_ready), .dispatch_src1_tag(dispatch_src1_tag),
        .dispatch_src1_value(dispatch_src1_value),
        .dispatch_src2_ready(1'b1), .dispatch_src2_tag(3'd0), .dispatch_src2_value(dispatch_src2_value),
        .wb_valid(wb_valid), .wb_tag(wb_tag), .wb_result(wb_result),
        .alu_available(alu_available), .alu_issue_valid(alu_issue_valid),
        .alu_issue_tag(alu_issue_tag), .alu_issue_op(alu_issue_op),
        .alu_src1(alu_src1), .alu_src2(alu_src2),
        .load_available(load_available), .load_issue_valid(load_issue_valid),
        .load_issue_tag(load_issue_tag), .load_base(load_base), .load_offset(load_offset)
    );

    alu u_alu (
        .srca(alu_src1), .srcb(alu_src2), .alu_control(alu_issue_op),
        .aluresult(alu_result), .zero()
    );

    rob u_rob (
        .clk(clk), .rst_n(rst_n),
        .alloc_valid(dispatch_valid && iq_ready), .alloc_ready(rob_ready),
        .alloc_tag(dispatch_tag), .alloc_pc(32'd0), .alloc_rd(5'd0), .alloc_crypto(1'b0),
        .wb_valid(wb_valid), .wb_tag(wb_tag), .wb_result(wb_result),
        .commit_valid(commit_valid), .commit_ready(commit_ready),
        .commit_tag(commit_tag), .commit_result(commit_result),
        .commit_pc(), .commit_rd(), .commit_crypto()
    );

    task automatic tick;
        @(posedge clk);
        #1;
    endtask

    task automatic reset_queues;
        rst_n = 0;
        alu_available = 0;
        load_available = 0;
        tick;
        rst_n = 1;
    endtask

    task automatic enqueue(
        input [2:0] tag, input is_load, input [2:0] op,
        input src1_ready, input [2:0] source_tag,
        input [31:0] src1_value, input [31:0] src2_value
    );
        dispatch_valid = 1;
        dispatch_is_load = is_load;
        dispatch_op = op;
        dispatch_src1_ready = src1_ready;
        dispatch_src1_tag = source_tag;
        dispatch_src1_value = src1_value;
        dispatch_src2_value = src2_value;
        #1;
        if ({iq_ready, rob_ready, dispatch_tag} !== {2'b11, tag})
            $fatal(1, "Dispatch tag %0d failed: IQ ready=%b ROB ready=%b offered tag=%0d",
                tag, iq_ready, rob_ready, dispatch_tag);
        tick;
        dispatch_valid = 0;
    endtask

    task automatic broadcast(input [2:0] tag, input [31:0] value);
        wb_valid = 1;
        wb_tag = tag;
        wb_result = value;
        $display("CDB tag=%0d result=%0d", tag, value);
        tick;
        wb_valid = 0;
    endtask

    task automatic retire(input [2:0] tag, input [31:0] value);
        if ({commit_valid, commit_tag, commit_result} !== {1'b1, tag, value})
            $fatal(1, "Expected commit tag=%0d result=%0d, got valid=%b tag=%0d result=%0d",
                tag, value, commit_valid, commit_tag, commit_result);
        $display("COMMIT tag=%0d result=%0d", commit_tag, commit_result);
        commit_ready = 1;
        tick;
        commit_ready = 0;
    endtask

    initial begin
        if ($value$plusargs("vcd=%s", vcd_path)) begin
            $dumpfile(vcd_path);
            $dumpvars(0, tb_issue_queue);
        end

        reset_queues;
        enqueue(0, 1, ADD, 1, 0, 'h100, 0); // I0 lw at address 0x100
        enqueue(1, 0, ADD, 0, 0, 0, 3);     // I1 add waits for I0, then adds 3
        enqueue(2, 0, XOR, 1, 0, 6, 3);     // I2 xor 6,3

        alu_available = 1;
        load_available = 1;
        #1;
        if ({load_issue_valid, load_issue_tag, alu_issue_valid, alu_issue_tag} !==
            {1'b1, 3'd0, 1'b1, 3'd2})
            $fatal(1, "Expected simultaneous issue of I0 load and I2 ALU, with I1 waiting");
        if (load_base + load_offset !== 32'h100 || alu_result !== 32'd5)
            $fatal(1, "Wrong operand sent to either execution lane");
        $display("DUAL ISSUE load=I%0d alu=I%0d; I1 waits", load_issue_tag, alu_issue_tag);
        // The real ALU's XOR result writes back at this edge. The bench
        // returns the load value later to model a slower memory operation.
        broadcast(alu_issue_tag, alu_result);
        if (commit_valid !== 0 || alu_issue_valid !== 0 || load_issue_valid !== 0)
            $fatal(1, "The older dependency must still block I1 and ROB retirement");

        broadcast(0, 12);
        if ({alu_issue_valid, alu_issue_tag} !== {1'b1, 3'd1} || alu_result !== 32'd15)
            $fatal(1, "I1 must wake on tag 0 and calculate 12 + 3");
        $display("WAKE AND ISSUE I%0d src1=%0d result=%0d", alu_issue_tag, alu_src1, alu_result);
        broadcast(alu_issue_tag, alu_result);
        retire(0, 12);
        retire(1, 15);
        retire(2, 5);
        if (commit_valid !== 0)
            $fatal(1, "ROB did not drain after three retirements");

        reset_queues;
        enqueue(0, 0, ADD, 1, 0, 10, 2);     // Issue producer I0, delay its result.
        alu_available = 1;
        #1;
        if ({alu_issue_valid, alu_issue_tag} !== {1'b1, 3'd0})
            $fatal(1, "Expected I0 producer to issue");
        tick;
        alu_available = 0;

        enqueue(1, 1, ADD, 0, 0, 0, 0);     // Older blocked load.
        enqueue(2, 1, ADD, 1, 0, 'h200, 0);  // Younger ready load.
        enqueue(3, 0, ADD, 1, 0, 1, 1);
        enqueue(4, 0, ADD, 1, 0, 2, 2);
        load_available = 1;
        #1;
        if ({load_issue_valid, iq_ready} !== 2'b00)
            $fatal(1, "Full queue must hold younger loads behind its older load");

        // Accept I5 into the full queue as I3 leaves, on the same edge
        // as the broadcast I5 needs. I5 must capture that result.
        alu_available = 1;
        wb_valid = 1;
        wb_tag = 0;
        wb_result = 12;
        enqueue(5, 0, ADD, 0, 0, 0, 1);
        wb_valid = 0;
        if ({load_issue_valid, load_issue_tag, alu_issue_valid, alu_issue_tag} !==
            {1'b1, 3'd1, 1'b1, 3'd4})
            $fatal(1, "Oldest eligible load and ALU entry must issue after compaction");
        tick;
        if ({load_issue_valid, load_issue_tag, alu_issue_valid, alu_issue_tag} !==
            {1'b1, 3'd2, 1'b1, 3'd5} || alu_result !== 32'd13)
            $fatal(1, "The dispatching entry missed the same-cycle wakeup");

        $display("TB_ISSUE_QUEUE_PASS");
        $finish;
    end
endmodule