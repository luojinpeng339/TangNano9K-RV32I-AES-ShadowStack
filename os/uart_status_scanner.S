# OS-0C — UART command scanner v0
#
# Recognize exactly:
#     status<Enter>
#
# On success, transmit the live halt status and the low nibble of mcycle:
#     H=0\r\n
#     MC=?\r\n
# Registers:
#   x5 = UART base address, 0x1000
#   x6 = UART STATUS / temporary
#   x7 = received character / transmit byte / value to format
#   x8 = expected character / formatter temporary
#   x9 = security-status base, 0x1100
#   x11 = saved return address for print_hex32
#   x10 = remaining nibble count


        addi x5, x0, 1
        slli x5, x5, 12          # x5 = 0x1000
        addi x9, x5, 256         # x9 = 0x1100, security-status base

        jal  x1, prompt
        jal  x0, wait_s

wait_s:
        jal  x1, getc
        addi x8, x0, 'h'
        beq  x7, x8, help_t
        addi x8, x0, 's'
        beq  x7, x8, wait_t
        jal  x1, unknown_line
        jal  x0, wait_s


help_t:
        jal  x1, getc
        addi x8, x0, 'e'
        beq  x7, x8, help_l
        jal  x0, wait_s
help_l:
        jal  x1, getc
        addi x8, x0, 'l'
        beq  x7, x8, help_p
        jal  x0, wait_s
help_p:
        jal  x1, getc
        addi x8, x0, 'p'
        beq  x7, x8, help_enter
        jal  x0, wait_s
help_enter:
        jal  x1, getc
        addi x8, x0, 13
        beq  x7, x8, help_ok
        jal  x0, wait_s

help_ok:
        addi x7, x0, 'h'
        jal  x1, putc
        addi x7, x0, 'e'
        jal  x1, putc
        addi x7, x0, 'l'
        jal  x1, putc
        addi x7, x0, 'p'
        jal  x1, putc
        addi x7, x0, ':'
        jal  x1, putc
        addi x7, x0, ' '
        jal  x1, putc
        addi x7, x0, 'h'
        jal  x1, putc
        addi x7, x0, 'e'
        jal  x1, putc
        addi x7, x0, 'l'
        jal  x1, putc
        addi x7, x0, 'p'
        jal  x1, putc
        addi x7, x0, ' '
        jal  x1, putc
        addi x7, x0, 's'
        jal  x1, putc
        addi x7, x0, 't'
        jal  x1, putc
        addi x7, x0, 'a'
        jal  x1, putc
        addi x7, x0, 't'
        jal  x1, putc
        addi x7, x0, 'u'
        jal  x1, putc
        addi x7, x0, 's'
        jal  x1, putc
        addi x7, x0, 13
        jal  x1, putc
        addi x7, x0, 10
        jal  x1, putc
        jal  x1, prompt
        jal  x0, wait_s

unknown_line:
        # The first non-matching byte is already in x7. Discard the rest
        # of this line so the next prompt starts at a command boundary.
unknown_wait_enter:
        jal  x1, getc
        addi x8, x0, 13
        beq  x7, x8, unknown_enter
        jal  x0, unknown_wait_enter

unknown_enter:
        addi x7, x0, 'u'
        jal  x1, putc
        addi x7, x0, 'n'
        jal  x1, putc
        addi x7, x0, 'k'
        jal  x1, putc
        addi x7, x0, 'n'
        jal  x1, putc
        addi x7, x0, 'o'
        jal  x1, putc
        addi x7, x0, 'w'
        jal  x1, putc
        addi x7, x0, 'n'
        jal  x1, putc
        addi x7, x0, ' '
        jal  x1, putc
        addi x7, x0, 'c'
        jal  x1, putc
        addi x7, x0, 'o'
        jal  x1, putc
        addi x7, x0, 'm'
        jal  x1, putc
        addi x7, x0, 'm'
        jal  x1, putc
        addi x7, x0, 'a'
        jal  x1, putc
        addi x7, x0, 'n'
        jal  x1, putc
        addi x7, x0, 'd'
        jal  x1, putc
        addi x7, x0, 13
        jal  x1, putc
        addi x7, x0, 10
        jal  x1, putc
        jal  x1, prompt
        jal  x0, wait_s

