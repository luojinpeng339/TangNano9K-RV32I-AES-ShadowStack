module rob (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        alloc_valid,
    output wire        alloc_ready,
    input  wire [31:0] alloc_pc,
    input  wire [4:0]  alloc_rd,
    input  wire        alloc_crypto,
    output wire [2:0]  alloc_tag,

    input  wire        wb_valid,
    input  wire [2:0]  wb_tag,
    input  wire [31:0] wb_result,

    output wire        commit_valid,
    input  wire        commit_ready,
    output wire [2:0]  commit_tag,
    output wire [31:0] commit_pc,
    output wire [4:0]  commit_rd,
    output wire [31:0] commit_result,
    output wire        commit_crypto
);

    localparam DEPTH = 8;

    // Contiguous live slots run from head (oldest) to tail (next allocation).
    reg [2:0] head, tail;
    reg [DEPTH-1:0] slot_valid;
    reg [DEPTH-1:0] slot_done;
    reg [DEPTH-1:0] slot_crypto;
    reg [31:0] slot_pc [0:DEPTH-1];
    reg [4:0]  slot_rd [0:DEPTH-1];
    reg [31:0] slot_result [0:DEPTH-1];

    wire alloc_fire, commit_fire;

    assign alloc_tag = tail;
    assign alloc_ready = rst_n && (!slot_valid[tail] || commit_fire);
    assign alloc_fire = alloc_valid && alloc_ready;

    // Only the head can commit. The payload is meaningful while commit_valid is high.
    assign commit_valid = rst_n && slot_valid[head] && slot_done[head];
    assign commit_tag = head;
    assign commit_pc = slot_pc[head];
    assign commit_rd = slot_rd[head];
    assign commit_result = slot_result[head];
    assign commit_crypto = slot_crypto[head];
    assign commit_fire = commit_valid && commit_ready;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            head <= 3'd0;
            tail <= 3'd0;
            slot_valid <= 0;
            slot_done <= 0;
        end else begin
            // Writeback uses the tag of an already allocated, unfinished slot.
            if (wb_valid && slot_valid[wb_tag] && !slot_done[wb_tag]) begin
                slot_result[wb_tag] <= wb_result;
                slot_done[wb_tag] <= 1'b1;
            end

            if (commit_fire) begin
                slot_valid[head] <= 1'b0;
                slot_done[head] <= 1'b0;
                head <= head + 3'd1;
            end

            // When full, head and tail coincide. Allocation wins if both fire.
            if (alloc_fire) begin
                slot_pc[tail] <= alloc_pc;
                slot_rd[tail] <= alloc_rd;
                slot_crypto[tail] <= alloc_crypto;
                slot_valid[tail] <= 1'b1;
                slot_done[tail] <= 1'b0;
                tail <= tail + 3'd1;
            end
        end
    end
endmodule