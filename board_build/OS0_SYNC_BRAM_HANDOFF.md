# OS-0 synchronous-BRAM board build handoff

## What this build contains

This is the current OS-0 monitor image for the Tang Nano 9K security CPU:

```text
SEC-OS0> help
SEC-OS0> status
SEC-OS0> unknown command
```

`status` emits:

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

The instruction memory is implemented as a synchronous block-RAM style ROM.
`src/if_stage.v` contains the two-response fetch buffer required to preserve
BRAM responses through a pipeline load-use stall.

## Authoritative files

```text
src/test_program.hex                    active board-build ROM
board_images/os0_status_sync_bram.hex  immutable named copy of that ROM
src/instr_mem.v                         synchronous instruction ROM
src/if_stage.v                          synchronous fetch request/response FIFO
src/if_id_reg.v                         fetch-valid gate
src/top_pipeline.v                      IF metadata wiring
src/security_status_mmio.v              read-only 0x1100 status block
board_build/security_cpu.gprj           Gowin project
board_build/build_fs.tcl                full synthesis/P&R/bitstream script
```

SHA-256 for the active and named ROM copies is identical:

```text
7A5C7E5354A1DF5C75545CE0D0A9E09C85C6F9814BC8145A9271DA...
```

## Manual Gowin build

1. Close memory-heavy programs first. The local CLI build was killed by the
   Windows host during Gowin technical mapping, not by a synthesis diagnostic.
2. Open `board_build/security_cpu.gprj` in Gowin IDE.
3. Confirm top module is `top_pipeline` and device is
   `GW1NR-LV9QN88PC6/I5`.
4. Confirm the project includes `../src/security_status_mmio.v`.
5. Confirm `src/test_program.hex` matches
   `board_images/os0_status_sync_bram.hex`.
6. Run Synthesis, then inspect the report:
   - instruction ROM must use BSRAM / pROM;
   - do not accept the old `15360 LUT4 used to infer mem` failure.
7. Run Place & Route and inspect 27 MHz timing.
8. Generate the `.fs` only after synthesis and P&R both succeed.

## Verification completed before handoff

```text
SYNC_GETC_STORE_PASS mem0=41
SYNC_LINE_BUFFER_FIRST_CHAR_PASS buffer0=41
TOP_PIPELINE_UART_LINE_BUFFER_PASS echo=Ab3
TOP_PIPELINE_UART_UNKNOWN_PASS output=unknown_command
TOP_PIPELINE_UART_HELP_PASS output=help: help status
SYNC_STATUS_PREFIX_PASS output=H=0
SYNC_STATUS_FULL_PASS H,MC,MI,AR,SO,CC,CV,SD
```

## Important current limitation

No current OS-0 `.fs` is included with this handoff. The older `.fs` files in
`board_images/` are not this synchronous-BRAM OS monitor and must not be
labeled as such.