wait_t:
        jal  x1, getc
        addi x8, x0, 't'
        beq  x7, x8, wait_a
        jal  x0, wait_s

wait_a:
        jal  x1, getc
        addi x8, x0, 'a'
        beq  x7, x8, wait_t2
        jal  x0, wait_s


wait_t2:
        jal  x1, getc
        addi x8, x0, 't'
        beq  x7, x8, wait_u
        jal  x0, wait_s        


wait_u:
        jal  x1, getc
        addi x8, x0, 'u'
        beq  x7, x8, wait_s2
        jal  x0, wait_s        


wait_s2:
        jal  x1, getc
        addi x8, x0, 's'
        beq  x7, x8, wait_enter
        jal  x0, wait_s         


wait_enter:
        jal  x1, getc
        addi x8, x0, 13         
        beq  x7, x8, status_ok
        jal  x0, wait_s

status_ok:
        addi x7, x0, 'H'
        jal  x1, putc
        addi x7, x0, '='
        jal  x1, putc
        lw   x7, 0(x9)           # SEC_HALT, bit0
        addi x7, x7, '0'
        jal  x1, putc
        addi x7, x0, 13
        jal  x1, putc
        addi x7, x0, 10
        jal  x1, putc

        addi x7, x0, 'M'
        jal  x1, putc
        addi x7, x0, 'C'
        jal  x1, putc
        addi x7, x0, '='
        jal  x1, putc
        lw   x7, 4(x9)           # MCYCLE
        jal  x1, print_hex32    # output all 8 hexadecimal nibbles
        addi x7, x0, 13
        jal  x1, putc
        addi x7, x0, 10
        jal  x1, putc

        addi x7, x0, 'M'
        jal  x1, putc
        addi x7, x0, 'I'
        jal  x1, putc
        addi x7, x0, '='
        jal  x1, putc
        lw   x7, 8(x9)           # MINSTRET
        jal  x1, print_hex32
        addi x7, x0, 13
        jal  x1, putc
        addi x7, x0, 10
        jal  x1, putc

        addi x7, x0, 'A'
        jal  x1, putc
        addi x7, x0, 'R'
        jal  x1, putc
        addi x7, x0, '='
        jal  x1, putc
        lw   x7, 12(x9)          # AES_RETIRED
        jal  x1, print_hex32
        addi x7, x0, 13
        jal  x1, putc
        addi x7, x0, 10
        jal  x1, putc

        addi x7, x0, 'S'
        jal  x1, putc
        addi x7, x0, 'O'
        jal  x1, putc
        addi x7, x0, '='
        jal  x1, putc
        lw   x7, 16(x9)          # SHADOW_OPS
        jal  x1, print_hex32
        addi x7, x0, 13
        jal  x1, putc
        addi x7, x0, 10
        jal  x1, putc

        addi x7, x0, 'C'
        jal  x1, putc
        addi x7, x0, 'C'
        jal  x1, putc
        addi x7, x0, '='
        jal  x1, putc
        lw   x7, 20(x9)          # CFI_CHECKS
        jal  x1, print_hex32
        addi x7, x0, 13
        jal  x1, putc
        addi x7, x0, 10
        jal  x1, putc

        addi x7, x0, 'C'
        jal  x1, putc
        addi x7, x0, 'V'
        jal  x1, putc
        addi x7, x0, '='
        jal  x1, putc
        lw   x7, 24(x9)          # CFI_VIOLATIONS
        jal  x1, print_hex32
        addi x7, x0, 13
        jal  x1, putc
        addi x7, x0, 10
        jal  x1, putc

        addi x7, x0, 'S'
        jal  x1, putc
        addi x7, x0, 'D'
        jal  x1, putc
        addi x7, x0, '='
        jal  x1, putc
        lw   x7, 28(x9)          # SHADOW_DEPTH
        jal  x1, print_hex32
        addi x7, x0, 13
        jal  x1, putc
        addi x7, x0, 10
        jal  x1, putc
        jal  x1, prompt
        jal  x0, wait_s

