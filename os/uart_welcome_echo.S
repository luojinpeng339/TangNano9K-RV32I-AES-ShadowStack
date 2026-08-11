# OS-0B — UART boot banner, then polling echo
#
# UART base: x5 = 0x1000.  TXDATA=0(x5), STATUS=4(x5), RXDATA=8(x5).
# STATUS.bit0=tx_ready, STATUS.bit1=rx_valid.
#
# Keep this first monitor deliberately flat: no subroutine calls/returns yet.
# That makes boot evidence independent from the protected shadow-stack path;
# a later command monitor can introduce an ABI and CALL/RETURN regression.

        addi x5, x0, 1
        slli x5, x5, 12

# For every byte below, wait_tx_ready then write x7 to TXDATA.
# The generated hex expands this exact sequence for: "SEC-OS0\r\n".
# wait_tx_ready:
#   lw x6, 4(x5)
#   slli x6, x6, 31
#   srli x6, x6, 31
#   beq x6, x0, wait_tx_ready
#   sw x7, 0(x5)

# After the banner, wait for a received byte and echo it.  The transmitter is
# already idle when entering this loop, so the immediate TXDATA write is safe.
echo_loop:
        lw   x6, 4(x5)
        srli x6, x6, 1
        beq  x6, x0, echo_loop
        lw   x7, 8(x5)
        sw   x7, 0(x5)
        jal  x0, echo_loop
