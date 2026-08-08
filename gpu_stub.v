`timescale 1ns/1ps

// 仅用于 CPU 仿真，不是正式 GPU RTL。
// AES 指令不访问 GPU MMIO，因此所有 GPU 读数据返回 0。
module gpu_top (
    input  wire        clk,
    input  wire        rst_n,
    input  wire        gpu_sel,
    input  wire        gpu_we,
    input  wire        gpu_re,
    input  wire [5:0]  gpu_addr,
    input  wire [31:0] gpu_wdata,

    output wire [31:0] gpu_rdata,
    output wire        rgb_pclk,
    output wire        rgb_hsync,
    output wire        rgb_vsync,
    output wire        rgb_de,
    output wire        lcd_reset_n,
    output wire        lcd_disp,
    output wire [4:0]  rgb_r,
    output wire [5:0]  rgb_g,
    output wire [4:0]  rgb_b
);

    assign gpu_rdata  = 32'b0;

    assign rgb_pclk   = clk;
    assign rgb_hsync  = 1'b0;
    assign rgb_vsync  = 1'b0;
    assign rgb_de     = 1'b0;
    assign lcd_reset_n = rst_n;
    assign lcd_disp   = 1'b0;
    assign rgb_r      = 5'b0;
    assign rgb_g      = 6'b0;
    assign rgb_b      = 5'b0;

endmodule