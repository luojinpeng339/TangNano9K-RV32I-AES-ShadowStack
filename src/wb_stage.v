//============================================================================  
// Module          : wb_stage  
// Author          : Jinpeng Luo  
// Provenance      : Original work; header normalized 2026-08
// Design Notes    : Write-back stage with extensible result sources for future  
//                  FPU and divider integration. Supports 5-to-8 result types.  
//                  Zero-extension handles custom RV32IMFD extensions.  
// Future Ext      : result_src_w[2] for FP result, [3] for division remainder  
//                  wb_bypass added for early write-back to reduce RAW hazards  
//============================================================================  
module wb_stage(  
input reg_write_w,  
input [1:0] result_src_w,    // RV32I: memory, ALU, or PC+4  
input [31:0] read_data_w,  
input [31:0] alu_result_w,  
input [31:0] pc_plus_4_w,  
input [31:0] fpu_result_w,    // RESERVED for floating-point unit  
input [31:0] div_result_w,    // RESERVED for integer divider  
input [4:0] rd_w,  
output reg_write_out,  
output [4:0] rd_out,  
output reg [31:0] result_w,  
output wb_bypass            // RESERVED for early hazard resolution  
);

// ---- Control Signal Propagation (with fault-tolerant defaults) ----  
assign reg_write_out = reg_write_w;  
assign rd_out = rd_w;  
assign wb_bypass = 1'b0;      // RESERVED: Enable early write-back bypass

// ---- Multi-Source Result Selection (Extensible Architecture) ----  
// Priority: Div/FP > Memory > ALU > PC+4 > Safe Default  
// Current: RV32I base (3 sources), Future: RV32IMFD (6 sources)  
always @(*) begin  
result_w = 32'b0;  // Fault-tolerant default (avoids X-propagation)

case (result_src_w[1:0])      // Current implementation  
2'b00 : result_w = read_data_w;    // Mem-to-reg  
2'b01 : result_w = alu_result_w;   // ALU result  
2'b10 : result_w = pc_plus_4_w;    // PC for JAL/RET  
default: result_w = 32'b0;         // Safe default (error recovery)  
endcase

// FPU/divider result selection is intentionally not part of the RV32I baseline.  
end

endmodule  
// module wb_stage(
//     input reg_write_w,
//     input [1:0] result_src_w,
//     input [31 :0] read_data_w,
//     input [31 : 0] alu_result_w,
//     input [31:0] pc_plus_4_w,
//     input [4 : 0] rd_w,
//     output reg_write_out,
//     output [4:0]  rd_out,
//     output reg [31:0] result_w
// );
//     assign reg_write_out = reg_write_w;
//     assign rd_out = rd_w;
//     always @(*) begin
//         result_w = 32'b0;
//     case (result_src_w)
//     2'b00 : result_w= read_data_w;
//     2'b01 : result_w = alu_result_w;
//     2'b10 : result_w = pc_plus_4_w;    
//         default: result_w =32'b0;
//     endcase
//     end

// endmodule
