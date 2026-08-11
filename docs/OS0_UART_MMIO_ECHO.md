# OS-0A / OS-0B — UART command-line foundation

Date: 2026-08-08

## 1. What we built today

The security CPU v1.0 used a fixed ROM workload and a fixed UART status reporter. It could demonstrate AES/CFI evidence, but a human could not interact with the CPU.

Today we converted the machine into the first interactive OS foundation:

```text
PC serial terminal
    ↓  (UART RX, FPGA pin 18)
UART receiver
    ↓  (one received byte)
UART MMIO registers
    ↓  (CPU lw polling)
RV32I echo program
    ↓  (CPU sw)
UART transmitter
    ↓  (UART TX, FPGA pin 17)
PC serial terminal
```

This is the first real software/peripheral interaction running on the Tang Nano 9K:

```text
computer input → FPGA hardware → self-written RV32I program → FPGA hardware → computer output
```

The board test was successful. SSCOM showed distinct send/receive records:

```text
发 → a
收 ← a

发 → b
收 ← b
```

Thus the received character is not a local terminal echo: it was returned by the FPGA CPU.

## 2. Why UART comes before a filesystem

A command-line OS needs a human input path before it can offer commands such as:

```text
help
status
ls
cat
```

A RAM filesystem without UART RX would only be a static data structure. UART RX plus memory-mapped IO creates the control plane needed for the later command monitor.

The correct OS order is therefore:

```text
UART RX/TX + MMIO
→ polling echo
→ welcome text
→ command parser
→ status / security counters
→ RAM-backed filesystem
→ display text console and defensive LED/button demo
```

## 3. OS-0 address contract

The project now reserves this software-visible address map:

```text
0x0000_0000 - 0x0000_0FFF   data RAM
0x0000_1000 - 0x0000_10FF   UART MMIO
0x0000_1100 - 0x0000_11FF   security counters/status, planned
0x0000_1200 - 0x0000_12FF   GPIO/LED/button, planned
0x0000_1300 - 0x0000_13FF   timer, reserved
```

UART register layout:

```text
0x1000  UART_TXDATA  write low byte: transmit
0x1004  UART_STATUS  bit0=tx_ready, bit1=rx_valid
0x1008  UART_RXDATA  read low byte; read acknowledges/clears rx_valid
0x100C  UART_BAUD    readback of clocks per bit
```

At 27 MHz and 115200 baud:

```text
27,000,000 / 115,200 = 234.375 clocks/bit
```

The first implementation uses 234 clocks per bit, a sufficiently small baud error for reliable serial operation.

## 4. Hardware modules and data flow

### `src/uart_rx.v`

This module turns the asynchronous UART pin into a buffered byte.

```text
pin 18
→ two-flop synchronizer
→ start-bit half-period confirmation
→ 8 LSB-first data samples
→ stop-bit check
→ rx_data + rx_valid
```

The receiver uses a one-byte buffer. `rx_valid` stays high until the CPU reads RXDATA and emits `rx_ack`.

### `src/uart_tx.v`

This module serializes a byte written by the CPU:

```text
TXDATA write
→ start bit 0
→ data[0] ... data[7], LSB first
→ stop bit 1
→ tx_ready
```

### `src/uart_mmio.v`

This joins the RX/TX engines to CPU-visible registers. It sees only a 2-bit word offset:

```text
addr[3:2] = 0  → TXDATA
addr[3:2] = 1  → STATUS
addr[3:2] = 2  → RXDATA
addr[3:2] = 3  → BAUD
```

### `src/mem_stage.v`

This is where full CPU addresses are decoded. The legacy GPU MMIO decode was removed from the OS path and UART is selected when:

```verilog
uart_sel = (alu_result_m[31:8] == 24'h000010);
```

Reads now use an explicit pipeline control signal:

```verilog
uart_re = mem_read_m && uart_sel;
```

This matters because `!mem_write_m` does not mean an instruction is a load; an ALU instruction also does not write memory. OS peripherals require real read/write semantics.

Read data is selected by:

```verilog
read_data_m = uart_sel ? uart_rdata : data_mem_rdata;
```

### `src/top_pipeline.v`

