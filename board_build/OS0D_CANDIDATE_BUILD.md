# OS-0D candidate board build

Candidate files:

```text
board_build/os0_line_monitor.gprj
board_build/build_os0_line_monitor.tcl
board_images/os0_line_monitor.hex
```

The candidate Gowin project is copied from the existing security CPU project,
but its ROM input is changed only to:

```text
../board_images/os0_line_monitor.hex
```

The existing `security_cpu.gprj` and `src/test_program.hex` are untouched.

## Current evidence

```text
ROM SHA256 = 88FD5752D718343EFC38AB0D146ECC5F4EF7265F8334F72452F1DC319ADF41E5
FS  SHA256 = 673C722C70837B4FA3C04778B5C228314DC310E7EE10ADEF4C4414C9A00E3737
LINE_MONITOR_FAST_STATUS_PASS full_H_MC_MI_AR_SO_CC_CV_SD
```

## Synthesis / P&R / bitstream — passed

The independent candidate project was built with Gowin V1.9.11.03 Education
on 2026-08-11:

```text
Synthesis → Place & Route → Timing analysis → Bitstream generation → Power analysis
```

Output:

```text
board_images/os0_line_monitor.fs
```

Target: `GW1NR-LV9QN88PC6/I5` (Tang Nano 9K)

Measured implementation usage:

```text
Logic     2833 / 8640  (33%)
Registers 1023 / 6693  (16%)
BSRAM       10 / 26   (39%), including 6 pROM
Peak build memory: 236 MB
```

## Board UART evidence — passed

At 10:15–10:16 on 2026-08-11, the candidate `.fs` was programmed and tested
through SSCOM at 115200 8N1. The FPGA emitted `SEC-OS0>` after reset and
correctly handled all command paths:

```text
help<CR>
→ help: help status
  SEC-OS0>

status<CR>
→ H=0
  MC=D4444444
  MI=88888888
  AR=00000000
  SO=A1111111
  CC=33333333
  CV=00000000
  SD=00000000
  SEC-OS0>

abc<CR>
→ unknown command
  SEC-OS0>
```

The changing/nonzero counter values are live reads through the security-status
MMIO path. This is a complete terminal → FPGA UART RX → RV32I OS monitor →
FPGA UART TX board proof, not local terminal echo.

The candidate is now board-verified. The existing `security_cpu.gprj` and
`src/test_program.hex` remain untouched; promote this image to the active ROM
only through an explicit version-control/board-image decision.

