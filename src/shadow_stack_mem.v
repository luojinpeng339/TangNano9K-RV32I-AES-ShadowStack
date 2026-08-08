module shadow_stack_mem #(
    parameter DEPTH = 32
)(
    input  wire        clk,
    input  wire        rst_n,

    input  wire        push_en,
    input  wire [31:0] push_ra,
    input  wire        pop_en,

    output wire [31:0] top_ra,
    output wire        empty,
    output wire        full,

    output reg         push_ok,
    output reg         pop_ok,
    output reg         overflow_fault,
    output reg         underflow_fault
);

    // 32 × 32-bit protected storage.
    reg [31:0] shadow_mem [0:DEPTH-1];

    // Must represent values 0 through DEPTH inclusive.
    reg [5:0] ssp;

    assign empty = (ssp == 0);
    assign full  = (ssp == DEPTH);

    // Return a deterministic value on empty; do not index ssp-1 in that case.
    assign top_ra = (ssp == 0) ? 32'b0 : shadow_mem[ssp - 1];

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            ssp <= 0;
            push_ok <= 1'b0;
            pop_ok <= 1'b0;
            overflow_fault <= 1'b0;
            underflow_fault <= 1'b0;
            // Deliberately do not clear shadow_mem: ssp defines validity.
        end
        else begin
            push_ok <= 1'b0;
            pop_ok  <= 1'b0;

            // First-version contract: simultaneous push/pop has no effect.
            // The future CFI controller must never request both together.
            if (push_en && pop_en) begin
            end
            else if (push_en) begin
                if (full) begin
                    overflow_fault <= 1'b1;
                end
                else begin
                    shadow_mem[ssp] <= push_ra;
                    ssp <= ssp + 1'b1;
                    push_ok <= 1'b1;
                end
            end
            else if (pop_en) begin
                if (empty) begin
                    underflow_fault <= 1'b1;
                end
                else begin
                    ssp <= ssp - 1'b1;
                    pop_ok <= 1'b1;
                end
            end
        end
    end

endmodule
