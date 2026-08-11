# OS-0C line-buffer prototype
#
# Purpose: validate word-per-character line buffering without changing the
# current command monitor. Data RAM buffer starts at 0x300.
# Input: one UART line terminated by CR.
# Output: echoes the buffered line, then CR/LF, then loops.
#
# This is deliberately a standalone prototype. It does not replace the
# verified status/help monitor until its end-to-end test passes.
# x5 = UART base 0x1000
# x6 = temporary / UART status
# x7 = character
# x8 = temporary
# x9 = buffer base 0x300
# x10 = buffer pointer
# x11 = saved return address / end pointer

        addi x5, x0, 1
        slli x5, x5, 12
        addi x9, x0, 3
        slli x9, x9, 8          # x9 = 0x300

line_loop:
        addi x10, x9, 0         # write pointer = buffer base
read_line:
        jal  x1, getc
        addi x8, x0, 13
        beq  x7, x8, line_ready
        sw   x7, 0(x10)
        addi x10, x10, 4
        jal  x0, read_line

line_ready:
        addi x11, x10, 0        # end pointer
        addi x10, x9, 0         # read pointer = buffer base
write_line:
        beq  x10, x11, line_done
        lw   x7, 0(x10)
        jal  x1, putc
        addi x10, x10, 4
        jal  x0, write_line

line_done:
        addi x7, x0, 13
        jal  x1, putc
        addi x7, x0, 10
        jal  x1, putc
        jal  x0, line_loop

putc:
putc_wait:
        lw   x6, 4(x5)
        slli x6, x6, 31
        srli x6, x6, 31
        beq  x6, x0, putc_wait
        sw   x7, 0(x5)
        jalr x0, 0(x1)

getc:
getc_wait:
        lw   x6, 4(x5)
        srli x6, x6, 1
        beq  x6, x0, getc_wait
        lw   x7, 8(x5)
        jalr x0, 0(x1)
