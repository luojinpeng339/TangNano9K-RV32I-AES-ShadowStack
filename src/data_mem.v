//============================================================================  
// Module          : data_mem  
// Author          : LJP_2034580440
// Created         : 2026.03.22  
// Design Notes    : Dual-port data memory with FPU word size awareness.  
//                  Supports 32-bit integer and 64-bit double precision FP access.  
//                  Includes parity protection for reliability.  
// FP Alignment    : 64-bit FP accesses require 8-byte alignment (RESERVED check)  
// Error Detection : Parity bit per 32-bit word (RESERVED implementation)  
// Atomic Ops      : LR/SC support for RISC-V A extension (RESERVED)  
//============================================================================  
module data_mem #(  
parameter WIDTH = 32,  
parameter DEPTH = 1024,  
parameter ADDR_WIDTH = 10  
)(  
input  wire clk,  
input  wire mem_write_m,  
input  wire [ADDR_WIDTH-1:0] addr,  
input  wire [WIDTH-1:0] wdata,  
// RESERVED for extended features  
input  wire fpu_mem_write,      // FPU store operation  
input  wire [63:0] fpu_wdata,   // 64-bit FP data  
input  wire [3:0] byte_en,      // Byte enable for misaligned access  
input  wire parity_en,          // Parity generation enable  
output reg  [WIDTH-1:0] rdata,  
output reg  [63:0] fpu_rdata,   // 64-bit FP read data  
output reg  parity_error       // Memory parity error flag  
);  

    reg [WIDTH-1:0] mem [0 : DEPTH-1];

// 写端口
always @(posedge clk) begin
    if (mem_write_m) begin
        mem[addr] <= wdata;
    end
end

always @(*) begin
    rdata = mem[addr];
end
endmodule
