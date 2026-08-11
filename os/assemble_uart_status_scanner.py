#!/usr/bin/env python3
"""Minimal two-pass assembler for OS-0C uart_status_scanner.S.

Supports only the RV32I forms used by this monitor.  It intentionally rejects
unknown source rather than silently emitting a wrong ROM image.
"""
from pathlib import Path
import ast
import re

SOURCE = Path(__file__).with_name("uart_status_scanner.S")
OUTPUT = Path(__file__).with_name("uart_status_scanner.hex")
REG = {f"x{i}": i for i in range(32)}


def clean(line):
    return line.split("#", 1)[0].strip()


def imm(text):
    text = text.strip()
    if text.startswith("'"):
        return ord(ast.literal_eval(text))
    return int(text, 0)


def split_ops(text):
    return [item.strip() for item in text.split(None, 1)[1].split(",")]


def i_type(opcode, rd, rs1, funct3, value):
    return ((value & 0xFFF) << 20) | (REG[rs1] << 15) | (funct3 << 12) | (REG[rd] << 7) | opcode


def b_type(offset, rs1, rs2, funct3=0b000):
    value = offset & 0x1FFF
    return (((value >> 12) & 1) << 31) | (((value >> 5) & 0x3F) << 25) | (REG[rs2] << 20) | (REG[rs1] << 15) | ((funct3 & 0x7) << 12) | (((value >> 1) & 0xF) << 8) | (((value >> 11) & 1) << 7) | 0x63


def s_type(offset, rs2, rs1):
    value = offset & 0xFFF
    return ((value >> 5) << 25) | (REG[rs2] << 20) | (REG[rs1] << 15) | (0b010 << 12) | ((value & 0x1F) << 7) | 0x23


def jal(offset, rd):
    value = offset & 0x1FFFFF
    return (((value >> 20) & 1) << 31) | (((value >> 1) & 0x3FF) << 21) | (((value >> 11) & 1) << 20) | (((value >> 12) & 0xFF) << 12) | (REG[rd] << 7) | 0x6F


def mem_operand(text):
    match = re.fullmatch(r"(.+)\((x\d+)\)", text.replace(" ", ""))
    if not match:
        raise ValueError(f"bad memory operand: {text}")
    return imm(match.group(1)), match.group(2)

lines = []
labels = {}
pc = 0
for original in SOURCE.read_text(encoding="utf-8").splitlines():
    text = clean(original)
    if not text:
        continue
    if text.endswith(":"):
        label = text[:-1]
        if label in labels:
            raise ValueError(f"duplicate label: {label}")
        labels[label] = pc
    else:
        lines.append((pc, text))
        pc += 4

words = []
for pc, text in lines:
    mnemonic = text.split()[0]
    ops = split_ops(text)
    if mnemonic == "addi":
        word = i_type(0x13, ops[0], ops[1], 0b000, imm(ops[2]))
    elif mnemonic == "slli":
        word = i_type(0x13, ops[0], ops[1], 0b001, imm(ops[2]))
    elif mnemonic == "srli":
        word = i_type(0x13, ops[0], ops[1], 0b101, imm(ops[2]))
    elif mnemonic == "lw":
        offset, rs1 = mem_operand(ops[1]); word = i_type(0x03, ops[0], rs1, 0b010, offset)
    elif mnemonic == "sw":
        offset, rs1 = mem_operand(ops[1]); word = s_type(offset, ops[0], rs1)
    elif mnemonic == "beq":
        word = b_type(labels[ops[2]] - pc, ops[0], ops[1], 0b000)
    elif mnemonic == "bne":
        word = b_type(labels[ops[2]] - pc, ops[0], ops[1], 0b001)
    elif mnemonic == "jal":
        word = jal(labels[ops[1]] - pc, ops[0])
    elif mnemonic == "jalr":
        offset, rs1 = mem_operand(ops[1]); word = i_type(0x67, ops[0], rs1, 0b000, offset)
    else:
        raise ValueError(f"unsupported instruction: {text}")
    words.append(word)

OUTPUT.write_text("".join(f"{word:08X}\n" for word in words), encoding="ascii")
print(f"assembled {SOURCE.name}: {len(words)} instructions -> {OUTPUT.name}")
