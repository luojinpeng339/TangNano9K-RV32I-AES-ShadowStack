# OS-0D 800×480 live security dashboard candidate

## Purpose

This candidate keeps the board-verified OS-0D UART monitor (`help`, `status`,
unknown command) and replaces the prior fixed title renderer with a live
security dashboard on the proven RGB panel scanout:

```text
physical: 800×480 RGB565
internal: 400×240 RGB565
scale:    2× nearest-neighbor
clock:    27 MHz
```

Displayed live signals are wired directly from the CPU experiment counters:

```text
SECURITY OS-0 LIVE
HALT=0/1
MC=xxxxxxxx
MI=xxxxxxxx
AR=xxxxxxxx
SO=xxxxxxxx
CC=xxxxxxxx
CV=xxxxxxxx
SD=0000xxxx
UART COMMAND READY
```

Palette: cyan title, green normal status, red HALT, amber footer, black
background.

## Candidate output

```text
board_images/os0_dashboard.fs
SHA256: A9B31ABDD53A2535E8825671DEAED92B418BD101DEAE9750420116A09730714E
```

## Gates passed

```text
DASHBOARD_RENDERER_PASS live_status_palette
RGB_SCANOUT_PASS registered_bundle 800x480@60Hz 2x=400x240
Gowin synthesis → P&R → timing → bitstream → power: PASS
```

Target: `GW1NR-LV9QN88PC6/I5`.

```text
Logic     3191 / 8640  (37%)
Registers 1026 / 6693  (16%)
BSRAM       10 / 26   (39%)
Build elapsed time: 54 s, peak memory 239 MB
```

## Final ROM-embedded dashboard board evidence — passed (2026-08-11 11:58)

The first dashboard candidate builds mistakenly retained the old ROM because
`src/instr_mem.v` uses a hard-coded `$readmemh("test_program.hex", mem)`.
The final controlled build temporarily placed the corrected line-monitor ROM
at that actual build input, then restored the normal source ROM afterward.

Final candidate:

```text
board_images/os0_dashboard_romfixed.fs
FS SHA256: 50D8411935FB79FA3E67A8FEDE02D9A4E80FE69F0074D1B183780DD377F36AFB
Embedded OS ROM SHA256: 8A5A24404B11B542E8F94698DCEB683309570696252909ABDA0AC0DBBE6709C7
```

Board UART `status<CR>` at 115200 8N1 produced valid live counter values:

```text
H=0
MC=06776C98
MI=026D07B3
AR=00000000
SO=00000087
CC=00000051
CV=00000000
SD=00000001
SEC-OS0>
```

This closes the OS-0D display/UART board gate: terminal commands, formatted
live MMIO status, and the 800×480 dashboard run together. The temporary ROM
replacement used for bitstream construction was restored after the build.

## Board validation required

Program this `.fs` as a new candidate. Confirm the physical panel shows the
above live dashboard and SSCOM still accepts `help` and `status` at 115200 8N1.
Do not label the display side verified until a panel photo confirms the actual
800×480 panel output.
