module tb_rob;
    timeunit 1ns;
    timeprecision 1ps;

    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg alloc_valid = 1'b0;
    reg [31:0] alloc_pc = 32'b0;
    reg [4:0] alloc_rd = 5'b0;
    wire alloc_ready;
    wire [2:0] alloc_tag;
    reg wb_valid = 1'b0;
    reg [2:0] wb_tag = 3'b0;
    reg [31:0] wb_result = 32'b0;
    reg commit_ready = 1'b0;
    wire commit_valid;
    wire [2:0] commit_tag;
    wire [31:0] commit_pc;
    wire [4:0] commit_rd;
    wire [31:0] commit_result;

    integer index;
    string vcd_path;

    always #5 clk = ~clk;

    rob dut (
        .clk(clk), .rst_n(rst_n),
        .alloc_valid(alloc_valid), .alloc_ready(alloc_ready),
        .alloc_pc(alloc_pc), .alloc_rd(alloc_rd), .alloc_crypto(1'b0), .alloc_tag(alloc_tag),
        .wb_valid(wb_valid), .wb_tag(wb_tag), .wb_result(wb_result),
        .commit_valid(commit_valid), .commit_ready(commit_ready),
        .commit_tag(commit_tag), .commit_pc(commit_pc),
        .commit_rd(commit_rd), .commit_result(commit_result), .commit_crypto()
    );

    task tick;
        begin
            @(posedge clk);
            #1;
        end
    endtask

    task reset_rob;
        begin
            rst_n = 1'b0;
            tick;
            rst_n = 1'b1;
            #1;
            if (alloc_ready !== 1'b1 || commit_valid !== 1'b0)
                $fatal(1, "Reset must leave an empty ROB ready for allocation");
        end
    endtask

    task allocate;
        input [2:0] expected_tag;
        input [31:0] pc;
        input [4:0] rd;
        begin
            alloc_valid = 1'b1;
            alloc_pc = pc;
            alloc_rd = rd;
            #1;
            if (alloc_ready !== 1'b1 || alloc_tag !== expected_tag)
                $fatal(1, "Allocation expected tag %0d, got tag %0d ready=%b",
                    expected_tag, alloc_tag, alloc_ready);
            tick;
            alloc_valid = 1'b0;
        end
    endtask

    task complete;
        input [2:0] tag;
        input [31:0] result;
        begin
            wb_valid = 1'b1;
            wb_tag = tag;
            wb_result = result;
            tick;
            wb_valid = 1'b0;
            $display("WB tag=%0d result=%0d commit_valid=%b", tag, result, commit_valid);
        end
    endtask

    task expect_commit;
        input [2:0] tag;
        input [31:0] pc;
        input [4:0] rd;
        input [31:0] result;
        begin
            if (commit_valid !== 1'b1 || commit_tag !== tag || commit_pc !== pc
                || commit_rd !== rd || commit_result !== result)
                $fatal(1, "Expected commit tag=%0d pc=%h rd=x%0d result=%0d; got valid=%b tag=%0d pc=%h rd=x%0d result=%0d",
                    tag, pc, rd, result, commit_valid, commit_tag, commit_pc, commit_rd, commit_result);
        end
    endtask

    task retire;
        input [2:0] tag;
        input [31:0] pc;
        input [4:0] rd;
        input [31:0] result;
        begin
            expect_commit(tag, pc, rd, result);
            commit_ready = 1'b1;
            tick;
            commit_ready = 1'b0;
            $display("COMMIT tag=%0d pc=%h rd=x%0d result=%0d", tag, pc, rd, result);
        end
    endtask

    initial begin
        if ($value$plusargs("vcd=%s", vcd_path)) begin
            $dumpfile(vcd_path);
            $dumpvars(0, tb_rob);
        end

        reset_rob;
        $display("Case 1: younger instruction finishes first");
        allocate(3'd0, 32'h100, 5'd5);
        allocate(3'd1, 32'h104, 5'd8);

        commit_ready = 1'b1;
        complete(3'd1, 32'd42);
        if (commit_valid !== 1'b0)
            $fatal(1, "Younger writeback must not bypass the unfinished head");
        tick;
        if (commit_valid !== 1'b0)
            $fatal(1, "Head must remain blocked until its own writeback");

        commit_ready = 1'b0;
        complete(3'd0, 32'd17);
        expect_commit(3'd0, 32'h100, 5'd5, 32'd17);
        tick;
        expect_commit(3'd0, 32'h100, 5'd5, 32'd17);
        retire(3'd0, 32'h100, 5'd5, 32'd17);
        retire(3'd1, 32'h104, 5'd8, 32'd42);
        if (commit_valid !== 1'b0)
            $fatal(1, "Drained ROB must not commit another instruction");

        reset_rob;
        $display("Case 2: full ROB retires and reuses a slot on the same edge");
        for (index = 0; index < 8; index = index + 1)
            allocate(index[2:0], 32'h200 + 4 * index, 5'd3);
        if (alloc_ready !== 1'b0)
            $fatal(1, "Full ROB accepted a ninth instruction");

        complete(3'd0, 32'd100);
        if (alloc_ready !== 1'b0)
            $fatal(1, "A blocked commit must not free an allocation slot");
        commit_ready = 1'b1;
        expect_commit(3'd0, 32'h200, 5'd3, 32'd100);
        allocate(3'd0, 32'h220, 5'd9);
        commit_ready = 1'b0;
        #1;
        if (alloc_ready !== 1'b0 || commit_valid !== 1'b0)
            $fatal(1, "Simultaneous reuse must keep the ROB full without skipping tag 1");

        for (index = 1; index < 8; index = index + 1) begin
            complete(index[2:0], 32'd100 + index);
            retire(index[2:0], 32'h200 + 4 * index, 5'd3, 32'd100 + index);
        end
        if (commit_valid !== 1'b0)
            $fatal(1, "Reused slot must wait for its new result");
        complete(3'd0, 32'd108);
        retire(3'd0, 32'h220, 5'd9, 32'd108);
        if (commit_valid !== 1'b0 || alloc_ready !== 1'b1)
            $fatal(1, "ROB must return to empty after tag wraparound");

        $display("TB_ROB_PASS");
        $finish;
    end
endmodule