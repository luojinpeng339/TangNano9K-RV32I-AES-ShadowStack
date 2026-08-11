`timescale 1ns/1ps
// UART 8N1 receiver, one-byte buffer, LSB-first.
// uart_rx is asynchronous to clk and is synchronized internally.
module uart_rx #(
    parameter integer CLKS_PER_BIT = 234
)(
    input  wire       clk,
    input  wire       rst_n,
    input  wire       uart_rx,  // 18pin
    input  wire       rx_ack,   //清除rx_vaild
    output reg [7:0]  rx_data,  // 8-bit字节
    output reg        rx_valid  //未被读取的字节
);
    localparam integer HALF_BIT = CLKS_PER_BIT / 2;
    localparam [1:0] RX_IDLE  = 2'd0,
                     RX_START = 2'd1,
                     RX_DATA  = 2'd2,
                     RX_STOP  = 2'd3;

    // Two-flop synchronizer: all receive-state logic below uses rx_sync only.
    reg rx_meta;
    reg rx_sync;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rx_meta <= 1'b1;
            rx_sync <= 1'b1;
        end else begin
            rx_meta <= uart_rx;
            rx_sync <= rx_meta;
        end
    end

    reg [1:0] state;
    reg [8:0] clk_counter;
    reg [2:0] bit_index;
    reg [7:0] rx_shift;


    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state       <= RX_IDLE;
            clk_counter <= 9'd0;
            bit_index   <= 3'd0;
            rx_shift    <= 8'd0;
            rx_data     <= 8'd0;
            rx_valid    <= 1'b0;
        end else begin
            
            if (rx_ack)
                rx_valid <= 1'b0;

            case (state)
                RX_IDLE: begin
                    clk_counter <= 9'd0;
                    bit_index   <= 3'd0;
                    if (!rx_sync)
                        state <= RX_START;
                end

                // Re-sample at the middle of the candidate start bit to reject
                // narrow low glitches before accepting a frame.
                RX_START: begin
                    if (clk_counter == HALF_BIT - 1) begin
                        clk_counter <= 9'd0;
                        if (!rx_sync) begin
                            bit_index <= 3'd0;
                            state <= RX_DATA;
                        end else begin
                            state <= RX_IDLE;
                        end
                    end else begin
                        clk_counter <= clk_counter + 1'b1;
                    end
                end

                // UART sends the least-significant bit first, so directly store
                // each centre sample in the matching destination bit position.
                RX_DATA: begin
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter <= 9'd0;
                        rx_shift[bit_index] <= rx_sync;
                        if (bit_index == 3'd7) begin
                            bit_index <= 3'd0;
                            state <= RX_STOP;
                        end else begin
                            bit_index <= bit_index + 1'b1;
                        end
                    end else begin
                        clk_counter <= clk_counter + 1'b1;
                    end
                end

                // A valid 8N1 frame has an asserted stop bit. A bad stop bit is
                // silently discarded in v0; the MMIO layer may add framing-error
                // reporting later without changing the data-path contract.
                RX_STOP: begin
                    if (clk_counter == CLKS_PER_BIT - 1) begin
                        clk_counter <= 9'd0;
                        state <= RX_IDLE;
                        if (rx_sync) begin
                            rx_data <= rx_shift;
                            rx_valid <= 1'b1;
                        end
                    end else begin
                        clk_counter <= clk_counter + 1'b1;
                    end
                end

                default: begin
                    state       <= RX_IDLE;
                    clk_counter <= 9'd0;
                    bit_index   <= 3'd0;
                end
            endcase
        end
    end
endmodule
