module register_file #(parameter WIDTH = 32)(
    input  clk,
    input [4:0] addr1,
    input [4:0] addr2,
    input [4:0] addr3,
    input [WIDTH-1:0] wdata,
    input write_en,
    output [WIDTH-1:0] rdata1,
    output[WIDTH-1:0] rdata2
);

    reg [WIDTH-1:0] regs [0:31];
    // x0 恒为 0。WB→ID 同周期旁路保证：当一条指令在本时钟沿写回，
    // ID 阶段读取同一寄存器时能立刻看到新 wdata，而非旧 regs[] 值。
    // 这是五级流水线的 write-first register-file 语义。
    assign rdata1 = (addr1 == 0) ? {WIDTH{1'b0}} :
                    ((write_en && (addr3 != 0) && (addr3 == addr1)) ? wdata : regs[addr1]);
    assign rdata2 = (addr2 == 0) ? {WIDTH{1'b0}} :
                    ((write_en && (addr3 != 0) && (addr3 == addr2)) ? wdata : regs[addr2]);

    always @(posedge clk) begin
        if (write_en && (addr3 != 0)) begin
            regs[addr3] <= wdata;
        end
    end

endmodule
