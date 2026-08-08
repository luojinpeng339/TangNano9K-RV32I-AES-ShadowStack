# Tang Nano 9K RV32I Security CPU

A five-stage RV32I hardware-security experiment platform for the Sipeed Tang Nano 9K (Gowin GW1NR-9C).

## What is implemented

- Five-stage RV32I pipeline: IF / ID / EX / MEM / WB
- RV32 Zkne-compatible encryption subset:
  - `aes32esi`
  - `aes32esmi`
- Custom AES-128 key-expansion assist (`custom-0`, explicitly **not** ratified Zkne)
- AES-128 FIPS-197 end-to-end CPU regression
- Protected internal shadow stack for canonical returns:
  - call: `jal rd, imm`, `rd != x0`
  - return: `jalr x0, 0(x1)`
- Sticky security halt on return mismatch / underflow / shadow-stack fault
- Retirement-accurate internal counters:
  - `mcycle`
  - `minstret`
  - `aes_retired_count`
  - `shadow_push_pop_count`
  - `cfi_check_count`
  - `cfi_violation_count`
- UART board reporter at 115200 baud
- Tang Nano 9K synthesis, P&R and `.fs` images

## Final board evidence

After changing instruction ROM to combinational read, cold-start behavior is stable both in simulation and on hardware.

| Workload | Halt | AES retired | Shadow ops | CFI checks | CFI violations |
|---|---:|---:|---:|---:|---:|
| AES forwarding | 0 | 2 | 0 | 0 | 0 |
| Normal nested calls | 0 | 0 | 4 | 2 | 0 |
| Shadow-stack attack | 1 | 0 | 1 | 1 | 1 |

Observed UART snapshots:

```text
AES:
H=0, AR=00000002, SO=00000000, CC=00000000, CV=00000000

Normal:
H=0, AR=00000000, SO=00000004, CC=00000002, CV=00000000

Attack:
H=1, AR=00000000, SO=00000001, CC=00000001, CV=00000001
```

## Repository layout

```text
src/                         Core RTL, AES modules and default ROM image
board_images/*.hex           Reproducible board workload images
board_images/               Reproducible workload hex and final .fs files
board_build/                Standalone Gowin project and generated build output
build/                      Simulation testbenches and generated local artifacts
tools/                      Golden-model/vector helpers
docs/                       Verification, board and roadmap documentation
```

## Simulation

Authoritative project root:

```text
C:\Users\Administrator\Desktop\CPU
```

Icarus Verilog is used for functional simulation. The testbenches in `build/` are verification artifacts; they do not modify core RTL.

Examples:

```powershell
Set-Location C:\Users\Administrator\Desktop\CPU
C:\iverilog\bin\iverilog.exe -g2012 -s tb_top_pipeline_shadow_normal_counters `
  -o build\tb_top_pipeline_shadow_normal_counters.vvp `
  build\tb_top_pipeline_shadow_normal_counters.v src\*.v
C:\iverilog\bin\vvp.exe build\tb_top_pipeline_shadow_normal_counters.vvp
```

See `docs/VERIFICATION.md` for the complete evidence matrix and cold-start checks.

## Gowin build

Tool used:

```text
D:\Gowin_edu\Gowin\Gowin_V1.9.11.03_Education_x64\IDE\bin\gw_sh.exe
```

The standalone project targets:

```text
GW1NR-LV9QN88PC6/I5
27 MHz (37.037 ns)
```

Build from `board_build/`:

```powershell
Set-Location C:\Users\Administrator\Desktop\CPU\board_build
& 'D:\Gowin_edu\Gowin\Gowin_V1.9.11.03_Education_x64\IDE\bin\gw_sh.exe' build_fs.tcl
```

The final images are in `board_images/`. Do not overwrite the current `src\test_program.hex` without backing it up first; see `board_images/README.md`.

## Authorship and development notes

The RTL, board integration, verification and documentation in this repository are original work by **Jinpeng Luo**. During development, AI tools were used as assistants for interface wiring, refactoring checks and debugging; they are not code authors or copyright holders.

Some historical source headers were incorrectly rewritten during an earlier AI-assisted cleanup. They have been normalized to reflect the actual project authorship.

## Scope and honest limitations

- The shadow stack protects the first-version canonical ABI return form only; generalized indirect-CFI is deferred.
- The custom key-expansion instruction is not part of ratified RV32 Zkne and is labeled separately.
- The current board reporter is a fixed-window experiment observer, not a CSR interface.
- GPU sources are not part of this project. `gpu_stub.v` exists only to satisfy the inherited `mem_stage` interface in the CPU-only build.

## Next stage

The hardware-security CPU is now frozen as the platform for the next phase: a minimal RV32I bare-metal runtime / operating-system experiment. See `docs/OS_ROADMAP.md`.
