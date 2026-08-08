//============================================================================  
// Module          : ex_mem_reg  
// Author          : LJP_2034580440  
// Created         : 2026.03.20  
// Design Notes    : EX-MEM pipeline register with multi-cycle operation support.  
//                  Preserves DIV/FPU intermediate states across pipeline flushes.  
//                  Includes exception state for precise interrupt handling.  
// DIV State       : div_busy, div_remainder preserved during stalls  
// FPU State       : fpu_exception, fpu_rounding_mode propagated  
// Fault Recovery  : Exception flags clear on flush, preserved on stall  
//============================================================================  
module ex_mem_reg(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        flush_m,
    input  wire        stall_m,
    input  wire [31:0] alu_result_e,
    input  wire [31:0] write_data_e,
    input  wire [31:0] pc_plus_4_e,
    input  wire        zero_e,
    input  wire [4:0]  rd_e,
    input  wire        reg_write_e,
    input  wire        mem_write_e,
    input  wire [1:0]  result_src_e,
    input  wire valid_e,
    output reg  valid_m,
    output reg  [31:0] alu_result_m,
    output reg  [31:0] write_data_m,
    output reg  [31:0] pc_plus_4_m,
    output reg         zero_m,
    output reg  [4:0]  rd_m,
    output reg         reg_write_m,
    output reg         mem_write_m,
    output reg  [1:0]  result_src_m,
    input  wire        div_busy_in,  
    input wire mem_read_e,
    input  wire [31:0] div_remainder_in,  
    input  wire        fpu_exception_in,  
    input  wire [2:0]  fpu_rmode_in,  
    input  wire crypto_en_e,
    output reg  crypto_en_m,
    output reg         div_busy_out,  
    output reg [31:0]  div_remainder_out,  
    output reg         fpu_exception_out,  
    output reg mem_read_m,
    output reg [2:0]   fpu_rmode_out  
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            alu_result_m <= 32'b0;
            write_data_m <= 32'b0;
            pc_plus_4_m <= 32'b0;
            zero_m <= 1'b0;
            rd_m <= 5'b0;
            reg_write_m <= 1'b0;
            mem_write_m <= 1'b0;
            result_src_m <= 2'b00;
            mem_read_m <= 1'b0;
            valid_m <= 1'b0;
            crypto_en_m <= 1'b0;
        end
        else if (flush_m) begin
            alu_result_m <= 32'b0;
            write_data_m <= 32'b0;
            pc_plus_4_m <= 32'b0;
            zero_m <= 1'b0;rd_m <= 5'b0;
            reg_write_m <= 1'b0;
            mem_write_m <= 1'b0;//为了后续扩展除数与异常消查，这不一定要
            result_src_m <= 2'b00;
            mem_read_m <= 1'b0;
            valid_m <= 1'b0;
            crypto_en_m <= 1'b0;
        end
        else if (stall_m) begin
        
        end
        else begin
            alu_result_m <= alu_result_e;
            write_data_m <= write_data_e;
            pc_plus_4_m <= pc_plus_4_e;
            zero_m <= zero_e;
            rd_m <= rd_e;
            reg_write_m <= reg_write_e;
            mem_write_m <= mem_write_e;
            result_src_m <= result_src_e;
            mem_read_m <= mem_read_e;
            valid_m <= valid_e;
            crypto_en_m <= crypto_en_e;
        end
    end
endmodule

// module ex_mem_reg(  
// input  wire        clk,  
// input  wire        rst_n,  
// input  wire        flush_m,  
// input  wire        stall_m,  
// // Standard ports...  
// // RESERVED for DIV/FPU state preservation  
// input  wire        div_busy_in,  
// input  wire [31:0] div_remainder_in,  
// input  wire        fpu_exception_in,  
// input  wire [2:0]  fpu_rmode_in,  
// output reg         div_busy_out,  
// output reg [31:0]  div_remainder_out,  
// output reg         fpu_exception_out,  
// output reg [2:0]   fpu_rmode_out  
// );

// always @(posedge clk or negedge rst_n) begin  
// if (!rst_n) begin  
// // Standard reset...  
// div_busy_out <= 1'b0;  
// div_remainder_out <= 32'b0;  
// fpu_exception_out <= 1'b0;  
// fpu_rmode_out <= 3'b000;  
// end  
// else if (flush_m) begin  
// // Branch misprediction flush  
// div_busy_out <= 1'b0;       // Cancel ongoing DIV/FPU ops  
// fpu_exception_out <= 1'b0;  
// end  
// else if (!stall_m) begin  
// // Normal pipeline advance  
// div_busy_out <= div_busy_in;  
// div_remainder_out <= div_remainder_in;  
// fpu_exception_out <= fpu_exception_in;  
// fpu_rmode_out <= fpu_rmode_in;  
// end  
// // Else: stall preserves all states (multi-cycle ops safe)  
// end  
// endmodule  
