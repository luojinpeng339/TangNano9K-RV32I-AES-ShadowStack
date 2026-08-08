//============================================================================  
// Module          : alu  
// Auteur          : ZYY_2034580440  
// Créé le         : 2024.03.19  
// Design Notes    : Arithmetic Logic Unit with DIV/FPU operation stubs.  
//                  Base integer operations implemented, DIV/FP reserved.  
//                  Zero flag supports DIV-by-zero detection.  
// Future Ext      : alu_control[5:4] for DIV operations (DIV, DIVU, REM, REMU)  
//                  alu_control[7:6] for FP operations (FADD, FSUB, etc.)  
// Exception Path  : DIV-by-zero trap with precise exception handling  
//============================================================================  
module alu #(parameter WIDTH = 32)(  
input  wire [WIDTH-1:0] srca,  
input [WIDTH-1:0] srcb,  
input [2:0] alu_control,      // RV32I ALU control  
output reg  [WIDTH-1:0] aluresult,  
output reg zero,  
// RESERVED for extended operations  
output div_by_zero,           // Division by zero flag  
output overflow,             // Arithmetic overflow flag  
output fpu_exception         // Floating-point exception  
);
    always @(*) begin
        aluresult ={WIDTH{1'b0}};
        zero = 1'b0;
         case (alu_control)
            3'b000: aluresult = srca + srcb;  // add
            3'b001: aluresult = srca - srcb;  // sub
            3'b010: aluresult = srca & srcb;  // and
            3'b011: aluresult = srca | srcb;  // or  
            3'b100: aluresult = srca ^ srcb;
            3'b101: aluresult = srca << srcb[4:0];      // SLL / SLLI
            3'b110: aluresult = srca >> srcb[4:0];
            3'b111: aluresult = ($signed(srca) < $signed(srcb)) ? 1 : 0;
            default: aluresult = {WIDTH{1'b0}};// Safe defaul
        endcase
        zero= (aluresult == 0);
    end

endmodule
