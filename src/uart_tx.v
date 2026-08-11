`timescale 1ns/1ps
// Simple 8N1 transmitter. tx_start is sampled only when tx_ready=1.
module uart_tx #(
    parameter integer CLKS_PER_BIT = 234
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] tx_data,
    input  wire       tx_start,
    output reg        uart_tx,
    output wire       tx_ready
);
    localparam [1:0] TX_IDLE  = 2'd0,
                     TX_START = 2'd1,
                     TX_DATA  = 2'd2,
                     TX_STOP  = 2'd3;
    reg [1:0] state;
    reg [8:0] clk_counter;
    reg [2:0] bit_index;
    reg [7:0] shift;

    assign tx_ready = (state == TX_IDLE);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= TX_IDLE;
            clk_counter <= 9'd0;
            bit_index <= 3'd0;
            shift <= 8'd0;
            uart_tx <= 1'b1;
        end else begin
            case (state)
                TX_IDLE: begin
                    uart_tx <= 1'b1;
                    clk_counter <= 9'd0;
                    bit_index <= 3'd0;
                    if (tx_start) begin
                        shift <= tx_data;
                        uart_tx <= 1'b0;
                        state <= TX_START;
                    end
                end
                TX_START: begin
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter <= 9'd0;
                        uart_tx <= shift[0];
                        state <= TX_DATA;
                    end else clk_counter <= clk_counter + 1'b1;
                end
                TX_DATA: begin
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter <= 9'd0;
                        if (bit_index == 3'd7) begin
                            uart_tx <= 1'b1;
                            bit_index <= 3'd0;
                            state <= TX_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                            uart_tx <= shift[bit_index + 1'b1];
                        end
                    end else clk_counter <= clk_counter + 1'b1;
                end
                TX_STOP: begin
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter <= 9'd0;
                        uart_tx <= 1'b1;
                        state <= TX_IDLE;
                    end else clk_counter <= clk_counter + 1'b1;
                end
                default: state <= TX_IDLE;
            endcase
        end
    end
endmodule
