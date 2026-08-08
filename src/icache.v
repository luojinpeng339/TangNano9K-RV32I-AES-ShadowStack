module icache #(
    parameter CACHE_ENTRIES = 64,
    parameter INDEX_BITS = 6
)(
    input  clk,
    input  rst_n,
    input  [31:0] addr,
    output [31:0] inst
);
    wire [31:0] mem_instr;
    instr_mem u_mem(
        .clk  (clk),
        .addr (addr),
        .rdata(mem_instr)
    );

    reg [31:0] cache_data [0:CACHE_ENTRIES-1];
    reg [31:0] cache_tag  [0:CACHE_ENTRIES-1];
    reg        cache_valid[0:CACHE_ENTRIES-1];

    integer i;
    wire [INDEX_BITS-1:0] index = addr[7:2];
    wire [31:0] tag = addr[31:8];

    wire hit = cache_valid[index] && (cache_tag[index] == tag);
    assign inst = hit ? cache_data[index] : mem_instr;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < CACHE_ENTRIES; i = i + 1)
                cache_valid[i] <= 1'b0;
        end else begin
            if (!hit) begin
                cache_valid[index] <= 1'b1;
                cache_tag  [index] <= tag;
                cache_data [index] <= mem_instr;
            end
        end
    end

endmodule
