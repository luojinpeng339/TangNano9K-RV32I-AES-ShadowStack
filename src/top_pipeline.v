`timescale 1ns / 1ps

module top_pipeline(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        uart_rx,
    output wire        uart_tx,
    output wire        rgb_pclk,
    output wire        rgb_hsync,
    output wire        rgb_vsync,
    output wire        rgb_de,
    output wire        lcd_reset_n,
    output wire        lcd_disp,
    output wire [4:0]  rgb_r,
    output wire [5:0]  rgb_g,
    output wire [4:0]  rgb_b
    
);

    // ===============================================================
    // 1. 声明全局信号线 - 保持你原来的完美连线


    wire [31:0] pc_f, pc_plus_4_f, instr_f;
    wire [31:0] pc_rom_f, pc_plus_4_rom_f;
    wire        instr_valid_f;
    wire [31:0] pc_d, pc_plus_4_d, instr_d;
    wire valid_d, valid_e, valid_m, valid_w;
    wire [31:0] pc_plus_4_e, pc_plus_4_m, pc_plus_4_w;
    wire [31:0] pc_plus_4_m_out;  
    wire [31:0] pc_plus_4_ex;
    wire [31:0] pc_e_in, pctarget_e;
    wire [4:0] rd_w_out;
    wire [31:0] rd1_d, rd2_d, imm_ext_d;
    wire [31:0] rd1_e, rd2_e, imm_ext_e;
    wire [4:0]  rs1_d, rs2_d, rd_d;
    wire [4:0] rd_loop;
    wire [4:0] rd_e_out; 
    wire [4:0]  rs1_e, rs2_e, rd_e, rd_m, rd_w;
    wire [31:0] alu_result_e, alu_result_m, alu_result_w;
    wire [31:0] write_data_e, write_data_m, read_data_m,read_data_w;
    wire [31:0] result_w;
    wire        zero_e;
    wire stall_f, stall_d, flush_d, flush_e;
    wire [1:0] forward_ae, forward_be;
    wire pcsrc_e, jump_e, branch_e;
    wire jump_d, alu_src_d, branch_d;
    wire alu_src_e;
    wire crypto_en_d;
    wire crypto_op_d;
    wire jalr_d;
    wire jalr_e;
    wire [1:0] crypto_bs_d;
    wire crypto_en_e;
    wire crypto_en_m, crypto_en_w;
    wire crypto_op_e;
    wire [1:0] crypto_bs_e;
    wire zero_m;
    wire reg_write_d, mem_read_d, mem_write_d;
    wire reg_write_e, mem_read_e, mem_write_e;
    wire reg_write_m, mem_read_m, mem_write_m;
    wire reg_write_w;
    wire reg_write_loop;  
    wire [1 :0] result_src_d, result_src_e, result_src_m, result_src_w;
    wire [2:0] alu_control_d, alu_control_e;
    wire [1:0] imm_src_d;
    wire kexp1i_en_d;
    wire [4:0] kexp_rnum_d;
    wire       kexp1i_en_e;
    wire [4:0] kexp_rnum_e;
    wire        shadow_push_en;
    wire [31:0] shadow_push_ra;
    wire        shadow_pop_en;

    wire [31:0] shadow_top_ra;
    wire        shadow_empty;
    wire        shadow_full;
    wire [5:0]  shadow_depth;
    wire        shadow_push_ok;
    wire        shadow_pop_ok;
    wire        shadow_overflow_fault;
    wire        shadow_underflow_fault;

    wire        security_fault_e;
    wire        cfi_check_e;
    wire        cfi_violation_event_e;
    reg         security_halted;
    wire        stall_f_safe;
    wire        flush_d_safe;
    wire        flush_e_safe;
    assign stall_f_safe = stall_f || security_fault_e || security_halted;
    assign flush_d_safe = flush_d || security_fault_e || security_halted;
    assign flush_e_safe = flush_e || security_fault_e || security_halted;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            security_halted <= 1'b0;
        else if (security_fault_e)
            security_halted <= 1'b1;
    end
    wire [6:0]  opcode_d;
    wire [6:0]  opcode_e;

    // Retirement-accurate experiment counters, exposed read-only at 0x1100.
    reg [31:0] mcycle;
    reg [31:0] minstret;
    reg [31:0] aes_retired_count;
    reg [31:0] shadow_push_pop_count;
    reg [31:0] cfi_check_count;
    reg [31:0] cfi_violation_count;

    // ---- 分支预测信号声明 ----
    wire pred_taken_f;             // BHT预测结果（1=跳）
    wire btb_hit_f;                // BTB命中
    wire [31:0] btb_target_f;      // BTB缓存的目标地址
    wire [31:0] branch_pc_e;       // EX阶段的分支PC（从pc_e_in取）
    assign branch_pc_e = pc_e_in;
// OS-0 baseline: disable speculative branch prediction.
// IF always follows PC+4 until EX resolves a real branch/jump.
    wire use_predict = 1'b0;
    wire [31:0] predicted_target = 32'd0;
    wire branch_mispredicted;

    // ===============================================================
    // 2. 实例化 5 个阶段模块和 4 根黑粗线
    // ===============================================================
    if_stage u_if_stage (
        .use_predict(use_predict),
        .predicted_target(predicted_target),
        .clk(clk), .rst_n(rst_n), .stall_f(stall_f_safe), .pcsrc_e(pcsrc_e), .pctarget_e(pctarget_e),
        .pc_f(pc_f), .pc_plus_4_f(pc_plus_4_f),
        .pc_rom_f(pc_rom_f), .pc_plus_4_rom_f(pc_plus_4_rom_f),
        .instr_valid_f(instr_valid_f), .instr_f(instr_f)
    );
    if_id_reg u_if_id_reg (
        .clk(clk), .rst_n(rst_n), .flush_d(flush_d_safe), .stall_d(stall_d),
        .pc_f(pc_rom_f),
        .instr_f(instr_f), .pc_plus_4_f(pc_plus_4_rom_f),
        .instr_valid_f(instr_valid_f),
         .pc_d(pc_d),
        .instr_d(instr_d), .pc_plus_4_d(pc_plus_4_d),
        .valid_d(valid_d)
    );
    id_stage u_id_stage (
        .clk(clk), .instr_d(instr_d), .rd_w(rd_loop), .reg_write_w(reg_write_loop), .result_w(result_w),
        .pc_d_in(pc_d), .pc_plus_4_i(pc_plus_4_d), .pc_d_out(),
        .rs1_d(rs1_d), .rs2_d(rs2_d), .rd_d(rd_d), .rd1_d(rd1_d), .rd2_d(rd2_d),
        .imm_ext_d(imm_ext_d), .reg_write_d(reg_write_d), .mem_read_d(mem_read_d),
        .mem_write_d(mem_write_d), .result_src_d(result_src_d), .alu_control_d(alu_control_d),
        .branch_d(branch_d), .jump_d(jump_d), .alu_src_d(alu_src_d), .crypto_en_d(crypto_en_d),
        .crypto_op_d(crypto_op_d), .crypto_bs_d(crypto_bs_d),.kexp1i_en_d(kexp1i_en_d),.kexp_rnum_d(kexp_rnum_d),
        .jalr_d(jalr_d),
        .opcode_d(opcode_d)
    );
    id_ex_reg u_id_ex_reg (
        .clk(clk), .rst_n(rst_n), .flush_e(flush_e_safe), .stall_d(stall_d),
        .mem_read_d(mem_read_d), .reg_write_d(reg_write_d), .result_src_d(result_src_d),
        .mem_write_d(mem_write_d), .jump_d(jump_d), .alu_control_d(alu_control_d),
        .alu_src_d(alu_src_d), .branch_d(branch_d), .rd1_d(rd1_d), .rd2_d(rd2_d),
        .imm_ext_d(imm_ext_d), .pc_d(pc_d), .pc_plus_4_d(pc_plus_4_d),
        .rs1_d(rs1_d), .rs2_d(rs2_d), .rd_d(rd_d),
        .crypto_en_d(crypto_en_d),
        .crypto_op_d(crypto_op_d),
        .crypto_bs_d(crypto_bs_d),
        .jalr_d(jalr_d),
        .opcode_d(opcode_d),
        .valid_d(valid_d),
        .valid_e(valid_e),

        .rd1_e(rd1_e), .rd2_e(rd2_e), .imm_ext_e(imm_ext_e), .pc_e(pc_e_in), .pc_plus_4_e(pc_plus_4_e),
        .rs1_e(rs1_e), .rs2_e(rs2_e), .rd_e(rd_e), .reg_write_e(reg_write_e),
        .mem_read_e(mem_read_e), .mem_write_e(mem_write_e), .alu_src_e(alu_src_e),
        .jump_e(jump_e), .branch_e(branch_e), .result_src_e(result_src_e), .alu_control_e(alu_control_e),
        .crypto_en_e(crypto_en_e),
        .crypto_op_e(crypto_op_e),
        .crypto_bs_e(crypto_bs_e),
        .kexp1i_en_d(kexp1i_en_d),
        .kexp_rnum_d(kexp_rnum_d),
        .kexp1i_en_e(kexp1i_en_e),
        .kexp_rnum_e(kexp_rnum_e),
        .jalr_e(jalr_e),
        .opcode_e(opcode_e)
    );
    shadow_stack_mem #(
        .DEPTH(32)
    ) u_shadow_stack_mem (
        .clk             (clk),
        .rst_n           (rst_n),

        .push_en         (shadow_push_en),
        .push_ra         (shadow_push_ra),
        .pop_en          (shadow_pop_en),

        .top_ra          (shadow_top_ra),
        .empty           (shadow_empty),
        .full            (shadow_full),
        .depth           (shadow_depth),

        .push_ok         (shadow_push_ok),
        .pop_ok          (shadow_pop_ok),
        .overflow_fault  (shadow_overflow_fault),
        .underflow_fault (shadow_underflow_fault)
    );
    ex_stage u_ex_stage (
        .clk(clk), .reg_write_e(reg_write_e), .result_src_e(result_src_e), .mem_write_e(mem_write_e),
        .jump_e(jump_e), .branch_e(branch_e), .alu_control_e(alu_control_e), .alu_src_e(alu_src_e),
        .addr1_e(rd1_e), .addr2_e(rd2_e), .pc_e_in(pc_e_in), .forward_a_e(forward_ae),
        .alu_result_m(alu_result_m), .forward_b_e(forward_be), .imm_ext_e(imm_ext_e), .result_w(result_w),
        .rd_e(rd_e), .pc_plus_4_in(pc_plus_4_e), .pc_plus_4_out(pc_plus_4_ex), .rd_e_out(rd_e_out),
        .aluresult_e(alu_result_e), .pc_target_e(pctarget_e), .pcsrc_e(pcsrc_e),
        .write_data_e(write_data_e), .zero_e(zero_e),
        .div_start(1'b0), .fpu_start(1'b0),
        .crypto_en_e(crypto_en_e),
        .crypto_op_e(crypto_op_e),
        .crypto_bs_e(crypto_bs_e),.kexp1i_en_e(kexp1i_en_e),.kexp_rnum_e(kexp_rnum_e),
        .jalr_e(jalr_e),
        .opcode_e(opcode_e),
        .rs1_index_e(rs1_e),
        .shadow_top_ra(shadow_top_ra),
        .shadow_empty(shadow_empty),
        .shadow_overflow_fault(shadow_overflow_fault),
        .shadow_underflow_fault(shadow_underflow_fault),
        .shadow_push_en(shadow_push_en),
        .shadow_push_ra(shadow_push_ra),
        .shadow_pop_en(shadow_pop_en),
        .security_fault_e(security_fault_e),
        .cfi_check_e(cfi_check_e),
        .cfi_violation_event_e(cfi_violation_event_e)
    );
    ex_mem_reg u_ex_mem_reg (
        .clk(clk), .rst_n(rst_n), .flush_m(1'b0), .stall_m(1'b0),
        .alu_result_e(alu_result_e), .write_data_e(write_data_e), .pc_plus_4_e(pc_plus_4_ex),
        .zero_e(zero_e), .rd_e(rd_e_out), .reg_write_e(reg_write_e), .mem_write_e(mem_write_e),
        .valid_e(valid_e), .valid_m(valid_m), .crypto_en_e(crypto_en_e), .crypto_en_m(crypto_en_m),
        .result_src_e(result_src_e), .alu_result_m(alu_result_m), .write_data_m(write_data_m),
        .pc_plus_4_m(pc_plus_4_m), .zero_m(zero_m), .rd_m(rd_m), .reg_write_m(reg_write_m),
        .mem_write_m(mem_write_m), .result_src_m(result_src_m),
        .div_busy_in(1'b0), .div_remainder_in(32'b0), .fpu_exception_in(1'b0),.mem_read_e(mem_read_e),
        .mem_read_m(mem_read_m), .fpu_rmode_in(3'b0)
    );
    mem_stage u_mem_stage (
        .clk(clk), .rst_n(rst_n), .reg_write_m(reg_write_m), .result_src_m(result_src_m), .mem_write_m(mem_write_m),
        .mem_read_m(mem_read_m), .uart_rx(uart_rx), .uart_tx(uart_tx),
        .security_halted(security_halted), .mcycle(mcycle), .minstret(minstret),
        .aes_retired_count(aes_retired_count), .shadow_push_pop_count(shadow_push_pop_count),
        .cfi_check_count(cfi_check_count), .cfi_violation_count(cfi_violation_count),
        .shadow_depth(shadow_depth),
        .alu_result_m(alu_result_m), .write_data_m(write_data_m), .rd_m(rd_m),
        .pc_plus_4_in(pc_plus_4_m), .rd_w_out(rd_w_out), .pc_plus_4_m_out(pc_plus_4_m_out),
        .read_data_m(read_data_m),
        .fpu_mem_write(1'b0), .fpu_write_data(32'b0), .parity_check_en(1'b0),
        .rgb_pclk(), .rgb_hsync(), .rgb_vsync(), .rgb_de(),
        .lcd_reset_n(), .lcd_disp()
    );
    mem_wb_reg u_mem_wb_reg (
        .clk(clk), .rst_n(rst_n), .flush_w(1'b0), .stall_w(1'b0),
        .read_data_m(read_data_m), .alu_result_m(alu_result_m), .pc_plus_4_m(pc_plus_4_m_out),
        .rd_m(rd_w_out), .reg_write_m(reg_write_m), .result_src_m(result_src_m),
        .valid_m(valid_m), .valid_w(valid_w), .crypto_en_m(crypto_en_m), .crypto_en_w(crypto_en_w),
        .read_data_w(read_data_w), .alu_result_w(alu_result_w), .pc_plus_4_w(pc_plus_4_w),
        .rd_w(rd_w), .reg_write_w(reg_write_w), .result_src_w(result_src_w)
    );
    wb_stage u_wb_stage (
        .reg_write_w(reg_write_w), .result_src_w(result_src_w), .read_data_w(read_data_w),
        .alu_result_w(alu_result_w), .pc_plus_4_w(pc_plus_4_w), .rd_w(rd_w),
        .fpu_result_w(32'b0), .div_result_w(32'b0),
        .reg_write_out(reg_write_loop), .rd_out(rd_loop), .result_w(result_w)
    );
    // Internal experiment counters. They are intentionally not CSRs in v1;
    // testbenches (and OS-0 status MMIO) observe them hierarchically.

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            mcycle                <= 32'd0;
            minstret              <= 32'd0;
            aes_retired_count     <= 32'd0;
            shadow_push_pop_count <= 32'd0;
            cfi_check_count       <= 32'd0;
            cfi_violation_count   <= 32'd0;
        end else begin
            mcycle <= mcycle + 32'd1;
            if (valid_w)
                minstret <= minstret + 32'd1;
            if (valid_w && crypto_en_w)
                aes_retired_count <= aes_retired_count + 32'd1;
            if (shadow_push_ok || shadow_pop_ok)
                shadow_push_pop_count <= shadow_push_pop_count + 32'd1;
            if (cfi_check_e)
                cfi_check_count <= cfi_check_count + 32'd1;
            if (cfi_violation_event_e)
                cfi_violation_count <= cfi_violation_count + 32'd1;
        end
    end

    // With static not-taken policy, only an actually taken branch/jump needs
    // younger IF/ID and ID/EX instructions flushed.
    assign branch_mispredicted = pcsrc_e;
    hazard_unit u_hazard_unit (
        .id_ex_mem_read(mem_read_e), .ex_mem_reg_write(reg_write_m), .ex_rd(rd_e),
        .mem_rd(rd_m), .wb_rd(rd_w), .reg_write_w(reg_write_w), .pcsrc_e(pcsrc_e),
        .ex_rs1(rs1_e), .ex_rs2(rs2_e),
        .id_rs1(rs1_d), .id_rs2(rs2_d), .stall_f(stall_f), .stall_d(stall_d),
        .branch_mispredicted(branch_mispredicted),
        .ex_mem_mem_read(mem_read_m),
        .flush_e(flush_e), .flush_d(flush_d), .forward_ae(forward_ae), .forward_be(forward_be)
    );
    branch_predictor_top u_branch_pred (
        .clk(clk), .rst_n(rst_n),
        .pc_i(pc_f),
        .pred_taken_o(pred_taken_f),
        .btb_hit_o(btb_hit_f),
        .btb_target_o(btb_target_f),
        .update_pc_i(branch_pc_e),
        .update_taken_i(pcsrc_e),
        .update_target_i(pctarget_e)
    );
    // Diagnostic A: repeat the earlier 8x16 S glyph.  It separates a
    // multi-character density effect from the newer banner glyph mapping.
    wire [8:0]  display_x;
    wire [7:0]  display_y;
    wire [15:0] display_pixel;

    // Restored OS BIOS display after the RGB quadrant diagnostic confirmed
    // all data channels, pin mapping and timing are correct.
    bios_text_renderer u_bios_text_renderer (
        .x                 (display_x),
        .y                 (display_y),
        .security_halted   (security_halted),
        .mcycle            (mcycle),
        .minstret          (minstret),
        .aes_retired_count (aes_retired_count),
        .shadow_ops        (shadow_push_pop_count),
        .cfi_checks        (cfi_check_count),
        .cfi_violations    (cfi_violation_count),
        .shadow_depth      (shadow_depth),
        .pixel_out         (display_pixel)
    );

    rgb_scanout u_rgb_scanout (
        .clk        (clk),
        .rst_n      (rst_n),
        .pixel_in   (display_pixel),
        .internal_x (display_x),
        .internal_y (display_y),

        .rgb_pclk   (rgb_pclk),
        .rgb_hsync  (rgb_hsync),
        .rgb_vsync  (rgb_vsync),
        .rgb_de     (rgb_de),
        .rgb_r      (rgb_r),
        .rgb_g      (rgb_g),
        .rgb_b      (rgb_b)
    );

    assign lcd_reset_n = rst_n;
    assign lcd_disp    = 1'b1;

    // Board-visible evidence path. The reporter snapshots the counters after
    // a fixed execution window and sends one report at 115200 baud.
    // The fixed status reporter is retained for counter logic during the
    // transition, but it must not drive UART once CPU MMIO owns the pin.
    uart_status_reporter #(
        .CLK_PER_BIT(234),
        .WAIT_CYCLES(4096)
    ) u_uart_status_reporter (
        .clk(clk), .rst_n(rst_n), .uart_tx(), .report_done(),
        .security_halted(security_halted),
        .mcycle(mcycle), .minstret(minstret), .aes_retired_count(aes_retired_count),
        .shadow_push_pop_count(shadow_push_pop_count), .cfi_check_count(cfi_check_count),
        .cfi_violation_count(cfi_violation_count)
    );

endmodule
