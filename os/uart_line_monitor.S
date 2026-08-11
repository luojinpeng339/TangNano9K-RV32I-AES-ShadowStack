# OS-0D line-buffered command monitor v1
# Collect one CR-terminated command into RAM at 0x300, then parse help/status.
        addi x5, x0, 1
        slli x5, x5, 12
        addi x9, x5, 256
        addi x12, x0, 3
        slli x12, x12, 8
        jal  x1, prompt
main_loop:
        addi x10, x12, 0
collect:
        jal  x1, getc
        addi x8, x0, 13
        beq  x7, x8, line_end
        sw   x7, 0(x10)
        addi x10, x10, 4
        jal  x0, collect
line_end:
        sw   x7, 0(x10)
        jal  x0, parse_line
parse_line:
        lw   x8, 0(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 'h'
        beq  x8, x7, not_equal_ok_0
        jal  x0, check_status
not_equal_ok_0:
        lw   x8, 4(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 'e'
        beq  x8, x7, not_equal_ok_1
        jal  x0, unknown_line
not_equal_ok_1:
        lw   x8, 8(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 'l'
        beq  x8, x7, not_equal_ok_2
        jal  x0, unknown_line
not_equal_ok_2:
        lw   x8, 12(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 'p'
        beq  x8, x7, not_equal_ok_3
        jal  x0, unknown_line
not_equal_ok_3:
        lw   x8, 16(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 13
        beq  x8, x7, not_equal_ok_4
        jal  x0, unknown_line
not_equal_ok_4:
        jal  x1, help_ok
        jal  x0, main_loop
check_a:
        lw   x8, 0(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 'a'
        beq  x8, x7, a_second
        jal  x0, unknown_line
a_second:
        lw   x8, 4(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 'e'
        beq  x8, x7, aes_third
        addi x7, x0, 't'
        beq  x8, x7, attack_third
        jal  x0, unknown_line
aes_third:
        lw   x8, 8(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 's'
        beq  x8, x7, aes_end
        jal  x0, unknown_line
aes_end:
        lw   x8, 12(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 13
        beq  x8, x7, aes_demo
        jal  x0, unknown_line
attack_third:
        lw   x8, 8(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 't'
        beq  x8, x7, attack_fourth
        jal  x0, unknown_line
attack_fourth:
        lw   x8, 12(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 'a'
        beq  x8, x7, attack_fifth
        jal  x0, unknown_line
attack_fifth:
        lw   x8, 16(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 'c'
        beq  x8, x7, attack_sixth
        jal  x0, unknown_line
attack_sixth:
        lw   x8, 20(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 'k'
        beq  x8, x7, attack_end
        jal  x0, unknown_line
attack_end:
        lw   x8, 24(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 13
        beq  x8, x7, attack_demo
        jal  x0, unknown_line

aes_demo:
        addi x14, x0, 1
        addi x15, x0, 2
        aes32esi x14, x14, x15, 0
        addi x7, x0, 'A'
        jal  x1, putc
        addi x7, x0, 'E'
        jal  x1, putc
        addi x7, x0, 'S'
        jal  x1, putc
        addi x7, x0, ' '
        jal  x1, putc
        addi x7, x0, 'O'
        jal  x1, putc
        addi x7, x0, 'K'
        jal  x1, putc
        addi x7, x0, 13
        jal  x1, putc
        addi x7, x0, 10
        jal  x1, putc
        jal  x1, prompt
        jal  x0, main_loop

attack_demo:
        jal  x0, attack_body
attack_body:
        jal  x1, attack_payload
        jal  x0, attack_body
attack_payload:
        addi x1, x0, 64
        jalr x0, 0(x1)

check_status:
        lw   x8, 0(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 's'
        beq  x8, x7, not_equal_ok_5
        jal  x0, check_a
not_equal_ok_5:
        lw   x8, 4(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 't'
        beq  x8, x7, not_equal_ok_6
        jal  x0, unknown_line
not_equal_ok_6:
        lw   x8, 8(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 'a'
        beq  x8, x7, not_equal_ok_7
        jal  x0, unknown_line
not_equal_ok_7:
        lw   x8, 12(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 't'
        beq  x8, x7, not_equal_ok_8
        jal  x0, unknown_line
not_equal_ok_8:
        lw   x8, 16(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 'u'
        beq  x8, x7, not_equal_ok_9
        jal  x0, unknown_line
not_equal_ok_9:
        lw   x8, 20(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 's'
        beq  x8, x7, not_equal_ok_10
        jal  x0, unknown_line
not_equal_ok_10:
        lw   x8, 24(x12)
        addi x0, x0, 0
        addi x0, x0, 0
        addi x7, x0, 13
        beq  x8, x7, not_equal_ok_11
        jal  x0, unknown_line
not_equal_ok_11:
        jal  x1, status_ok
        jal  x0, main_loop
help_ok:
        addi x7,x0,'h'
 jal x1,putc
        addi x7,x0,'e'
 jal x1,putc
        addi x7,x0,'l'
 jal x1,putc
        addi x7,x0,'p'
 jal x1,putc
        addi x7,x0,':'
 jal x1,putc
        addi x7,x0,' '
 jal x1,putc
        addi x7,x0,'h'
 jal x1,putc
        addi x7,x0,'e'
 jal x1,putc
        addi x7,x0,'l'
 jal x1,putc
        addi x7,x0,'p'
 jal x1,putc
        addi x7,x0,' '
 jal x1,putc
        addi x7,x0,'s'
 jal x1,putc
        addi x7,x0,'t'
 jal x1,putc
        addi x7,x0,'a'
 jal x1,putc
        addi x7,x0,'t'
 jal x1,putc
        addi x7,x0,'u'
 jal x1,putc
        addi x7,x0,'s'
 jal x1,putc
        addi x7,x0,13
 jal x1,putc
        addi x7,x0,10
 jal x1,putc
        jalr x0,0(x1)
unknown_line:
        addi x7,x0,'u'
 jal x1,putc
        addi x7,x0,'n'
 jal x1,putc
        addi x7,x0,'k'
 jal x1,putc
        addi x7,x0,'n'
 jal x1,putc
        addi x7,x0,'o'
 jal x1,putc
        addi x7,x0,'w'
 jal x1,putc
        addi x7,x0,'n'
 jal x1,putc
        addi x7,x0,' '
 jal x1,putc
        addi x7,x0,'c'
 jal x1,putc
        addi x7,x0,'o'
 jal x1,putc
        addi x7,x0,'m'
 jal x1,putc
        addi x7,x0,'m'
 jal x1,putc
        addi x7,x0,'a'
 jal x1,putc
        addi x7,x0,'n'
 jal x1,putc
        addi x7,x0,'d'
 jal x1,putc
        addi x7,x0,13
 jal x1,putc
        addi x7,x0,10
 jal x1,putc
        jal x1,prompt
        jal x0,main_loop
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
        jal  x0, main_loop

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
#   output: eight hexadecimal ASCII characters, MS nibble first.
#   x13 keeps the shifting source; x7 is free for the ASCII byte consumed by
#   putc. (Using x7 for both corrupts all digits after the first.)
print_hex32:
        addi x11, x1, 0
        addi x13, x7, 0
        addi x10, x0, 8
hex_loop:
        srli x8, x13, 28
        slli x13, x13, 4
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
