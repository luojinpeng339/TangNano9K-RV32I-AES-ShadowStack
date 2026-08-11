module instr_mem #(parameter WIDTH = 32, DEPTH = 512)(
    input  wire              clk,
    input  wire [WIDTH-1:0]  addr,
    output reg  [WIDTH-1:0]  rdata
);
    (* ram_style = "block" *) reg [WIDTH-1:0] mem [0:DEPTH-1];
    initial $readmemh("test_program.hex", mem);
    always @(posedge clk) rdata <= mem[addr >> 2];
endmodule
