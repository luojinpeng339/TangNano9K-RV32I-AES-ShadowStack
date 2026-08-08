//============================================================================  
// Module          : mem_stage  
// Author          : ZYY_2034580440 / Luo & Lan  
// Created         : 2024.03.16 / Updated 2026.07.28
// Design Notes    : Memory stage with data RAM + GPU MMIO integration.
//                  Address map:
//                    0x000–0x2FF → data memory (RAM)
//                    0x400–0x4FF → GPU MMIO
//============================================================================  
module mem_stage(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        reg_write_m,
    input  wire [1:0]  result_src_m,
    input  wire        mem_write_m,
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
    output wire [4:0]  rgb_r,
    output wire [5:0]  rgb_g,
    output wire [4:0]  rgb_b,

    // ---- Pipeline outputs ----
    output wire [4:0]  rd_w_out,
    output wire [31:0] pc_plus_4_m_out,  
    output wire [31:0] read_data_m,
    output wire        mem_error_flag          // RESERVED: Memory access error flag 
);
    
    // ================================================================
    // 1. Address decoding
    //    GPU MMIO: 0x400 – 0x4FF
    //    Data RAM: everything else that fits in 10-bit addr width
    // ================================================================
    wire gpu_sel;
    assign gpu_sel = (alu_result_m[31:8] == 24'h000004);

    wire data_mem_we;
    assign data_mem_we = mem_write_m && !gpu_sel;

    wire gpu_we;
    wire gpu_re;
    assign gpu_we = mem_write_m && gpu_sel;
    assign gpu_re = !mem_write_m && gpu_sel;

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
    // 4. GPU MMIO peripheral (addresses 0x400–0x4FF)
    // ================================================================
    wire [31:0] gpu_rdata;

    gpu_top u_gpu_top (
        .clk      (clk),
        .rst_n    (rst_n),
        .gpu_sel  (gpu_sel),
        .gpu_we   (gpu_we),
        .gpu_re   (gpu_re),
        .gpu_addr (alu_result_m[7:2]),
        .gpu_wdata(write_data_m),
        .gpu_rdata(gpu_rdata),
        .rgb_pclk (rgb_pclk),
        .rgb_hsync(rgb_hsync),
        .rgb_vsync(rgb_vsync),
        .rgb_de   (rgb_de),
        .lcd_reset_n(lcd_reset_n),
        .lcd_disp (lcd_disp),
        .rgb_r    (rgb_r),
        .rgb_g    (rgb_g),
        .rgb_b    (rgb_b)
    );

    // ================================================================
    // 5. Read data mux: GPU overrides data_mem when selected
    // ================================================================
    assign read_data_m = gpu_sel ? gpu_rdata : data_mem_rdata;

endmodule