# prompt:
#   print the fixed interactive monitor prompt. x11 saves the caller's link
#   while each putc invocation uses x1.
prompt:
        addi x11, x1, 0
        addi x7, x0, 'S'
        jal  x1, putc
        addi x7, x0, 'E'
        jal  x1, putc
        addi x7, x0, 'C'
        jal  x1, putc
        addi x7, x0, '-'
        jal  x1, putc
        addi x7, x0, 'O'
        jal  x1, putc
        addi x7, x0, 'S'
        jal  x1, putc
        addi x7, x0, '0'
        jal  x1, putc
        addi x7, x0, '>'
        jal  x1, putc
        addi x7, x0, ' '
        jal  x1, putc
        addi x1, x11, 0
        jalr x0, 0(x1)

# print_hex32:
#   input x7 = 32-bit value
#   output: eight hexadecimal ASCII characters, MS nibble first
#   x11 preserves this routine's return address; x10 counts nibbles.
print_hex32:
        addi x11, x1, 0
        addi x10, x0, 8
hex_loop:
        slli x8, x7, 28
        srli x8, x8, 28
        slli x7, x7, 4
        addi x10, x10, -1
        addi x6, x0, 10
        beq  x8, x6, hex_a
        addi x6, x0, 11
        beq  x8, x6, hex_b
        addi x6, x0, 12
        beq  x8, x6, hex_c
        addi x6, x0, 13
        beq  x8, x6, hex_d
        addi x6, x0, 14
        beq  x8, x6, hex_e
        addi x6, x0, 15
        beq  x8, x6, hex_f
        addi x7, x8, 48
        jal  x1, putc
        beq  x10, x0, hex_return
        jal  x0, hex_loop
hex_a:
        addi x7, x0, 65
        jal  x1, putc
        beq  x10, x0, hex_return
        jal  x0, hex_loop
hex_b:
        addi x7, x0, 66
        jal  x1, putc
        beq  x10, x0, hex_return
        jal  x0, hex_loop
hex_c:
        addi x7, x0, 67
        jal  x1, putc
        beq  x10, x0, hex_return
        jal  x0, hex_loop
hex_d:
        addi x7, x0, 68
        jal  x1, putc
        beq  x10, x0, hex_return
        jal  x0, hex_loop
hex_e:
        addi x7, x0, 69
        jal  x1, putc
        beq  x10, x0, hex_return
        jal  x0, hex_loop
hex_f:
        addi x7, x0, 70
        jal  x1, putc
        beq  x10, x0, hex_return
        jal  x0, hex_loop
hex_return:
        addi x1, x11, 0
        jalr x0, 0(x1)

# putc:
#   transmit x7 after waiting for UART STATUS.bit0=tx_ready.
putc:
wait_tx_ready:
        lw   x6, 4(x5)          
        slli x6, x6, 31          
        srli x6, x6, 31
        beq  x6, x0, wait_tx_ready

        sw   x7, 0(x5)
        jalr x0, 0(x1)

# getc:
#   return x7 = one received UART byte
getc:
getc_wait_rx:
        lw   x6, 4(x5)           # x6 = STATUS
        srli x6, x6, 1           # STATUS.bit1 (rx_valid) -> bit0
        beq  x6, x0, getc_wait_rx

        lw   x7, 8(x5)           # x7 = RXDATA; reading clears rx_valid
        jalr x0, 0(x1)           # return
