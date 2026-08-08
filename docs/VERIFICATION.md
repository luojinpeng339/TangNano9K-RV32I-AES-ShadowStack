# Verification and board evidence

## Authoritative root

All current evidence comes from:

```text
C:\Users\Administrator\Desktop\CPU
```

The old copied workspace under `D:\Agent\fpga_projects\riscv_zkne_cpu` is not authoritative.

## Functional evidence matrix

| Test | Result |
|---|---|
| Standard RV32 register fields | `TB_ID_STAGE_STANDARD_FIELDS_PASS checks=5` |
| AES32 functional unit | `TB_AES32_ZKNE_FU_PASS cases=6656` in the original independent-vector gate |
| AES32 pipeline forwarding | `TOP_PIPELINE_AES_FORWARDING_TEST: PASS` |
| AES-128 FIPS-197 in CPU pipeline | `TOP_PIPELINE_AES128_FIPS_PASS`, ciphertext `69C4E0D86A7B0430D8CDB78070B4C55A` |
| Load-use dependency | `LOAD_USE_REGRESSION_PASS` |
| Shadow stack memory | `TB_SHADOW_STACK_MEM_PASS depth=4` |
| Shadow-stack controller | `TB_SHADOW_STACK_CONTROL_LOGIC_PASS` |
| Normal nested calls + counters | `TOP_PIPELINE_SHADOW_NORMAL_COUNTERS_PASS`, `ssops=4`, `cfi_checks=2`, `cfi_violations=0` |
| Attack + counters | `TOP_PIPELINE_SHADOW_ATTACK_BLOCK_PASS`, `ssops=1`, `cfi_checks=1`, `cfi_violations=1` |
| UART reporter | `UART_STATUS_REPORTER_SMOKE_PASS bytes=92` |
| Cold-start normal workload | `h=0 ir=1368 so=4 cc=2 cv=0 ssp=0` |
| Cold-start attack workload | `h=1 ir=3 so=1 cc=1 cv=1 ssp=1` |

## Board images

| Image | Expected UART |
|---|---|
| `security_cpu_aes_forwarding.fs` | `H=0`, `AR=2`, `SO=0`, `CC=0`, `CV=0` |
| `security_cpu_shadow_normal.fs` | `H=0`, `AR=0`, `SO=4`, `CC=2`, `CV=0` |
| `security_cpu_shadow_attack.fs` | `H=1`, `AR=0`, `SO=1`, `CC=1`, `CV=1` |

All three final images were rebuilt after the `instr_mem.v` cold-start fix on 2026-08-08.

## Gowin P&R evidence

Device:

```text
GW1NR-LV9QN88PC6/I5
```

Clock:

```text
27 MHz / 37.037 ns
```

Final P&R output is under `board_build/impl/pnr/`.

The final build reported approximately:

```text
Logic:     2830 / 8640  (33%)
Registers: 1304 / 6693  (20%)
CLS:       1962 / 4320  (46%)
I/O:       25 / 71      (36%)
```

These are implementation measurements, not estimates. Timing should be read from the generated Gowin timing report for the exact image/tool run.

## Known warnings to clean in a later refactor

- Unused legacy FPU/divider/parity ports are still present and produce undriven-port warnings.
- `ex_mem_reg_reg_write` is a legacy unused input and should be tied off or removed.
- The CPU-only build uses `gpu_stub.v` solely because the inherited `mem_stage.v` interface still instantiates `gpu_top`; GPU is out of scope.
- The board reporter snapshots after a fixed 4096-cycle window.
