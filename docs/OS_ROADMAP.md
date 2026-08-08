# OS roadmap — next phase

The security CPU and board evidence are now frozen. The next phase is not a full Linux-class OS; it is a small, explainable RV32I bare-metal runtime that exercises the existing hardware.

## Recommended order

### OS-0: freeze the machine contract

- Document reset PC, memory map, UART output contract, instruction/data memory sizes, and alignment rules.
- Add a linker script and a deterministic reset/startup object.
- Stop relying on ad-hoc ROM initialization for software builds.

### OS-1: toolchain and runtime ABI

- Use a RISC-V RV32I cross compiler or assembler already available locally.
- Build a tiny startup:
  - initialize `sp`
  - clear `.bss`
  - call `main`
  - park in a loop
- Add `crt0.S`, linker script, and a reproducible `Makefile`/PowerShell build wrapper.

### OS-2: machine-mode monitor

- Define a small trap vector and `trap_entry`.
- Implement machine timer/software interrupt stubs only if the current RTL exposes usable sources.
- Otherwise first implement synchronous illegal-instruction and ecall handling in a deliberately minimal monitor.

### OS-3: drivers and services

- UART putc/puts driver through the existing board-visible output path.
- Timer service if a timer peripheral is actually connected.
- Security-event readout as a private monitor service, not a general-purpose CSR claim unless CSR wiring is added.

### OS-4: protected workload

- Run AES workload from the runtime.
- Run normal nested calls and attack replay from software images.
- Preserve the existing hardware counters and shadow-stack evidence.

## Immediate next action

Before writing OS code, inspect the actual instruction encoding/memory map and decide whether the current ROM/RAM arrangement will remain Harvard-style or be replaced by a single software image flow. Then add the linker script and reset startup only; do not add processes, virtual memory, or a scheduler yet.

## Explicitly deferred

- Linux/POSIX compatibility
- MMU, paging, virtual memory
- User/kernel privilege separation beyond what the RTL actually implements
- Filesystems, multitasking and scheduler
- Networking
- Full GCC/newlib port unless the toolchain and memory budget justify it
