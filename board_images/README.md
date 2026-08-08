# Board images

These are final Tang Nano 9K bitstreams rebuilt after the combinational-read instruction-ROM cold-start fix.

| File | Workload | Expected UART result |
|---|---|---|
| `security_cpu_aes_forwarding.fs` | AES32 forwarding | `H=0`, `AR=2`, `SO=0`, `CC=0`, `CV=0` |
| `security_cpu_shadow_normal.fs` | normal nested calls | `H=0`, `AR=0`, `SO=4`, `CC=2`, `CV=0` |
| `security_cpu_shadow_attack.fs` | tampered canonical return | `H=1`, `AR=0`, `SO=1`, `CC=1`, `CV=1` |

The corresponding ROM images are:

```text
aes_forwarding.hex
shadow_normal.hex
shadow_attack.hex
```

To rebuild one image:

```powershell
Set-Location C:\Users\Administrator\Desktop\CPU
Copy-Item test_program.hex board_images\test_program.hex.backup -Force
Copy-Item board_images\shadow_normal.hex test_program.hex -Force
Set-Location board_build
& 'D:\Gowin_edu\Gowin\Gowin_V1.9.11.03_Education_x64\IDE\bin\gw_sh.exe' build_fs.tcl
```

The project targets `GW1NR-LV9QN88PC6/I5` at 27 MHz and uses `pipeline.cst.cst`.

Do not publish temporary backup files or generated debug `.vvp` files as part of the clean source release.
