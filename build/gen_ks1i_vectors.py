from pathlib import Path
import random
import sys
sys.path.insert(0, str(Path(__file__).resolve().parents[1] / 'tools'))
from aes128_golden import SBOX, RCON

def ks1i(word, rnum):
    rotword = ((word << 8) & 0xFFFF_FFFF) | (word >> 24)
    subword = 0
    for byte_index in range(4):
        subword = (subword << 8) | SBOX[(rotword >> (24 - 8 * byte_index)) & 0xFF]
    rcon = RCON[rnum] if 0 <= rnum <= 10 else 0
    return subword ^ (rcon << 24)

rng = random.Random(0x4B533149)
words = [0x0C0D0E0F, 0x4D2B30C5, 0, 0xFFFF_FFFF]
words += [rng.getrandbits(32) for _ in range(512)]
rnums = list(range(11)) + [11, 15, 16, 31]
out = Path(__file__).resolve().parent / 'aes32_ks1i_vectors.txt'
with out.open('w', encoding='ascii', newline='\n') as f:
    for word in words:
        for rnum in rnums:
            f.write(f'{word:08X} {rnum} {ks1i(word, rnum):08X}\n')
print(f'wrote {len(words)*len(rnums)} vectors to {out}')
