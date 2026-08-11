// Read-only OS-0 security/status register bank, base 0x0000_1100.
// The inputs are architectural experiment counters maintained by top_pipeline.
module security_status_mmio (
    input  wire security_halted,
    input  wire [31:0] mcycle,
    input  wire [31:0] minstret,
    input  wire [31:0] aes_retired_count,
    input  wire [31:0] shadow_push_pop_count,
    input  wire [31:0] cfi_check_count,
    input  wire [31:0] cfi_violation_count,
    input  wire [5:0]  shadow_depth,
    input  wire [4:0]  mmio_addr,
    output reg  [31:0] mmio_rdata
);
    always @(*) begin
        case (mmio_addr)
            5'h00: mmio_rdata = {31'd0, security_halted};
            5'h01: mmio_rdata = mcycle;
            5'h02: mmio_rdata = minstret;
            5'h03: mmio_rdata = aes_retired_count;
            5'h04: mmio_rdata = shadow_push_pop_count;
            5'h05: mmio_rdata = cfi_check_count;
            5'h06: mmio_rdata = cfi_violation_count;
            5'h07: mmio_rdata = {26'd0, shadow_depth};
            default: mmio_rdata = 32'd0;
        endcase
    end
endmodule
