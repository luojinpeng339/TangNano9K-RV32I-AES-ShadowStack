module tb_top_pipeline_rob;
    timeunit 1ns;
    timeprecision 1ps;

    localparam RETIREMENTS = 12;
    reg clk = 1'b0;
    reg rst_n = 1'b0;
    reg [31:0] expected_pc [0:RETIREMENTS-1];
    reg [4:0] expected_rd [0:RETIREMENTS-1];
    reg [31:0] expected_result [0:RETIREMENTS-1];
    reg expected_crypto [0:RETIREMENTS-1];
    integer retired = 0;
    integer retired_aes = 0;
    string vcd_path;

    top_pipeline dut (.clk(clk), .rst_n(rst_n), .uart_rx(1'b1));
    always #5 clk = ~clk;

    task expect_retirement;
        input integer slot;
        input [31:0] pc;
        input [4:0] rd;
        input [31:0] result;
        input crypto;
        begin
            expected_pc[slot] = pc;
            expected_rd[slot] = rd;
            expected_result[slot] = result;
            expected_crypto[slot] = crypto;
        end
    endtask

    always @(posedge clk) begin
        if (rst_n && dut.rob_alloc_valid && !dut.rob_alloc_ready)
            $fatal(1, "The fixed pipeline exhausted its ROB");
        if (rst_n && dut.rob_commit_valid) begin
            if (retired >= RETIREMENTS)
                $fatal(1, "Unexpected retirement at PC %h", dut.rob_commit_pc);
            if (dut.rob_commit_pc !== expected_pc[retired] ||
                dut.rob_commit_tag !== retired[2:0] ||
                dut.rd_w !== expected_rd[retired] ||
                dut.reg_write_w !== (expected_rd[retired] != 5'd0) ||
                dut.rob_commit_crypto !== expected_crypto[retired])
                $fatal(1, "Retirement %0d: pc=%h tag=%0d rd=%0d write=%b crypto=%b",
                    retired, dut.rob_commit_pc, dut.rob_commit_tag, dut.rd_w,
                    dut.reg_write_w, dut.rob_commit_crypto);
            if (expected_rd[retired] != 5'd0 && dut.result_w !== expected_result[retired])
                $fatal(1, "Retirement %0d: expected result %h, got %h",
                    retired, expected_result[retired], dut.result_w);
            $display("ROB COMMIT tag=%0d pc=%h rd=%0d result=%h",
                dut.rob_commit_tag, dut.rob_commit_pc, dut.rd_w, dut.result_w);

            retired_aes = retired_aes + expected_crypto[retired];
            #1;
            if (expected_rd[retired] != 5'd0 &&
                dut.u_id_stage.u_register_file.regs[expected_rd[retired]] !== expected_result[retired])
                $fatal(1, "Retirement %0d did not update the register file", retired);
            retired = retired + 1;
            if (dut.minstret !== retired || dut.aes_retired_count !== retired_aes)
                $fatal(1, "Counters do not match the retirement stream");
        end
    end

    initial begin
        if ($value$plusargs("vcd=%s", vcd_path)) begin
            $dumpfile(vcd_path);
            $dumpvars(1, dut);
            $dumpvars(0, dut.u_rob);
        end

        expect_retirement( 0, 'h00,  5, 12, 0);
        expect_retirement( 1, 'h04,  0,  0, 0);
        expect_retirement( 2, 'h08,  4, 12, 0);
        expect_retirement( 3, 'h0c,  6, 17, 0);
        expect_retirement( 4, 'h10,  0,  0, 0);
        expect_retirement( 5, 'h18,  1, 'h1c, 0);
        expect_retirement( 6, 'h24, 10, 18, 0);
        expect_retirement( 7, 'h28,  0,  0, 0);
        expect_retirement( 8, 'h1c,  8,  9, 0);
        expect_retirement( 9, 'h20,  0,  0, 0);
        expect_retirement(10, 'h2c, 11, 'h63, 1);
        expect_retirement(11, 'h30,  0,  0, 0);

        #1;
        dut.u_if_stage.u_instr_mem.mem[0]  = 32'h00c00293; // addi x5,x0,12
        dut.u_if_stage.u_instr_mem.mem[1]  = 32'h00502023; // sw x5,0(x0)
        dut.u_if_stage.u_instr_mem.mem[2]  = 32'h00002203; // lw x4,0(x0)
        dut.u_if_stage.u_instr_mem.mem[3]  = 32'h00520313; // addi x6,x4,5
        dut.u_if_stage.u_instr_mem.mem[4]  = 32'h00630463; // beq x6,x6,+8
        dut.u_if_stage.u_instr_mem.mem[5]  = 32'h06300393; // skipped addi x7,x0,99
        dut.u_if_stage.u_instr_mem.mem[6]  = 32'h00c000ef; // jal x1,+12
        dut.u_if_stage.u_instr_mem.mem[7]  = 32'h00900413; // addi x8,x0,9
        dut.u_if_stage.u_instr_mem.mem[8]  = 32'h00c0006f; // jal x0,+12
        dut.u_if_stage.u_instr_mem.mem[9]  = 32'h00130513; // addi x10,x6,1
        dut.u_if_stage.u_instr_mem.mem[10] = 32'h00008067; // ret, matching call
        dut.u_if_stage.u_instr_mem.mem[11] = 32'h220005b3; // aes32esi x11,x0,x0,0
        dut.u_if_stage.u_instr_mem.mem[12] = 32'h00100013; // addi x0,x0,1
        dut.u_if_stage.u_instr_mem.mem[13] = 32'h00008067; // ret, now empty stack
        dut.u_if_stage.u_instr_mem.mem[14] = 32'h00802223; // younger sw x8,4(x0)
        dut.u_mem_stage.u_data_mem.mem[1] = 32'hdeadbeef;

        repeat (2) @(negedge clk);
        rst_n = 1'b1;
        repeat (80) @(negedge clk);

        if (retired != RETIREMENTS || dut.minstret !== RETIREMENTS ||
            dut.aes_retired_count !== 32'd1 || dut.rob_commit_valid !== 1'b0)
            $fatal(1, "Older instructions did not finish draining");
        if (dut.security_halted !== 1'b1 || dut.cfi_check_count !== 32'd2 ||
            dut.cfi_violation_count !== 32'd1 || dut.shadow_push_pop_count !== 32'd2)
            $fatal(1, "Unexpected shadow-stack or fail-stop behavior");
        if (dut.u_mem_stage.u_data_mem.mem[0] !== 32'd12 ||
            dut.u_mem_stage.u_data_mem.mem[1] !== 32'hdeadbeef)
            $fatal(1, "The expected store or the fault boundary was lost");

        $display("TB_TOP_PIPELINE_ROB_PASS committed=%0d aes=%0d", retired, retired_aes);
        $finish;
    end
endmodule