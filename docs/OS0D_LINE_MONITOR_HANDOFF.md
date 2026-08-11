# OS-0D line-buffered command monitor handoff

Status: **simulation-gated 2026-08-11**

## New software artifact

- `os/uart_line_monitor.S`
- `os/assemble_uart_line_monitor.py`
- `os/uart_line_monitor.hex`

This is a software-only successor prototype to the character-by-character
scanner. It keeps the current `help`, `status`, and unknown-command responses,
but first collects a CR-terminated command into data RAM at `0x300` using one
character per 32-bit word. It then parses the saved line.

It is **not yet the active board image**. `src/test_program.hex` remains the
last board-verified OS monitor image until the new image passes a complete
status-report simulation and a subsequent synthesis/board check.

## Verification gates passed

- ROM assembly: 343 instructions, fits the 512-word instruction ROM.
- Fast-UART parameter check: testbench-local UART TX/RX both use 2 clocks/bit; production RTL and board baud rate remain unchanged.
- `help<CR>`: response and line-buffer write validated.
- `status<CR>`: full UART report format validated:

```text
H=0
MC=xxxxxxxx
MI=xxxxxxxx
AR=xxxxxxxx
SO=xxxxxxxx
CC=xxxxxxxx
CV=xxxxxxxx
SD=xxxxxxxx
```

Evidence:

```text
LINE_MONITOR_FAST_PROBE bytes=48 3d 30 0d 0a 4d 43 3d
LINE_MONITOR_FAST_STATUS_PASS full_H_MC_MI_AR_SO_CC_CV_SD
```

The first probe bytes decode as `H=0\r\nMC=`. The full report checker verifies every label, CR/LF terminator, and each eight-character numeric field is uppercase hexadecimal.

## Board gate remains

This image is **not yet the active board image**. `src/test_program.hex` remains the last board-verified OS monitor image until the new image has a standard-rate (`234 clocks/bit`) synthesis/board check.

## Earlier diagnostic note (resolved)

The initial status failure was not a UART or pipeline failure. The line monitor used unsupported `bne`, then the first software-only rewrite incorrectly routed a non-`help` first character directly to `unknown_line`. The final code uses supported `beq` plus `jal`, and routes the non-`help` path to `check_status`.

## Design boundary

No CPU/security RTL was changed for this step. The current parser recognizes
exact `help` and `status` only; `ls` and `cat <name>` should be added after the
status gate is green, using the same buffered-line ABI.