The top-level now has `uart_rx` input and passes it into `mem_stage`; UART TX is driven by the new CPU peripheral rather than by the former fixed status reporter.

The CST wiring is:

```text
uart_tx = pin 17
uart_rx = pin 18
```

## 5. The first OS program: polling echo

Source file for study:

```text
os/uart_poll.S
```

ROM image actually executed:

```text
src/test_program.hex
```

Algorithm:

```asm
x5 = 0x1000
loop:
    x6 = UART_STATUS
    x6 = x6 >> 1
    if (x6 == 0) goto loop
    x7 = UART_RXDATA
    UART_TXDATA = x7
    goto loop
```

The shift has a specific reason:

```text
STATUS bit0 = tx_ready
STATUS bit1 = rx_valid
```

When no byte is pending:

```text
STATUS = 0x1
STATUS >> 1 = 0
beq x6,x0,loop is taken
```

When a byte is pending and TX is idle:

```text
STATUS = 0x3
STATUS >> 1 = 0x1
beq is not taken
```

The program then reads RXDATA and writes the same byte to TXDATA.

Machine code:

```text
00100293  addi x5, x0, 1
00C29293  slli x5, x5, 12
0042A303  lw   x6, 4(x5)
00135313  srli x6, x6, 1
FE030CE3  beq  x6, x0, -8
0082A383  lw   x7, 8(x5)
0072A023  sw   x7, 0(x5)
FEDFF06F  jal  x0, -20
```

## 6. Important CPU bug found and fixed while integrating OS software

The polling loop first failed because a load-use stall incorrectly froze MEM/WB:

```verilog
// old, wrong
.stall_w(stall_d)
```

When `lw STATUS` was followed by `srli`, `stall_d` was asserted. That must only:

```text
freeze IF and ID
insert an EX bubble
```

It must not prevent older instructions from reaching WB. In the failing sequence, an older:

```asm
slli x5,x5,12
```

had computed `0x1000` but was prevented from retiring, so x5 stayed `1`; the next load accessed address `0x00000005` instead of `0x00001004`, creating X propagation.

Correct connection:

```verilog
.stall_w(1'b0)
```

This led to the successful Test C result:

```text
OS0_UART_POLL_PASS
pc=00000014
x5=00001000
x6=00000000
```

We also disabled speculative branch prediction for OS-0:

```verilog
wire use_predict = 1'b0;
assign branch_mispredicted = pcsrc_e;
```

This makes IF statically follow PC+4; an actually taken branch/jump resolved in EX flushes younger instructions. It is the correct baseline while building a reliable command system. A future predictor must carry prediction metadata with the same branch instruction into EX before comparing prediction and outcome.

## 7. Verification evidence

### UART receiver

```text
TB_UART_RX_PASS
```

Covers `A`, `z`, `5`, false start, invalid stop bit and acknowledge clearing.

### UART MMIO peripheral

```text
TB_UART_MMIO_PASS
```

Covers:

```text
RX serial byte A
→ STATUS.rx_valid
→ RXDATA read = 0x41
→ acknowledgement clears valid
→ TXDATA write transmits 0x41
```

### CPU reads UART status

```text
OS0_UART_STATUS_PASS
x5=00001000
x6=00000001
```

### CPU stable polling

```text
OS0_UART_POLL_PASS
pc=00000014
x5=00001000
x6=00000000
```

### CPU end-to-end echo

```text
TOP_PIPELINE_UART_ECHO_PASS
char=41
```

### Board evidence

The bitstream:

```text
board_images/security_cpu_os0_uart_echo.fs
```

was programmed at 15:08 on 2026-08-08. In SSCOM at 115200 8N1, separate send and receive lines showed:

```text
发 → a   收 ← a
发 → b   收 ← b
```

## 8. What is complete and what is next

Complete:

```text
UART RX/TX hardware
UART MMIO
CPU polling software
CPU-driven board echo
```

Not complete yet:

```text
welcome text
line buffer
command parser
security-counter MMIO
GPIO/LED
RAM filesystem
RGB text console
```

The next block is a tiny monitor program which sends a fixed boot banner through UART MMIO, then reuses the echo loop to collect a line of input. Do not start filesystem work before the monitor can parse a line.
