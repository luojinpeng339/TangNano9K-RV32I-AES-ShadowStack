`timescale 1ns/1ps
// Board-observable status reporter for the security CPU experiment.
// After WAIT_CYCLES, snapshots counters and sends one 8N1 UART report.
module uart_status_reporter #(
    parameter integer CLK_PER_BIT = 234,  // 27 MHz / 115200 ~= 234.375
    parameter integer WAIT_CYCLES = 4096
)(
    input  wire        clk,
    input  wire        rst_n,
    input  wire        security_halted,
    input  wire [31:0] mcycle,
    input  wire [31:0] minstret,
    input  wire [31:0] aes_retired_count,
    input  wire [31:0] shadow_push_pop_count,
    input  wire [31:0] cfi_check_count,
    input  wire [31:0] cfi_violation_count,
    output reg         uart_tx,
    output reg         report_done
);
    localparam [1:0] TX_IDLE=2'd0, TX_START=2'd1, TX_DATA=2'd2, TX_STOP=2'd3;
    reg [1:0] tx_state;
    reg [15:0] baud_count;
    reg [3:0] bit_index;
    reg [7:0] tx_byte;
    reg [15:0] wait_count;
    reg started;
    reg [3:0] section;
    reg [3:0] char_index;

    reg snap_halted;
    reg [31:0] snap_mcycle, snap_minstret, snap_aes, snap_ssops, snap_cfi_checks, snap_cfi_violations;

    function [7:0] hex_ascii;
        input [3:0] nibble;
        begin
            hex_ascii = (nibble < 10) ? (8'h30 + nibble) : (8'h41 + nibble - 10);
        end
    endfunction

    function [7:0] selected_hex;
        input [2:0] which;
        input [2:0] nibble_index;
        reg [31:0] value;
        begin
            case (which)
                3'd0: value = snap_mcycle;
                3'd1: value = snap_minstret;
                3'd2: value = snap_aes;
                3'd3: value = snap_ssops;
                3'd4: value = snap_cfi_checks;
                default: value = snap_cfi_violations;
            endcase
            selected_hex = hex_ascii((value >> ((7-nibble_index)*4)) & 4'hf);
        end
    endfunction

    // section 0 = "SEC-CPU\r\n"; 1 = H; 2..7 = six 32-bit counters.
    always @(*) begin
        tx_byte = 8'h00;
        case (section)
            4'd0: case (char_index)
                0: tx_byte="S"; 1: tx_byte="E"; 2: tx_byte="C"; 3: tx_byte="-";
                4: tx_byte="C"; 5: tx_byte="P"; 6: tx_byte="U"; 7: tx_byte=8'h0d;
                default: tx_byte=8'h0a;
            endcase
            4'd1: case (char_index)
                0: tx_byte="H"; 1: tx_byte="="; 2: tx_byte=snap_halted ? "1" : "0";
                3: tx_byte=8'h0d; default: tx_byte=8'h0a;
            endcase
            default: begin
                case (char_index)
                    0: tx_byte = (section==2) ? "M" : (section==3) ? "I" :
                                 (section==4) ? "A" : (section==5) ? "S" : "C";
                    1: tx_byte = (section==2) ? "C" : (section==3) ? "R" :
                                 (section==4) ? "R" : (section==5) ? "O" :
                                 (section==6) ? "C" : "V";
                    2: tx_byte = "=";
                    3,4,5,6,7,8,9,10: tx_byte = selected_hex(section-2, char_index-3);
                    11: tx_byte = 8'h0d;
                    default: tx_byte = 8'h0a;
                endcase
            end
        endcase
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            uart_tx <= 1'b1;
            report_done <= 1'b0;
            tx_state <= TX_IDLE;
            baud_count <= 0;
            bit_index <= 0;
            wait_count <= 0;
            started <= 1'b0;
            section <= 0;
            char_index <= 0;
            snap_halted <= 0;
            snap_mcycle <= 0; snap_minstret <= 0; snap_aes <= 0;
            snap_ssops <= 0; snap_cfi_checks <= 0; snap_cfi_violations <= 0;
        end else if (!started) begin
            uart_tx <= 1'b1;
            if (wait_count == WAIT_CYCLES-1) begin
                started <= 1'b1;
                snap_halted <= security_halted;
                snap_mcycle <= mcycle;
                snap_minstret <= minstret;
                snap_aes <= aes_retired_count;
                snap_ssops <= shadow_push_pop_count;
                snap_cfi_checks <= cfi_check_count;
                snap_cfi_violations <= cfi_violation_count;
            end else begin
                wait_count <= wait_count + 1'b1;
            end
        end else if (!report_done) begin
            case (tx_state)
                TX_IDLE: begin uart_tx <= 1'b0; baud_count <= 0; tx_state <= TX_START; end
                TX_START: if (baud_count == CLK_PER_BIT-1) begin baud_count<=0; bit_index<=0; uart_tx<=tx_byte[0]; tx_state<=TX_DATA; end else baud_count<=baud_count+1'b1;
                TX_DATA: if (baud_count == CLK_PER_BIT-1) begin
                    baud_count <= 0;
                    if (bit_index == 7) begin uart_tx <= 1'b1; tx_state <= TX_STOP; end
                    else begin bit_index <= bit_index+1'b1; uart_tx <= tx_byte[bit_index+1'b1]; end
                end else baud_count<=baud_count+1'b1;
                default: if (baud_count == CLK_PER_BIT-1) begin
                    baud_count <= 0; uart_tx <= 1'b1; tx_state <= TX_IDLE;
                    if ((section==0 && char_index==8) || (section==1 && char_index==4) || (section>=2 && char_index==12)) begin
                        char_index <= 0;
                        if (section == 7) report_done <= 1'b1;
                        else section <= section + 1'b1;
                    end else char_index <= char_index + 1'b1;
                end else baud_count<=baud_count+1'b1;
            endcase
        end
    end
endmodule
