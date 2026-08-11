//============================================================================  
// Module          : mem_stage  
// Author          : Jinpeng Luo  
// Provenance      : Original work; header normalized 2026-08
// Design Notes    : Memory stage with data RAM + OS-0 MMIO integration.
//                  Address map:
//                    0x000–0xFFF → data memory (RAM)
//                    0x1000–0x10FF → UART MMIO
//                    0x1100–0x11FF → security/status MMIO
//============================================================================  
module mem_stage(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        reg_write_m,
    input  wire [1:0]  result_src_m,
    input  wire        mem_write_m,
    input  wire        mem_read_m,
    input  wire [31:0] alu_result_m,
    input  wire [31:0] write_data_m,
    input  wire [4:0]  rd_m,
    input  wire [31:0] pc_plus_4_in,
    // RESERVED ports for FPU/Div and fault tolerance  
    input  wire        fpu_mem_write,          // For FP store operations  
    input  wire [31:0] fpu_write_data,         // FP data to store  
    input  wire        parity_check_en,        // Memory parity check enable  

    // ---- GPU / RGB outputs ----
    output wire        rgb_pclk,
    output wire        rgb_hsync,
    output wire        rgb_vsync,
    output wire        rgb_de,
    output wire        lcd_reset_n,
    output wire        lcd_disp,
    input  wire        uart_rx,
    output wire        uart_tx,
    input  wire        security_halted,
    input  wire [31:0] mcycle,
    input  wire [31:0] minstret,
    input  wire [31:0] aes_retired_count,
    input  wire [31:0] shadow_push_pop_count,
    input  wire [31:0] cfi_check_count,
    input  wire [31:0] cfi_violation_count,
    input  wire [5:0]  shadow_depth,

    // ---- Pipeline outputs ----
    output wire [4:0]  rd_w_out,
    output wire [31:0] pc_plus_4_m_out,  
    output wire [31:0] read_data_m,
    output wire        mem_error_flag          // RESERVED: Memory access error flag 
);
    
    // ================================================================
    // 1. Address decoding
    //    UART MMIO: 0x1000 – 0x10FF
    //    Data RAM: all remaining addresses in the current OS-0 map
    // ================================================================
    wire uart_sel;
    assign uart_sel = (alu_result_m[31:8] == 24'h000010);
    wire security_sel;
    assign security_sel = (alu_result_m[31:8] == 24'h000011);

    wire data_mem_we;
    assign data_mem_we = mem_write_m && !uart_sel && !security_sel;

    wire uart_we;
    wire uart_re;
    assign uart_we = mem_write_m && uart_sel;
    assign uart_re = mem_read_m && uart_sel;

    // ================================================================
    // 2. Pipeline passthrough
    // ================================================================
    assign rd_w_out         = rd_m;
    assign pc_plus_4_m_out  = pc_plus_4_in;
    assign mem_error_flag   = 1'b0;   // reserved

    // ================================================================
    // 3. Data memory (addresses below 0x300)
    // ================================================================
    wire [31:0] data_mem_rdata;

    data_mem #(
        .WIDTH      (32),
        .DEPTH      (1024),
        .ADDR_WIDTH (10)
    ) u_data_mem (
        .clk         (clk),
        .mem_write_m (data_mem_we),
        .wdata       (write_data_m),
        .addr        (alu_result_m[11:2]),
        .rdata       (data_mem_rdata)
    );

    // ================================================================
    // 4. UART MMIO peripheral (0x1000–0x10FF)
    // ================================================================
    wire [31:0] uart_rdata;

    uart_mmio u_uart_mmio (
        .clk       (clk),
        .rst_n     (rst_n),
        .uart_rx   (uart_rx),
        .uart_tx   (uart_tx),
        .mmio_we   (uart_we),
        .mmio_re   (uart_re),
        .mmio_addr (alu_result_m[3:2]),
        .mmio_wdata(write_data_m),
        .mmio_rdata(uart_rdata)
    );

    wire [31:0] security_rdata;
    security_status_mmio u_security_status_mmio (
        .security_halted       (security_halted),
        .mcycle                (mcycle),
        .minstret              (minstret),
        .aes_retired_count     (aes_retired_count),
        .shadow_push_pop_count (shadow_push_pop_count),
        .cfi_check_count       (cfi_check_count),
        .cfi_violation_count   (cfi_violation_count),
        .shadow_depth          (shadow_depth),
        .mmio_addr             (alu_result_m[6:2]),
        .mmio_rdata            (security_rdata)
    );

    // ================================================================
    // 5. Read data mux: MMIO overrides data RAM when selected
    // ================================================================
    assign read_data_m = uart_sel ? uart_rdata :
                         security_sel ? security_rdata : data_mem_rdata;

endmodule
