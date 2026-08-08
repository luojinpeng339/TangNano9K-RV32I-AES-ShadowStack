//================================================================================
// Module Name    : instr_mem
// Description    : Instruction Memory (ROM). Stores the RISC-V assembly program.
//                  Read-only, inherently for the IF stage.
//================================================================================

module instr_mem #(parameter WIDTH = 32, DEPTH = 1024)(
    input  wire clk,
    input  wire [WIDTH-1:0] addr,
    output wire [WIDTH-1:0] rdata
);

    reg [WIDTH-1:0] mem [0:DEPTH-1];

    initial begin
        $readmemh("test_program.hex", mem);
    end

    assign rdata = mem[addr >> 2];
endmodule