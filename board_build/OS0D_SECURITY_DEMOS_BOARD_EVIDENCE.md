# OS-0D security demonstrations — board evidence

Date: 2026-08-11

Final board image:

```text
board_images/os0_security_demos.fs
SHA256: 54B4D89BE8353E7D2D48EDAAD93F092E26BF3A63C8431DCC74C2A8A6F2071C52
```

## Demonstration A — data security acceleration

At 115200 8N1:

```text
send: aes + CR
receive: AES OK
```

Then `status + CR` showed `AR` increased. This demonstrates a retired
Zkne AES32 instruction and the retirement-confirmed `aes_retired_count` event.

## Demonstration B — control-flow security

After reset:

```text
send: attack + CR
```

Observed on the board:

```text
HALT=1
CV=1
```

The dashboard HALT indication changed from green to red and the CPU stopped
responding to UART, as designed. The protected sequence is:

```text
JAL / shadow push
→ ordinary x1 return-address overwrite
→ canonical JALR return
→ shadow mismatch
→ CFI violation
→ sticky security halt
```

Reset is required after this demonstration. This is intentional fail-stop
behavior, not a UART failure.

## Combined interpretation

The same interactive OS and live dashboard now demonstrate both security axes:

```text
AES32 data-security acceleration: AR increases
Shadow-stack control-flow protection: CV increases and HALT asserts
```
