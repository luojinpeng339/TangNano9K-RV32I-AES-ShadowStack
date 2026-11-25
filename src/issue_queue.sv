module issue_queue (
    input  wire        clk,
    input  wire        rst_n,

    input  wire        dispatch_valid,
    output wire        dispatch_ready,
    input  wire [2:0]  dispatch_tag,
    input  wire        dispatch_is_load,
    input  wire [2:0]  dispatch_op,
    input  wire        dispatch_src1_ready,
    input  wire [2:0]  dispatch_src1_tag,
    input  wire [31:0] dispatch_src1_value,
    input  wire        dispatch_src2_ready,
    input  wire [2:0]  dispatch_src2_tag,
    input  wire [31:0] dispatch_src2_value,

    input  wire        wb_valid,
    input  wire [2:0]  wb_tag,
    input  wire [31:0] wb_result,

    input  wire        alu_available,
    output wire        alu_issue_valid,
    output wire [2:0]  alu_issue_tag,
    output wire [2:0]  alu_issue_op,
    output wire [31:0] alu_src1,
    output wire [31:0] alu_src2,

    input  wire        load_available,
    output wire        load_issue_valid,
    output wire [2:0]  load_issue_tag,
    output wire [31:0] load_base,
    output wire [31:0] load_offset
);

    localparam DEPTH = 4;

    // ready=1 时使用 value，否则等待 tag 对应的写回结果。
    typedef struct packed {
        logic        ready;
        logic [2:0]  tag;
        logic [31:0] value;
    } operand_t;

    typedef struct packed {
        logic       is_load;
        logic [2:0] tag;
        logic [2:0] op;
        operand_t   src1;
        operand_t   src2;
    } entry_t;

    entry_t entries [0:DEPTH-1];
    entry_t next_entries [0:DEPTH-1];
    logic [2:0] count, next_count;
    logic [DEPTH-1:0] alu_selected, load_selected;
    entry_t alu_entry, load_entry;

    // 可用信号表示执行端本拍能接收。issue_valid 表示这一拍已选中。
    assign alu_issue_valid = |alu_selected;
    assign alu_issue_tag = alu_entry.tag;
    assign alu_issue_op = alu_entry.op;
    assign alu_src1 = alu_entry.src1.value;
    assign alu_src2 = alu_entry.src2.value;

    assign load_issue_valid = |load_selected;
    assign load_issue_tag = load_entry.tag;
    assign load_base = load_entry.src1.value;
    assign load_offset = load_entry.src2.value;

    assign dispatch_ready = rst_n && (count < DEPTH || alu_issue_valid || load_issue_valid);

    // 槽位按年龄从老到新排列。ALU 可以越过尚未就绪的指令。
    // 访存通道只考虑最老的 load，保持队列内 load 的发射顺序。
    always @* begin : select_issues
        entry_t candidate;
        logic saw_load;
        candidate = '0;
        saw_load = 1'b0;
        alu_selected = '0;
        load_selected = '0;
        alu_entry = '0;
        load_entry = '0;
        for (integer index = 0; index < DEPTH; index = index + 1) begin
            if (rst_n && index < count) begin
                candidate = entries[index];
                if (candidate.is_load) begin
                    if (!saw_load && load_available && candidate.src1.ready && candidate.src2.ready) begin
                        load_selected[index] = 1'b1;
                        load_entry = candidate;
                    end
                    saw_load = 1'b1;
                end else if (alu_available && alu_selected == 0 && candidate.src1.ready && candidate.src2.ready) begin
                    alu_selected[index] = 1'b1;
                    alu_entry = candidate;
                end
            end
        end
    end

    function automatic operand_t wake_operand(
        input operand_t source,
        input logic broadcast_valid,
        input logic [2:0] broadcast_tag,
        input logic [31:0] broadcast_result
    );
        operand_t updated;
        updated = source;
        if (!source.ready && broadcast_valid && source.tag == broadcast_tag) begin
            updated.ready = 1'b1;
            updated.value = broadcast_result;
        end
        return updated;
    endfunction

    // 去掉发射的槽位，保留其余槽位的年龄顺序，再把新指令追加到尾部。
    // 写回唤醒在时钟沿进入队列状态，下一拍才参与发射选择。
    always @* begin : advance_queue
        entry_t candidate;
        integer kept;
        candidate = '0;
        kept = 0;
        for (integer index = 0; index < DEPTH; index = index + 1)
            next_entries[index] = '0;

        for (integer index = 0; index < DEPTH; index = index + 1) begin
            if (index < count && !alu_selected[index] && !load_selected[index]) begin
                candidate = entries[index];
                candidate.src1 = wake_operand(candidate.src1, wb_valid, wb_tag, wb_result);
                candidate.src2 = wake_operand(candidate.src2, wb_valid, wb_tag, wb_result);
                next_entries[kept] = candidate;
                kept = kept + 1;
            end
        end

        if (dispatch_valid && dispatch_ready) begin
            candidate.is_load = dispatch_is_load;
            candidate.tag = dispatch_tag;
            candidate.op = dispatch_op;
            // 同拍入队的指令也要接到这次广播。
            candidate.src1 = wake_operand(
                {dispatch_src1_ready, dispatch_src1_tag, dispatch_src1_value}, wb_valid, wb_tag, wb_result);
            candidate.src2 = wake_operand(
                {dispatch_src2_ready, dispatch_src2_tag, dispatch_src2_value}, wb_valid, wb_tag, wb_result);
            next_entries[kept] = candidate;
            kept = kept + 1;
        end
        next_count = kept[2:0];
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            count <= 3'd0;
        end else begin
            count <= next_count;
            for (integer index = 0; index < DEPTH; index = index + 1)
                entries[index] <= next_entries[index];
        end
    end
endmodule