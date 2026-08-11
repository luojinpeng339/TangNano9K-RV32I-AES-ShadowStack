# OS-0 Test C — poll UART RX validity
#
# UART_STATUS = 0x1004:
#   bit0 = tx_ready
#   bit1 = rx_valid
# No received character: STATUS=1, STATUS>>1=0, branch back to loop.

        addi x5, x0, 1
        slli x5, x5, 12

loop:
        lw   x6, 4(x5)
        srli x6, x6, 1
        beq  x6, x0, loop

        # Reached only after UART RX has placed a byte in its buffer.
        jal  x0, 0
