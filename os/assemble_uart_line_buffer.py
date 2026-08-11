#!/usr/bin/env python3
from pathlib import Path
import re
SOURCE=Path(__file__).with_name('uart_line_buffer.S')
OUTPUT=Path(__file__).with_name('uart_line_buffer.hex')
REG={f'x{i}':i for i in range(32)}
def clean(s): return s.split('#',1)[0].strip()
def imm(s): return int(s.strip(),0)
def ops(s): return [x.strip() for x in s.split(None,1)[1].split(',')]
def it(rd,rs1,f3,v,opc): return ((v&0xfff)<<20)|(REG[rs1]<<15)|(f3<<12)|(REG[rd]<<7)|opc
def bt(off,rs1,rs2,f3=0):
 v=off&0x1fff
 return (((v>>12)&1)<<31)|(((v>>5)&0x3f)<<25)|(REG[rs2]<<20)|(REG[rs1]<<15)|(f3<<12)|(((v>>1)&0xf)<<8)|(((v>>11)&1)<<7)|0x63
def st(off,rs2,rs1):
 v=off&0xfff
 return ((v>>5)<<25)|(REG[rs2]<<20)|(REG[rs1]<<15)|(2<<12)|((v&31)<<7)|0x23
def jl(off,rd):
 v=off&0x1fffff
 return (((v>>20)&1)<<31)|(((v>>1)&0x3ff)<<21)|(((v>>11)&1)<<20)|(((v>>12)&0xff)<<12)|(REG[rd]<<7)|0x6f
def mem(s):
 m=re.fullmatch(r'(.+)\((x\d+)\)',s.replace(' ','')); return imm(m.group(1)),m.group(2)
labels={}; lines=[]; pc=0
for raw in SOURCE.read_text().splitlines():
 s=clean(raw)
 if not s: continue
 if s.endswith(':'): labels[s[:-1]]=pc
 else: lines.append((pc,s)); pc+=4
out=[]
for pc,s in lines:
 m=s.split()[0]; o=ops(s) if len(s.split())>1 else []
 if m=='addi': w=it(o[0],o[1],0,imm(o[2]),0x13)
 elif m=='slli': w=it(o[0],o[1],1,imm(o[2]),0x13)
 elif m=='srli': w=it(o[0],o[1],5,imm(o[2]),0x13)
 elif m=='lw': a,r=mem(o[1]); w=it(o[0],r,2,a,3)
 elif m=='sw': a,r=mem(o[1]); w=st(a,o[0],r)
 elif m=='beq': w=bt(labels[o[2]]-pc,o[0],o[1])
 elif m=='jal': w=jl(labels[o[1]]-pc,o[0])
 elif m=='jalr': a,r=mem(o[1]); w=it(o[0],r,0,a,0x67)
 else: raise ValueError(s)
 out.append(w)
OUTPUT.write_text(''.join(f'{w:08X}\n' for w in out))
print(f'assembled {len(out)} instructions -> {OUTPUT.name}')
