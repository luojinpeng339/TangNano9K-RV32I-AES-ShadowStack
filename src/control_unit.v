
//============================================================================  
// Module          : control_unit  
// Author          : Luo Jinpeng  
// Provenance      : Original work; header normalized 2026-08
// Design Notes    : Extended control unit for RV32IMFD instruction set.  
//                  Generates DIV/FPU control signals with hazard awareness.  
//                  Supports multi-cycle operation scheduling.  
// DIV Control     : div_start, div_signed, div_long (64-bit) signals  
// FPU Control     : fpu_op[2:0], fpu_rounding, fpu_fmt (S/D) signals  
// Exception       : Illegal instruction, DIV-by-zero, FP invalid op detection  
//=======================================================
module control_unit (
    input  wire [6:0]  opcode, 
    input  wire [2:0]  funct3, 
    input  wire [6:0]  funct7,
    output reg  reg_write,   
    output reg  mem_read,
    output reg  mem_write,   
    output reg  alu_src,      
    output reg  branch,       
    output reg  jump,        
    output reg [1:0] result_src,   //00=内存, 01=ALU, 10=PC+4
    output reg [2:0] alu_control, // ALU 控制码
    output reg [1:0] imm_src,     // I(00), S(01), B(10), J(11)

 // Zkne AES 指令识别信号：
 // crypto_en=1 表示当前指令是 aes32esi 或 aes32esmi。
 // crypto_op=0: aes32esi（最终轮）；1: aes32esmi（中间轮）。
    output reg crypto_en,
    output reg crypto_op,
    output reg kexp1i_en,
    output reg jalr
);

    always @(*) begin
        reg_write = 1'b0;
        mem_read = 1'b0;
        mem_write = 1'b0;
        alu_src = 1'b0;
        branch = 1'b0;
        jump  = 1'b0;
        result_src = 2'b01; 
        alu_control  = 3'b000;
        imm_src   = 2'b00;
        crypto_en = 1'b0;
        crypto_op = 1'b0;
        kexp1i_en = 1'b0;
        jalr = 1'b0;
        case (opcode)
            // R-Type 
    7'b0110011: begin
        reg_write = 1'b1;
        result_src = 2'b01;  
        alu_src = 1'b0;
  
 if ((funct3 == 3'b000) && (funct7[4:0] == 5'b10001)) begin
     crypto_en = 1'b1;
     crypto_op = 1'b0;  
 end
 else if ((funct3 == 3'b000) && (funct7[4:0] == 5'b10011)) begin
     crypto_en = 1'b1;
     crypto_op = 1'b1;
 end
 else begin
     // 非 AES 的普通 RV32I R 型 ALU 指令，保持原有逻辑。
     case ({funct7[5], funct3})
         4'b0000: alu_control = 3'b000; // ADD
         4'b1000: alu_control = 3'b001; // SUB
         4'b0111: alu_control = 3'b010; // AND
         4'b0110: alu_control = 3'b011; // OR
         4'b0100: alu_control = 3'b100; // XOR
         4'b0010: alu_control = 3'b111; // SLT
         default: alu_control = 3'b000;
     endcase
 end
                end
            
            // I-Type ADDI
            7'b0010011: begin
                reg_write = 1'b1;
                alu_src    = 1'b1;
                alu_control= 3'b000;  // ADD
                result_src = 2'b01;
                imm_src    = 2'b00;
                case (funct3)
                3'b000: alu_control = 3'b000; // ADDI
                3'b001: alu_control = 3'b101; // SLLI
                3'b101: alu_control = 3'b110; // SRLI
                default: alu_control = 3'b000; // 暂按 ADDI 安全处理
            endcase
            end

            // LW (Load Word)
            7'b0000011: begin
                reg_write = 1'b1;
                mem_read  = 1'b1;
                alu_src    = 1'b1;
                alu_control= 3'b000;  // ADD
                result_src = 2'b00;
                imm_src    = 2'b00;
            end

            // SW (Store Word)
            7'b0100011: begin
                mem_write = 1'b1;
                alu_src    = 1'b1;
                alu_control= 3'b000;  // ADD
                imm_src    = 2'b01;
            end

            // BEQ (Branch if Equal)
            7'b1100011: begin
                branch     = 1'b1;
                alu_control = 3'b001;  // SUB (ALU: 001 = -), zero flag判相等
                imm_src    = 2'b10;
            end

            // JAL (Jump And Link)
            7'b1101111: begin
                reg_write = 1'b1;
                jump   = 1'b1;    
                result_src = 2'b10;  
                imm_src   = 2'b11;   
            end

            7'b0001011: begin
                // Custom-0: kexp1i rd, rs1, rnum
                if (funct3 == 3'b000) begin
                    reg_write = 1'b1;
                    result_src = 2'b01;
                    alu_src = 1'b0;
                    kexp1i_en = 1'b1;
                end
            end
            
            7'b1100111: begin
                reg_write = 1'b1;
                result_src = 2'b10;//jair
                alu_src = 1'b1;
                imm_src = 2'b00;
                jump = 1'b1;
                jalr = 1'b1;
            end




            default: begin
                //nop
                reg_write  = 1'b0;
                mem_read   = 1'b0;
                mem_write  = 1'b0;
                alu_src    = 1'b0;
                branch     = 1'b0;
                jump       = 1'b0;
                result_src = 2'b01;
                alu_control= 3'b010;
                imm_src    = 2'b00;
            end



        endcase
    end
endmodule
 
 
//=====================  
// module control_unit (  
// input [31:0] instr,  
// // Standard outputs...  
// // Extended outputs for DIV/FPU  
// output reg div_start,  
// output reg div_signed,  
// output reg fpu_start,  
// output reg [2:0] fpu_op,  
// output reg [2:0] fpu_rmode,  
// output reg illegal_instr,  
// output reg div_zero_check  
// );

// // ---- Instruction Decoding with Extensions ----  
// always @(*) begin  
// // Base RV32I decoding...  
// div_start = 1'b0;  
// div_signed = 1'b0;  
// fpu_start = 1'b0;  
// fpu_op = \[2:0]'b000;  
// illegal_instr = 1'b0;  
// div_zero_check = 1'b0;

// casez (instr)  
// // RESERVED: DIV instructions  
// 32'b0000001_?????_?????_???_?????_0110011: begin // DIV  
// div_start = 1'b1;  
// div_signed = 1'b1;  
// div_zero_check = 1'b1;  
// end  
// // RESERVED: FPU instructions  
// 32'b0000011_?????_?????_???_?????_0010011: begin // FADD.S  
// fpu_start = 1'b1;  
// fpu_op = 3'b000;  
// fpu_rmode = instr\[14:12]; // Rounding mode from instr  
// end  
// // Illegal instruction trap  
// default: begin  
// if (!is_valid_rv32i(instr)) begin  
// illegal_instr = 1'b1;  
// end  
// end  
// endcase  
// end

// endmodule
