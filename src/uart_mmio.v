`timescale 1ns/1ps
// CPU-visible UART peripheral, base 0x0000_1000.
// +0x00 write TXDATA; +0x04 read STATUS (bit1=rx_valid, bit0=tx_ready);
// +0x08 read RXDATA (acknowledges the one-byte RX buffer).
module uart_mmio #(
    parameter integer CLKS_PER_BIT = 234
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        uart_rx,
    output wire        uart_tx,

    input  wire        mmio_we,
    input  wire        mmio_re,
    input  wire [1:0] mmio_addr,
    input  wire [31:0] mmio_wdata,
    output reg [31:0] mmio_rdata
);
    wire [7:0] rx_data;
    wire rx_valid;
    wire tx_ready;
    wire tx_start = mmio_we && (mmio_addr == 2'd0) && tx_ready;
    wire rx_ack = mmio_re && (mmio_addr == 2'd2);

    uart_rx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart_rx (
        .clk(clk), .rst_n(rst_n), .uart_rx(uart_rx), .rx_ack(rx_ack),
        .rx_data(rx_data), .rx_valid(rx_valid)
    );

    uart_tx #(.CLKS_PER_BIT(CLKS_PER_BIT)) u_uart_tx (
        .clk(clk), .rst_n(rst_n), .tx_data(mmio_wdata[7:0]),
        .tx_start(tx_start), .uart_tx(uart_tx), .tx_ready(tx_ready)
    );

    always @(*) begin
        case (mmio_addr)
            2'd1: mmio_rdata = {30'd0, rx_valid, tx_ready}; // STATUS
            2'd2: mmio_rdata = {24'd0, rx_data};  // RXDATA
            2'd3: mmio_rdata = CLKS_PER_BIT;  // BAUD readback
            default: mmio_rdata = 32'd0;
        endcase
    end
endmodule
