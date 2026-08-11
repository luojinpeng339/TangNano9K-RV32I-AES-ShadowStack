#!/usr/bin/env python3
"""Generate the flat OS-0B UART welcome-banner + echo ROM image.

No cross toolchain is required; instructions are encoded from the RV32I subset
already covered by the current CPU regressions.
"""
from pathlib import Path


def i(imm, rs1, funct3, rd, opcode=0x13):
    return ((imm & 0xFFF) << 20) | (rs1 << 15) | (funct3 << 12) | (rd << 7) | opcode


def lw(imm, rs1, rd): return i(imm, rs1, 0b010, rd, 0x03)
def sw(imm, rs2, rs1):
    imm &= 0xFFF
    return ((imm >> 5) << 25) | (rs2 << 20) | (rs1 << 15) | (0b010 << 12) | ((imm & 0x1F) << 7) | 0x23

def beq(imm, rs1, rs2):
    imm &= 0x1FFF
    return (((imm >> 12) & 1) << 31) | (((imm >> 5) & 0x3F) << 25) | (rs2 << 20) | (rs1 << 15) | (((imm >> 1) & 0xF) << 8) | (((imm >> 11) & 1) << 7) | 0x63

def jal(imm, rd=0):
    imm &= 0x1FFFFF
    return (((imm >> 20) & 1) << 31) | (((imm >> 1) & 0x3FF) << 21) | (((imm >> 11) & 1) << 20) | (((imm >> 12) & 0xFF) << 12) | (rd << 7) | 0x6F

words = []
def pc(): return len(words) * 4
def emit(word): words.append(word)

emit(i(1, 0, 0, 5))
emit(i(12, 5, 1, 5))               # x5 = 0x1000

for char in b"SEC-OS0\r\n":
    emit(i(char, 0, 0, 7))          # x7 = character
    wait = pc()
    emit(lw(4, 5, 6))
    emit(i(31, 6, 1, 6))            # keep STATUS.bit0 (tx_ready)
    emit(i(31, 6, 5, 6))
    emit(beq(wait - pc(), 6, 0))
    emit(sw(0, 7, 5))               # TXDATA = x7

echo_loop = pc()
emit(lw(4, 5, 6))
emit(i(1, 6, 5, 6))                 # rx_valid bit1 -> bit0
emit(beq(echo_loop - pc(), 6, 0))
emit(lw(8, 5, 7))
emit(sw(0, 7, 5))
emit(jal(echo_loop - pc()))

out = Path(__file__).with_name("uart_welcome_echo.hex")
out.write_text("".join(f"{word:08X}\n" for word in words), encoding="ascii")
print(f"wrote {out} ({len(words)} instructions)")
